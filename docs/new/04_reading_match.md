# Reading the Match State

Your AI needs to know what's happening in the game: where are your units, what resources do you have, where are enemies, what's on the map. This doc covers querying the game state.

## Getting Your Units

You already know how to track your units (from **02_first_ai.md**). Here's a quick recap:

```lua
local myTeam
local myUnits = {}

function M.Init(teamID)
    myTeam = teamID
    local units = Spring.GetTeamUnits(teamID) or {}
    for i = 1, #units do
        myUnits[units[i]] = true
    end
end

function M.UnitCreated(unitID, unitDefID, teamID)
    if teamID == myTeam then myUnits[unitID] = true end
end

function M.UnitFinished(unitID, unitDefID, teamID)
    if teamID == myTeam then myUnits[unitID] = true end
end

function M.UnitDestroyed(unitID, unitDefID, teamID)
    myUnits[unitID] = nil
end
```

Now you can iterate over your units:

```lua
for unitID in pairs(myUnits) do
    -- Do something with this unit
end
```

## Unit Information

Once you have a unit ID, you can query its properties:

```lua
local unitDefID = Spring.GetUnitDefID(unitID)
local x, y, z = Spring.GetUnitPosition(unitID)
local hp, maxHp = Spring.GetUnitHealth(unitID)
local cmdCount = Spring.GetUnitCommandCount(unitID)
```

**What each does:**

- `Spring.GetUnitDefID(unitID)` – Returns the unit's definition ID (used to look up `UnitDefs`)
- `Spring.GetUnitPosition(unitID)` – Returns the unit's current position (x, y, z)
- `Spring.GetUnitHealth(unitID)` – Returns current and max health
- `Spring.GetUnitCommandCount(unitID)` – Returns how many orders are queued (0 = idle)

## Unit Definitions (UnitDefs)

`UnitDefs[unitDefID]` is a table containing all metadata about a unit type. Useful fields:

```lua
local ud = UnitDefs[unitDefID]

-- Basic info
ud.name              -- String name (e.g., "armcom")
ud.isBuilding        -- Boolean: is this a building?
ud.isFactory         -- Boolean: can it build units?
ud.canMove           -- Boolean: can it move?

-- Costs
ud.metalCost         -- Metal required to build
ud.energyCost        -- Energy required to build

-- Building
ud.buildOptions      -- Table of unitDefIDs this unit can build
ud.xsize, ud.zsize   -- Footprint in map squares (×8 elmos)

-- Resources
ud.extractsMetal     -- Boolean: is this a metal extractor?
ud.windGenerator     -- Boolean: is this a wind turbine?
ud.tidalGenerator    -- Boolean: is this a tidal generator?
ud.energyMake        -- Energy production per frame

-- Combat
ud.weapons           -- Table of weapons (if any)
ud.customParams      -- Game-specific flags (e.g., iscommander, metal_extractor)
```

**Example: Find your commander**

```lua
local function isCommander(unitDefID)
    local ud = UnitDefs[unitDefID]
    return ud and ud.customParams and ud.customParams.iscommander
end

local commander
for unitID in pairs(myUnits) do
    local unitDefID = Spring.GetUnitDefID(unitID)
    if isCommander(unitDefID) then
        commander = unitID
        break
    end
end
```

**Example: Find all factories**

```lua
local factories = {}
for unitID in pairs(myUnits) do
    local unitDefID = Spring.GetUnitDefID(unitID)
    local ud = UnitDefs[unitDefID]
    if ud and ud.isFactory then
        table.insert(factories, unitID)
    end
end
```

## Resources

Your team has metal and energy. Query them like this:

```lua
local mCur, mStor, mPull, mIncome, mExpense, mShare = Spring.GetTeamResources(myTeam, "metal")
local eCur, eStor, ePull, eIncome, eExpense, eShare = Spring.GetTeamResources(myTeam, "energy")
```

**What each means:**

- `mCur` – Current metal available
- `mStor` – Metal storage capacity
- `mPull` – Metal being pulled (negative = deficit)
- `mIncome` – Metal income per frame
- `mExpense` – Metal expense per frame
- `mShare` – Metal being shared with allies

**In practice, you usually only care about current and storage:**

```lua
local mCur, mStor = Spring.GetTeamResources(myTeam, "metal")
local eCur, eStor = Spring.GetTeamResources(myTeam, "energy")

if mCur >= 100 then
    -- You have enough metal to build something
end

if eCur < eStor * 0.3 then
    -- You're running low on energy
end
```

## Finding Enemies

You can query the nearest enemy to a unit:

```lua
local enemyID = Spring.GetUnitNearestEnemy(unitID, radius, inLos)
```

**Parameters:**

- `unitID` – Which unit to search from
- `radius` – Search radius (in elmos)
- `inLos` – Boolean: only count enemies in line-of-sight?

**Example: Attack the nearest enemy**

```lua
local enemy = Spring.GetUnitNearestEnemy(unitID, 1200, true)
if enemy then
    local ex, ey, ez = Spring.GetUnitPosition(enemy)
    Spring.GiveOrderToUnit(unitID, CMD.FIGHT, {ex, ey or 0, ez}, {})
end
```

## Terrain and Map Information

### Ground Height

```lua
local height = Spring.GetGroundHeight(x, z)
```

Returns the terrain height at position (x, z).

### Ground Info

```lua
local type, type2, hasMetal = Spring.GetGroundInfo(x, z)
```

Returns terrain type and whether there's metal at that location.

### Map Size

```lua
local mapWidth = Game.mapSizeX
local mapHeight = Game.mapSizeZ
```

## Features (Rocks, Trees, Wrecks)

Features are static objects on the map: rocks, trees, wreckage, etc. You can query and reclaim them.

### Finding Features

```lua
local featureIDs = Spring.GetFeaturesInRectangle(x1, z1, x2, z2) or {}
for _, featureID in ipairs(featureIDs) do
    -- Process this feature
end
```

### Feature Information

```lua
local defID = Spring.GetFeatureDefID(featureID)
local fd = FeatureDefs[defID]

-- Feature properties
fd.name              -- String name
fd.metal             -- Metal value
fd.energy            -- Energy value
fd.reclaimable       -- Boolean: can it be reclaimed?
fd.destructable      -- Boolean: can it be destroyed?

-- Dynamic info
local metal, energy, reclaimLeft = Spring.GetFeatureResources(featureID)
local fx, fy, fz = Spring.GetFeaturePosition(featureID)
```

**Example: Find all reclaimable metal nearby**

```lua
local function findMetalToReclaim(x, z, radius)
    local x1, z1 = x - radius, z - radius
    local x2, z2 = x + radius, z + radius
    
    local features = Spring.GetFeaturesInRectangle(x1, z1, x2, z2) or {}
    local metalSpots = {}
    
    for _, featureID in ipairs(features) do
        local defID = Spring.GetFeatureDefID(featureID)
        local fd = FeatureDefs[defID]
        
        if fd and fd.reclaimable and fd.metal > 0 then
            local metal, energy = Spring.GetFeatureResources(featureID)
            local fx, fy, fz = Spring.GetFeaturePosition(featureID)
            table.insert(metalSpots, {
                featureID = featureID,
                x = fx,
                y = fy,
                z = fz,
                metal = metal
            })
        end
    end
    
    return metalSpots
end
```

## Team Information

Get info about all teams:

```lua
local teamList = Spring.GetTeamList() or {}
for _, teamID in ipairs(teamList) do
    local leader, allyTeam, startMetal, startEnergy, isAI, side, allyTeamID = Spring.GetTeamInfo(teamID)
    
    -- leader: player name or AI name
    -- allyTeam: which alliance this team is in
    -- isAI: boolean
    -- side: faction name
end
```

## Start Positions

Get where a team started:

```lua
local sx, sy, sz = Spring.GetTeamStartPosition(teamID)
```

This is useful for knowing where enemies likely are, or where to rally your units.

## Practical Example: Resource Monitor

Here's a complete example that monitors your resources and logs when you're in deficit:

```lua
local M = {}
local myTeam

function M.Init(teamID)
    myTeam = teamID
end

function M.Update(frame)
    if frame % 300 ~= 0 then return end  -- Check every 10 seconds
    
    local mCur, mStor, mPull, mIncome, mExpense = Spring.GetTeamResources(myTeam, "metal")
    local eCur, eStor, ePull, eIncome, eExpense = Spring.GetTeamResources(myTeam, "energy")
    
    local mPercent = (mCur / mStor) * 100
    local ePercent = (eCur / eStor) * 100
    
    Spring.Echo(string.format("[MyAI] Metal: %.0f%% | Energy: %.0f%%", mPercent, ePercent))
    
    if mCur < 50 then
        Spring.Echo("[MyAI] WARNING: Low metal!")
    end
    
    if eCur < eStor * 0.2 then
        Spring.Echo("[MyAI] WARNING: Low energy!")
    end
end

return M
```

## Next Steps

- **Next:** Read **05_giving_orders.md** to learn how to command your units
- **Advanced:** Read **06_practical_patterns.md** for common AI strategies
