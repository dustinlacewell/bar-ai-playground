# Using Scenario Start Positions in Your AI

When a tournament scenario is loaded, it defines custom start positions for each team. Your AI should use these positions instead of the default ones.

## Quick Start

Load the scenario utilities library and use it to get positions:

```lua
local scenarioUtils = VFS.Include("luarules/gadgets/ai/comp/lib/scenario_utils.lua")

function M.Init(teamID)
    myTeam = teamID
    
    -- Get your team's start position (from scenario or default)
    local x, y, z = scenarioUtils.GetTeamStartPosition(teamID)
    Spring.Echo("My start position: " .. x .. ", " .. z)
end
```

## Available Functions

### `GetTeamStartPosition(teamID)`

Get the start position for any team.

**Returns:** `x, y, z` (or `nil` if not available)

```lua
local x, y, z = scenarioUtils.GetTeamStartPosition(0)
if x then
    Spring.Echo("Team 0 starts at: " .. x .. ", " .. z)
end
```

### `GetEnemyStartPositions(myTeamID)`

Get all enemy team start positions.

**Returns:** Table of `{teamID, x, y, z}` for each enemy

```lua
local enemies = scenarioUtils.GetEnemyStartPositions(myTeam)
for _, enemy in ipairs(enemies) do
    Spring.Echo("Enemy team " .. enemy.teamID .. " at " .. enemy.x .. ", " .. enemy.z)
end
```

### `GetNearestEnemyStartPosition(myTeamID, myX, myZ)`

Find the closest enemy start position to your current location.

**Returns:** `{teamID, x, y, z, distance}` or `nil`

```lua
local myX, _, myZ = Spring.GetTeamStartPosition(myTeam)
local nearest = scenarioUtils.GetNearestEnemyStartPosition(myTeam, myX, myZ)

if nearest then
    Spring.Echo("Nearest enemy at " .. nearest.x .. ", " .. nearest.z)
    Spring.Echo("Distance: " .. nearest.distance)
end
```

## Example: Rush AI Using Scenario Positions

```lua
local M = {}
local myTeam
local myUnits = {}
local scenarioUtils = VFS.Include("luarules/gadgets/ai/comp/lib/scenario_utils.lua")

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

function M.UnitDestroyed(unitID)
    myUnits[unitID] = nil
end

function M.Update(frame)
    if frame % 90 == 0 then
        -- Get nearest enemy start position from scenario
        local myX, _, myZ = Spring.GetTeamStartPosition(myTeam)
        local target = scenarioUtils.GetNearestEnemyStartPosition(myTeam, myX, myZ)
        
        if target then
            -- Rush all units to enemy start position
            for unitID in pairs(myUnits) do
                Spring.GiveOrderToUnit(unitID, CMD.FIGHT, {target.x, 0, target.z}, {})
            end
        end
    end
end

return M
```

## Why Use Scenario Positions?

- **Accuracy:** The scenario defines where teams actually start, not where the engine thinks they start.
- **Tournament fairness:** All AIs see the same positions.
- **Flexibility:** Works with any scenario layout (circle, opposite corners, etc.).

## Fallback Behavior

If `scenarioUtils` is not available or the scenario doesn't define positions, the functions fall back to `Spring.GetTeamStartPosition()`, which uses the engine's default positions. This ensures your AI works even without a custom scenario.
