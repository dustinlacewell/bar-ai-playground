# Practical Patterns and Optimization

This doc covers common AI strategies and performance optimizations.

## Pattern 1: Unit Classification

Categorize units so you can handle them differently:

```lua
local function isCommander(unitDefID)
    local ud = UnitDefs[unitDefID]
    return ud and ud.customParams and ud.customParams.iscommander
end

local function isFactory(unitDefID)
    local ud = UnitDefs[unitDefID]
    return ud and ud.isFactory and #ud.buildOptions > 0
end

local function isBuilder(unitDefID)
    local ud = UnitDefs[unitDefID]
    return ud and ud.canMove and ud.isBuilder and #ud.buildOptions > 0
end

local function isMobileUnit(unitDefID)
    local ud = UnitDefs[unitDefID]
    return ud and ud.canMove and not ud.isBuilding
end

local function isCombatUnit(unitDefID)
    local ud = UnitDefs[unitDefID]
    return ud and ud.canMove and #(ud.weapons or {}) > 0
end

local function isBuilding(unitDefID)
    local ud = UnitDefs[unitDefID]
    return ud and ud.isBuilding
end

local function isExtractor(unitDefID)
    local ud = UnitDefs[unitDefID]
    return ud and (ud.extractsMetal or ud.windGenerator or ud.tidalGenerator)
end
```

**Why categorize?** Different unit types need different strategies. Factories build units, builders build structures, combat units attack, etc.

## Pattern 2: Separate Units by Role

Track different unit types separately:

```lua
local M = {}
local myTeam
local myUnits = {}
local commanders = {}
local factories = {}
local builders = {}
local combatUnits = {}

function M.Init(teamID)
    myTeam = teamID
    local units = Spring.GetTeamUnits(teamID) or {}
    for i = 1, #units do
        local unitID = units[i]
        myUnits[unitID] = true
        classifyUnit(unitID)
    end
end

local function classifyUnit(unitID)
    local unitDefID = Spring.GetUnitDefID(unitID)
    
    if isCommander(unitDefID) then
        commanders[unitID] = true
    elseif isFactory(unitDefID) then
        factories[unitID] = true
    elseif isBuilder(unitDefID) then
        builders[unitID] = true
    elseif isCombatUnit(unitDefID) then
        combatUnits[unitID] = true
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
    commanders[unitID] = nil
    factories[unitID] = nil
    builders[unitID] = nil
    combatUnits[unitID] = nil
end

function M.Update(frame)
    if frame % 60 ~= 0 then return end
    
    -- Handle each unit type differently
    for unitID in pairs(commanders) do
        -- Commander logic
    end
    
    for unitID in pairs(factories) do
        -- Factory logic
    end
    
    for unitID in pairs(builders) do
        -- Builder logic
    end
    
    for unitID in pairs(combatUnits) do
        -- Combat logic
    end
end

return M
```

## Pattern 3: Resource-Based Decisions

Make decisions based on available resources:

```lua
local function canAfford(metalCost, energyCost)
    local mCur, mStor = Spring.GetTeamResources(myTeam, "metal")
    local eCur, eStor = Spring.GetTeamResources(myTeam, "energy")
    
    return mCur >= metalCost and eCur >= energyCost
end

local function getResourceStatus()
    local mCur, mStor, mPull, mIncome, mExpense = Spring.GetTeamResources(myTeam, "metal")
    local eCur, eStor, ePull, eIncome, eExpense = Spring.GetTeamResources(myTeam, "energy")
    
    return {
        metalPercent = (mCur / mStor) * 100,
        energyPercent = (eCur / eStor) * 100,
        metalIncome = mIncome,
        metalExpense = mExpense,
        energyIncome = eIncome,
        energyExpense = eExpense,
        metalDeficit = mExpense > mIncome,
        energyDeficit = eExpense > eIncome,
    }
end

function M.Update(frame)
    if frame % 60 ~= 0 then return end
    
    local status = getResourceStatus()
    
    if status.metalDeficit then
        -- Build more metal extractors
    end
    
    if status.energyPercent < 30 then
        -- Build more power plants
    end
    
    if status.metalPercent > 80 then
        -- Spend metal on units/buildings
    end
end
```

## Pattern 4: Idle Unit Detection

Don't spam orders to idle units; only order them when they need it:

```lua
local function isIdle(unitID)
    return Spring.GetUnitCommandCount(unitID) == 0
end

function M.Update(frame)
    if frame % 60 ~= 0 then return end
    
    for unitID in pairs(combatUnits) do
        if isIdle(unitID) then
            -- Unit has no orders; give it a new one
            local enemy = Spring.GetUnitNearestEnemy(unitID, 1200, true)
            if enemy then
                Spring.GiveOrderToUnit(unitID, CMD.FIGHT, {enemy}, {})
            end
        end
    end
end
```

**Why check idle?** Prevents order spam and lets units finish their current task before reassigning them.

## Pattern 5: Throttled Loops

Don't loop over all units every frame; stagger different checks:

```lua
function M.Update(frame)
    -- Every 60 frames: check combat units
    if frame % 60 == 0 then
        for unitID in pairs(combatUnits) do
            -- Combat logic
        end
    end
    
    -- Every 120 frames: check builders
    if frame % 120 == 0 then
        for unitID in pairs(builders) do
            -- Builder logic
        end
    end
    
    -- Every 300 frames: check resources
    if frame % 300 == 0 then
        local status = getResourceStatus()
        -- Resource logic
    end
end
```

**Why stagger?** Spreads CPU load across frames instead of doing everything at once.

## Pattern 6: Caching Expensive Queries

Cache results of expensive queries:

```lua
local M = {}
local myTeam
local myUnits = {}
local cachedEnemyStartPositions = {}
local lastEnemyQueryFrame = 0

function M.Init(teamID)
    myTeam = teamID
    local units = Spring.GetTeamUnits(teamID) or {}
    for i = 1, #units do
        myUnits[units[i]] = true
    end
end

local function getEnemyStartPositions(frame)
    -- Cache for 300 frames (10 seconds)
    if frame - lastEnemyQueryFrame > 300 then
        cachedEnemyStartPositions = {}
        local teamList = Spring.GetTeamList() or {}
        for _, teamID in ipairs(teamList) do
            local leader, allyTeam = Spring.GetTeamInfo(teamID)
            if allyTeam ~= Spring.GetTeamInfo(myTeam) then
                local x, y, z = Spring.GetTeamStartPosition(teamID)
                if x then
                    table.insert(cachedEnemyStartPositions, {
                        teamID = teamID,
                        x = x,
                        y = y,
                        z = z
                    })
                end
            end
        end
        lastEnemyQueryFrame = frame
    end
    return cachedEnemyStartPositions
end

function M.Update(frame)
    if frame % 60 ~= 0 then return end
    
    local enemies = getEnemyStartPositions(frame)
    for _, enemy in ipairs(enemies) do
        -- Use cached enemy positions
    end
end

return M
```

## Pattern 7: Simple Rush AI

A complete example that rushes all units toward the nearest enemy:

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

local function findNearestEnemyStartPos()
    local myX, _, myZ = Spring.GetTeamStartPosition(myTeam)
    if not myX then return nil end
    
    local teamList = Spring.GetTeamList() or {}
    local nearest = nil
    local nearestDist = math.huge
    
    for _, teamID in ipairs(teamList) do
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
    
    return nearest
end

function M.Update(frame)
    if frame % 90 ~= 0 then return end
    
    local target = findNearestEnemyStartPos()
    if not target then return end
    
    for unitID in pairs(myUnits) do
        local unitDefID = Spring.GetUnitDefID(unitID)
        local ud = UnitDefs[unitDefID]
        
        -- Move all mobile units toward enemy
        if ud and ud.canMove then
            Spring.GiveOrderToUnit(unitID, CMD.FIGHT, {target.x, target.y or 0, target.z}, {})
        end
    end
end

return M
```

## Pattern 8: Performance Optimization Tips

### Use Local Aliases

```lua
-- BAD: Table lookups every time
function M.Update(frame)
    Spring.GiveOrderToUnit(unitID, CMD.MOVE, {x, y, z}, {})
end

-- GOOD: Cache at module level
local spGiveOrderToUnit = Spring.GiveOrderToUnit
local spGetUnitDefID = Spring.GetUnitDefID

function M.Update(frame)
    spGiveOrderToUnit(unitID, CMD.MOVE, {x, y, z}, {})
end
```

### Avoid Repeated Table Lookups

```lua
-- BAD: Looks up UnitDefs multiple times
for unitID in pairs(myUnits) do
    if UnitDefs[Spring.GetUnitDefID(unitID)].canMove then
        -- ...
    end
end

-- GOOD: Cache the lookup
for unitID in pairs(myUnits) do
    local unitDefID = Spring.GetUnitDefID(unitID)
    local ud = UnitDefs[unitDefID]
    if ud and ud.canMove then
        -- ...
    end
end
```

### Minimize Table Allocations

```lua
-- BAD: Creates a new table every frame
function M.Update(frame)
    local units = Spring.GetTeamUnits(myTeam)
    -- ...
end

-- GOOD: Track units incrementally
function M.UnitCreated(unitID, unitDefID, teamID)
    if teamID == myTeam then myUnits[unitID] = true end
end

function M.UnitDestroyed(unitID, unitDefID, teamID)
    myUnits[unitID] = nil
end
```

## Pattern 9: Debugging and Logging

Add logging to understand what your AI is doing:

```lua
local M = {}
local myTeam
local lastLogFrame = 0

function M.Init(teamID)
    myTeam = teamID
    Spring.Echo("[MyAI] Initialized for team " .. teamID)
end

function M.Update(frame)
    -- Log every 300 frames (10 seconds)
    if frame - lastLogFrame >= 300 then
        local mCur, mStor = Spring.GetTeamResources(myTeam, "metal")
        local eCur, eStor = Spring.GetTeamResources(myTeam, "energy")
        
        Spring.Echo(string.format(
            "[MyAI] Frame %d | Metal: %.0f/%.0f | Energy: %.0f/%.0f",
            frame, mCur, mStor, eCur, eStor
        ))
        
        lastLogFrame = frame
    end
end

return M
```

## Next Steps

- Review the reference section for complete API documentation
- Look at `luarules/gadgets/ai_simpleai.lua` for more advanced patterns
- Experiment with your own strategies!
