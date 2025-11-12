# Quick Start Cheat Sheet

Copy-paste templates to get started immediately.

## Minimal AI

Save as `luarules/gadgets/ai/comp/bots/my_ai.lua`:

```lua
local M = {}
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

function M.Update(frame)
    if frame % 60 ~= 0 then return end
    
    -- Your AI logic here
end

return M
```

## Rush AI (Attack Nearest Enemy)

```lua
local M = {}
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

function M.Update(frame)
    if frame % 90 ~= 0 then return end
    
    local myX, _, myZ = Spring.GetTeamStartPosition(myTeam)
    if not myX then return end
    
    -- Find nearest enemy start position
    local nearest = nil
    local nearestDist = math.huge
    
    for _, teamID in ipairs(Spring.GetTeamList() or {}) do
        local leader, allyTeam = Spring.GetTeamInfo(teamID)
        if allyTeam ~= Spring.GetTeamInfo(myTeam) then
            local ex, ey, ez = Spring.GetTeamStartPosition(teamID)
            if ex then
                local dist = math.sqrt((ex - myX)^2 + (ez - myZ)^2)
                if dist < nearestDist then
                    nearestDist = dist
                    nearest = {x = ex, y = ey, z = ez}
                end
            end
        end
    end
    
    if nearest then
        for unitID in pairs(myUnits) do
            local unitDefID = Spring.GetUnitDefID(unitID)
            local ud = UnitDefs[unitDefID]
            if ud and ud.canMove then
                Spring.GiveOrderToUnit(unitID, CMD.FIGHT, {nearest.x, nearest.y or 0, nearest.z}, {})
            end
        end
    end
end

return M
```

## Builder AI (Build Metal Extractors)

```lua
local M = {}
local myTeam
local myUnits = {}
local builders = {}
local nextBuildTime = 0

function M.Init(teamID)
    myTeam = teamID
    local units = Spring.GetTeamUnits(teamID) or {}
    for i = 1, #units do
        myUnits[units[i]] = true
        classifyUnit(units[i])
    end
end

local function classifyUnit(unitID)
    local unitDefID = Spring.GetUnitDefID(unitID)
    local ud = UnitDefs[unitDefID]
    if ud and ud.canMove and ud.isBuilder then
        builders[unitID] = true
    end
end

function M.UnitCreated(unitID, unitDefID, teamID)
    if teamID == myTeam then
        myUnits[unitID] = true
        classifyUnit(unitID)
    end
end

function M.UnitFinished(unitID, unitDefID, teamID)
    if teamID == myTeam then
        myUnits[unitID] = true
        classifyUnit(unitID)
    end
end

function M.UnitDestroyed(unitID, unitDefID, teamID)
    myUnits[unitID] = nil
    builders[unitID] = nil
end

local function findMetalExtractor()
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
    local mexDefID = findMetalExtractor()
    
    if not mexDefID then return end
    
    local mexCost = UnitDefs[mexDefID].metalCost
    
    for builderID in pairs(builders) do
        if mCur >= mexCost and Spring.GetUnitCommandCount(builderID) == 0 then
            local bx, by, bz = Spring.GetUnitPosition(builderID)
            local x, y, z = findBuildSpot(bx, bz, mexDefID)
            
            if x then
                Spring.GiveOrderToUnit(builderID, -mexDefID, {x, y, z, 0}, {})
                nextBuildTime = frame + 150
                return
            end
        end
    end
end

return M
```

## Useful Snippets

### Track Units by Type

```lua
local commanders = {}
local factories = {}
local builders = {}
local combatUnits = {}

local function classifyUnit(unitID)
    local unitDefID = Spring.GetUnitDefID(unitID)
    local ud = UnitDefs[unitDefID]
    if not ud then return end
    
    if ud.customParams and ud.customParams.iscommander then
        commanders[unitID] = true
    elseif ud.isFactory then
        factories[unitID] = true
    elseif ud.isBuilder then
        builders[unitID] = true
    elseif ud.canMove and #(ud.weapons or {}) > 0 then
        combatUnits[unitID] = true
    end
end
```

### Check Resources

```lua
local function getResources()
    local mCur, mStor = Spring.GetTeamResources(myTeam, "metal")
    local eCur, eStor = Spring.GetTeamResources(myTeam, "energy")
    
    return {
        metalPercent = (mCur / mStor) * 100,
        energyPercent = (eCur / eStor) * 100,
        canBuild = mCur >= 100,
    }
end
```

### Find Nearest Enemy

```lua
local function findNearestEnemy(unitID)
    local enemy = Spring.GetUnitNearestEnemy(unitID, 1200, true)
    if enemy then
        local ex, ey, ez = Spring.GetUnitPosition(enemy)
        return {x = ex, y = ey or 0, z = ez}
    end
    return nil
end
```

### Build Something

```lua
local function tryBuild(builderID, builtDefID, x, y, z)
    local ok = Spring.TestBuildOrder(builtDefID, x, y, z, 0)
    if ok == 2 then
        Spring.GiveOrderToUnit(builderID, -builtDefID, {x, y, z, 0}, {})
        return true
    end
    return false
end
```

### Order Idle Unit

```lua
local function orderIdleUnit(unitID, cmd, params)
    if Spring.GetUnitCommandCount(unitID) == 0 then
        Spring.GiveOrderToUnit(unitID, cmd, params, {})
    end
end
```

## Debugging

```lua
-- Print to console and infolog.txt
Spring.Echo("[MyAI] Debug: " .. value)

-- Print formatted
Spring.Echo(string.format("[MyAI] Metal: %.0f/%.0f", mCur, mStor))

-- Count units
local count = 0
for _ in pairs(myUnits) do count = count + 1 end
Spring.Echo("[MyAI] Unit count: " .. count)

-- Check unit status
for unitID in pairs(myUnits) do
    local unitDefID = Spring.GetUnitDefID(unitID)
    local ud = UnitDefs[unitDefID]
    local cmdCount = Spring.GetUnitCommandCount(unitID)
    Spring.Echo(string.format("[MyAI] %s has %d commands", ud.name, cmdCount))
end
```

## Testing

1. Save your AI to `luarules/gadgets/ai/comp/bots/my_ai.lua`
2. Start a Skirmish game
3. Select "Dev AI: my_ai" for your team
4. Use `/luarules reload` to hot-reload changes
5. Check `<BAR_INSTALL>/data/infolog.txt` for errors

## Next Steps

- Read **README.md** for overview
- Read **02_first_ai.md** for step-by-step guide
- Check **reference_commands.md** for all commands
- Check **reference_spring_api.md** for all APIs
- Check **troubleshooting.md** if something breaks
