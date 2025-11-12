# Your First AI

Let's build a minimal AI from scratch. This teaches you the structure and how the framework loads your code.

## The Absolute Minimum

Here's the tiniest working AI:

```lua
local M = {}

function M.Init(teamID)
    Spring.Echo("[MyAI] Hello from team " .. teamID)
end

return M
```

**What's happening:**

- `local M = {}` creates an empty table (your module)
- `function M.Init(teamID)` defines a function that runs once at game start
- `Spring.Echo(...)` prints to the console and `infolog.txt`
- `return M` returns your module so the framework can call your functions

**To use it:**

1. Save as `luarules/gadgets/ai/comp/bots/my_first_ai.lua`
2. Restart the game
3. Select "Dev AI: my_first_ai" in Skirmish
4. Check the console for your message

## Tracking Your Units

Most AIs need to know what units they control. Let's add that:

```lua
local M = {}
local myTeam
local myUnits = {}

function M.Init(teamID)
    myTeam = teamID
    Spring.Echo("[MyAI] Init for team " .. teamID)
    
    -- Capture units that already exist (e.g., the commander at start)
    local units = Spring.GetTeamUnits(teamID) or {}
    for i = 1, #units do
        myUnits[units[i]] = true
    end
    
    Spring.Echo("[MyAI] Starting with " .. #units .. " units")
end

function M.UnitCreated(unitID, unitDefID, teamID)
    if teamID == myTeam then
        myUnits[unitID] = true
    end
end

function M.UnitFinished(unitID, unitDefID, teamID)
    if teamID == myTeam then
        myUnits[unitID] = true
    end
end

function M.UnitDestroyed(unitID, unitDefID, teamID)
    myUnits[unitID] = nil
end

return M
```

**Key points:**

- `myTeam` stores your team ID (used to filter events from other teams)
- `myUnits` is a table where keys are unit IDs. We use `myUnits[unitID] = true` to track them
- `Spring.GetTeamUnits(teamID)` returns a list of all units your team owns at that moment
- `UnitCreated` fires when a unit is built (or spawned)
- `UnitFinished` fires when a unit finishes construction
- `UnitDestroyed` fires when a unit dies

**Why track units?** Because you need to know which units to give orders to. Without tracking, you'd have to query all units every frame (slow).

## Adding a Game Loop

Now let's make decisions every few frames:

```lua
local M = {}
local myTeam
local myUnits = {}

function M.Init(teamID)
    myTeam = teamID
    Spring.Echo("[MyAI] Init for team " .. teamID)
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
    -- Only make decisions every 60 frames (roughly 2 decisions per second)
    if frame % 60 ~= 0 then return end
    
    -- Heartbeat: log that we're alive
    if frame % 600 == 0 then
        local unitCount = 0
        for _ in pairs(myUnits) do unitCount = unitCount + 1 end
        Spring.Echo("[MyAI] Heartbeat: " .. unitCount .. " units")
    end
    
    -- TODO: Make actual decisions here
end

return M
```

**What's new:**

- `function M.Update(frame)` is called every frame (30 times per second)
- `if frame % 60 ~= 0 then return end` means "only run this code every 60 frames." This throttles decisions
- `frame % 600 == 0` means "every 600 frames" (20 seconds). We use this for heartbeats
- We count units by iterating `myUnits` and incrementing a counter

**Why throttle?** Making decisions every frame is wasteful. Units move slowly; you don't need to re-decide every 33ms. Every 60 frames (2 seconds) is reasonable for most AIs.

## Issuing Your First Order

Let's make units move to the team's start position:

```lua
local M = {}
local myTeam
local myUnits = {}

function M.Init(teamID)
    myTeam = teamID
    Spring.Echo("[MyAI] Init for team " .. teamID)
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
    
    -- Get the team's start position
    local sx, sy, sz = Spring.GetTeamStartPosition(myTeam)
    if not sx then return end  -- Start pos not available yet
    
    -- Order all units to move there
    for unitID in pairs(myUnits) do
        Spring.GiveOrderToUnit(unitID, CMD.MOVE, {sx, sy, sz}, {})
    end
end

return M
```

**New concepts:**

- `Spring.GetTeamStartPosition(myTeam)` returns the team's start position (x, y, z)
- `Spring.GiveOrderToUnit(unitID, CMD.MOVE, {x, y, z}, {})` orders a unit to move
  - `unitID`: which unit to order
  - `CMD.MOVE`: the command (move)
  - `{x, y, z}`: the position to move to
  - `{}`: options (empty for now; could include "shift" to queue orders)

**What happens:** Every 60 frames, all your units move to your start position. They'll keep moving there until they arrive or you give a new order.

## Checking Unit Properties

Let's only move mobile units (not buildings):

```lua
function M.Update(frame)
    if frame % 60 ~= 0 then return end
    
    local sx, sy, sz = Spring.GetTeamStartPosition(myTeam)
    if not sx then return end
    
    for unitID in pairs(myUnits) do
        local unitDefID = Spring.GetUnitDefID(unitID)
        local unitDef = unitDefID and UnitDefs[unitDefID]
        
        -- Only move units that can move
        if unitDef and unitDef.canMove then
            Spring.GiveOrderToUnit(unitID, CMD.MOVE, {sx, sy, sz}, {})
        end
    end
end
```

**New concepts:**

- `Spring.GetUnitDefID(unitID)` returns the unit's definition ID
- `UnitDefs[unitDefID]` is a table with all info about that unit type
- `unitDef.canMove` is a boolean: true if the unit can move, false if it's a building

**What happens:** Only mobile units move. Buildings stay put.

## Complete Working Example

Here's a complete, working AI that you can save and run:

```lua
local M = {}
local myTeam
local myUnits = {}

function M.Init(teamID)
    myTeam = teamID
    Spring.Echo("[MyAI] Init for team " .. teamID)
    local units = Spring.GetTeamUnits(teamID) or {}
    for i = 1, #units do
        myUnits[units[i]] = true
    end
    Spring.Echo("[MyAI] Starting with " .. #units .. " units")
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
    
    if frame % 600 == 0 then
        local count = 0
        for _ in pairs(myUnits) do count = count + 1 end
        Spring.Echo("[MyAI] Heartbeat: " .. count .. " units")
    end
    
    local sx, sy, sz = Spring.GetTeamStartPosition(myTeam)
    if not sx then return end
    
    for unitID in pairs(myUnits) do
        local unitDefID = Spring.GetUnitDefID(unitID)
        local unitDef = unitDefID and UnitDefs[unitDefID]
        
        if unitDef and unitDef.canMove then
            Spring.GiveOrderToUnit(unitID, CMD.MOVE, {sx, sy, sz}, {})
        end
    end
end

return M
```

Save this as `luarules/gadgets/ai/comp/bots/my_first_ai.lua`, select it in Skirmish, and watch your units march home.

## Debugging

If something goes wrong:

- Check `<BAR_INSTALL>/data/infolog.txt` for error messages
- Add `Spring.Echo(...)` calls to print debug info
- Use `/luarules reload` in-game to reload your code without restarting

## Next Steps

- **Next:** Read **03_game_loop.md** to understand frame rates and throttling better
- **Then:** Read **04_reading_match.md** to learn how to query the game state
- **Advanced:** Read **05_giving_orders.md** to learn all the commands available
