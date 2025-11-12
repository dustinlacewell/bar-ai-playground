# Giving Orders to Units

Your AI controls units by issuing commands. This doc covers all the common orders and how to use them effectively.

## The Basics

All orders use `Spring.GiveOrderToUnit`:

```lua
Spring.GiveOrderToUnit(unitID, CMD.<NAME>, params, options)
```

**Parameters:**

- `unitID` – Which unit to order
- `CMD.<NAME>` – The command (MOVE, FIGHT, BUILD, etc.)
- `params` – Command-specific parameters (usually a position or target)
- `options` – Flags like "shift" to queue orders

## Movement Commands

### MOVE

Move to a position:

```lua
Spring.GiveOrderToUnit(unitID, CMD.MOVE, {x, y, z}, {})
```

The unit will move to (x, y, z) and stop.

**Why use MOVE?** When you want a unit to go somewhere and stay there (e.g., rally point, retreat).

### FIGHT

Move to a position and attack anything in the way:

```lua
Spring.GiveOrderToUnit(unitID, CMD.FIGHT, {x, y, z}, {})
```

The unit will move to (x, y, z), attacking enemies along the way.

**Why use FIGHT?** For combat units that should engage enemies while moving (e.g., assault units).

### PATROL

Patrol between two positions:

```lua
Spring.GiveOrderToUnit(unitID, CMD.PATROL, {x, y, z}, {})
```

The unit will move to (x, y, z), then back to its starting position, and repeat.

**Why use PATROL?** For units guarding an area.

## Attack Commands

### ATTACK (Unit Target)

Attack a specific unit:

```lua
Spring.GiveOrderToUnit(unitID, CMD.ATTACK, {targetUnitID}, {})
```

The unit will attack the target until it dies or the order is cancelled.

### ATTACK (Position Target)

Attack a position (useful for area attacks):

```lua
Spring.GiveOrderToUnit(unitID, CMD.ATTACK, {x, y, z}, {})
```

The unit will move to (x, y, z) and attack anything there.

**Example: Attack the nearest enemy**

```lua
local enemy = Spring.GetUnitNearestEnemy(unitID, 1200, true)
if enemy then
    Spring.GiveOrderToUnit(unitID, CMD.ATTACK, {enemy}, {})
end
```

## Building Commands

### BUILD (Negative UnitDefID)

Build a structure:

```lua
local builtDefID = 123  -- The unit type to build
local x, y, z = 1000, 0, 1000  -- Where to build
local facing = 0  -- Rotation (0=South, 1=East, 2=North, 3=West)

Spring.GiveOrderToUnit(builderID, -builtDefID, {x, y, z, facing}, {})
```

**Important:** The command is the negative of the unitDefID. This tells the engine "build this unit type."

**Before building, always test the location:**

```lua
local ok = Spring.TestBuildOrder(builtDefID, x, y, z, facing)
if ok == 2 then
    -- ok == 2 means fully valid; build it
    Spring.GiveOrderToUnit(builderID, -builtDefID, {x, y, z, facing}, {})
else
    -- ok == 0 means invalid; ok == 1 means iffy (blocked/steep)
    Spring.Echo("Can't build here")
end
```

**Why test?** Buildings have footprints and placement rules. Testing ensures you don't waste orders on invalid locations.

### Footprints and Spacing

Buildings occupy space. Check their size:

```lua
local ud = UnitDefs[builtDefID]
local xsize = ud.xsize  -- Width in map squares
local zsize = ud.zsize  -- Depth in map squares
-- Each square is 8 elmos, so actual size is xsize*8 by zsize*8 elmos
```

When placing buildings, leave spacing to avoid overlap:

```lua
local function findBuildSpot(builderX, builderZ, builtDefID, searchRadius)
    local ud = UnitDefs[builtDefID]
    local spacing = (ud.xsize + ud.zsize) * 8  -- Rough spacing
    
    -- Try positions around the builder
    for angle = 0, 360, 45 do
        local rad = math.rad(angle)
        local x = builderX + math.cos(rad) * searchRadius
        local z = builderZ + math.sin(rad) * searchRadius
        
        local ok = Spring.TestBuildOrder(builtDefID, x, 0, z, 0)
        if ok == 2 then
            return x, z
        end
    end
    
    return nil
end
```

## Utility Commands

### STOP

Stop all current orders:

```lua
Spring.GiveOrderToUnit(unitID, CMD.STOP, {}, {})
```

The unit will stop moving and attacking.

### GUARD

Guard another unit (follow and protect):

```lua
Spring.GiveOrderToUnit(unitID, CMD.GUARD, {targetUnitID}, {})
```

The unit will follow the target and attack anything that attacks it.

**Why use GUARD?** To keep units together (e.g., guard your commander).

### RECLAIM

Reclaim a feature (rock, tree, wreck):

```lua
Spring.GiveOrderToUnit(unitID, CMD.RECLAIM, {featureID}, {})
```

The unit will move to the feature and reclaim it for resources.

**Example: Order a builder to reclaim nearby metal**

```lua
local features = Spring.GetFeaturesInRectangle(x1, z1, x2, z2) or {}
for _, featureID in ipairs(features) do
    local defID = Spring.GetFeatureDefID(featureID)
    local fd = FeatureDefs[defID]
    
    if fd and fd.reclaimable and fd.metal > 0 then
        Spring.GiveOrderToUnit(builderID, CMD.RECLAIM, {featureID}, {})
        break  -- Reclaim one at a time
    end
end
```

### REPAIR

Repair another unit:

```lua
Spring.GiveOrderToUnit(unitID, CMD.REPAIR, {targetUnitID}, {})
```

The unit will move to the target and repair it.

### RESURRECT

Resurrect a dead unit (if your unit has this ability):

```lua
Spring.GiveOrderToUnit(unitID, CMD.RESURRECT, {featureID}, {})
```

The unit will move to the wreck and resurrect it.

## State Commands

### FIRE_STATE

Set how aggressively a unit attacks:

```lua
Spring.GiveOrderToUnit(unitID, CMD.FIRE_STATE, {state}, {})
```

States:

- `0` – Hold fire (don't attack)
- `1` – Return fire (attack if attacked)
- `2` – Fire at will (attack anything)

**Example: Make a unit hold fire**

```lua
Spring.GiveOrderToUnit(unitID, CMD.FIRE_STATE, {0}, {})
```

### MOVE_STATE

Set how a unit moves:

```lua
Spring.GiveOrderToUnit(unitID, CMD.MOVE_STATE, {state}, {})
```

States:

- `0` – Hold position (don't move)
- `1` – Maneuver (move as needed)
- `2` – Roam (move freely)

### ONOFF

Turn a unit on or off:

```lua
Spring.GiveOrderToUnit(unitID, CMD.ONOFF, {0}, {})  -- Off
Spring.GiveOrderToUnit(unitID, CMD.ONOFF, {1}, {})  -- On
```

Useful for stopping energy-draining units when you're low on power.

## Queuing Orders

By default, each order replaces the previous one. To queue orders, use the "shift" option:

```lua
Spring.GiveOrderToUnit(unitID, CMD.MOVE, {x1, y1, z1}, {})
Spring.GiveOrderToUnit(unitID, CMD.MOVE, {x2, y2, z2}, {"shift"})
Spring.GiveOrderToUnit(unitID, CMD.MOVE, {x3, y3, z3}, {"shift"})
```

The unit will move to (x1, y1, z1), then (x2, y2, z2), then (x3, y3, z3).

**Example: Create a patrol route**

```lua
local function patrolRoute(unitID, positions)
    for i, pos in ipairs(positions) do
        local opts = i == 1 and {} or {"shift"}
        Spring.GiveOrderToUnit(unitID, CMD.MOVE, {pos.x, pos.y, pos.z}, opts)
    end
end

patrolRoute(unitID, {
    {x = 1000, y = 0, z = 1000},
    {x = 2000, y = 0, z = 1000},
    {x = 2000, y = 0, z = 2000},
})
```

## Practical Example: Simple Builder AI

Here's a complete example that builds metal extractors:

```lua
local M = {}
local myTeam
local myUnits = {}
local nextBuildTime = 0

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

local function isBuilder(unitDefID)
    local ud = UnitDefs[unitDefID]
    return ud and ud.canMove and ud.isBuilder and #ud.buildOptions > 0
end

local function findMexDefID()
    -- Find a metal extractor in the game
    for defID, ud in pairs(UnitDefs) do
        if ud.customParams and ud.customParams.metal_extractor then
            return defID
        end
    end
    return nil
end

local function findBuildSpot(builderX, builderZ, mexDefID)
    local radius = 500
    local x1, z1 = builderX - radius, builderZ - radius
    local x2, z2 = builderX + radius, builderZ + radius
    
    local features = Spring.GetFeaturesInRectangle(x1, z1, x2, z2) or {}
    for _, featureID in ipairs(features) do
        local defID = Spring.GetFeatureDefID(featureID)
        local fd = FeatureDefs[defID]
        
        if fd and fd.metal > 0 then
            local fx, fy, fz = Spring.GetFeaturePosition(featureID)
            local ok = Spring.TestBuildOrder(mexDefID, fx, fy, fz, 0)
            if ok == 2 then
                return fx, fy, fz
            end
        end
    end
    
    return nil
end

function M.Update(frame)
    if frame < nextBuildTime then return end
    if frame % 60 ~= 0 then return end
    
    local mCur, mStor = Spring.GetTeamResources(myTeam, "metal")
    local mexDefID = findMexDefID()
    
    if not mexDefID then return end
    
    local mexCost = UnitDefs[mexDefID].metalCost
    
    for unitID in pairs(myUnits) do
        local unitDefID = Spring.GetUnitDefID(unitID)
        
        if isBuilder(unitDefID) and mCur >= mexCost then
            local bx, by, bz = Spring.GetUnitPosition(unitID)
            local x, y, z = findBuildSpot(bx, bz, mexDefID)
            
            if x then
                Spring.GiveOrderToUnit(unitID, -mexDefID, {x, y, z, 0}, {})
                nextBuildTime = frame + 150  -- Wait 5 seconds before building again
                return
            end
        end
    end
end

return M
```

## Next Steps

- **Advanced:** Read **06_practical_patterns.md** for common AI strategies
- **Reference:** Check the reference section for a complete command list
