# The Game Loop and Timing

Understanding when your code runs is crucial for writing efficient AIs. This doc explains frames, ticks, and how to throttle decisions.

## Frames and the Game Loop

The engine runs at a fixed **30 frames per second** (FPS) by default. Every frame:

1. Physics and unit movement are updated.
2. Your AI's `Update(frame)` function is called.
3. The screen is rendered.

**One frame = ~33 milliseconds.**

The `frame` parameter in `Update(frame)` is a counter that increments every frame, starting from 0 at game start.

```lua
function M.Update(frame)
    Spring.Echo("Frame: " .. frame)  -- Prints 0, 1, 2, 3, ...
end
```

## Why Throttle Decisions?

Making decisions every frame is wasteful. Consider:

- **Every frame (30/sec):** You query all units, check resources, decide what to build, etc. That's 30 decisions per second.
- **Every 60 frames (2/sec):** You do the same thing, but only twice per second.

Units move slowly. A unit moving at 100 elmos/second travels only ~3 elmos per frame. You don't need to re-decide every 33ms; every 2 seconds is fine.

**Throttling saves CPU and makes your AI more predictable.**

## Common Throttling Patterns

### Every N Frames

```lua
function M.Update(frame)
    if frame % 60 ~= 0 then return end
    -- This code runs every 60 frames (~2 seconds)
end
```

The `%` operator is modulo (remainder). `frame % 60 == 0` is true when frame is 0, 60, 120, 180, etc.

### Every N Frames, Offset Per Team

If you have multiple AIs, stagger their decisions to avoid CPU spikes:

```lua
function M.Update(frame)
    local teamOffset = myTeam * 10  -- Each team offset by 10 frames
    if (frame + teamOffset) % 60 ~= 0 then return end
    -- Different teams decide at different times
end
```

This way, not all AIs decide at the same frame.

### Heartbeat (Rare Events)

```lua
function M.Update(frame)
    if frame % 600 == 0 then
        -- This runs every 600 frames (~20 seconds)
        Spring.Echo("[MyAI] Still alive!")
    end
end
```

Use heartbeats for logging, garbage collection, or rare checks.

## Frame Arithmetic

Some useful patterns:

```lua
-- Every 30 frames (1 second)
if frame % 30 == 0 then ... end

-- Every 60 frames (2 seconds)
if frame % 60 == 0 then ... end

-- Every 150 frames (5 seconds)
if frame % 150 == 0 then ... end

-- Every 300 frames (10 seconds)
if frame % 300 == 0 then ... end

-- Every 600 frames (20 seconds)
if frame % 600 == 0 then ... end

-- Every 1800 frames (60 seconds / 1 minute)
if frame % 1800 == 0 then ... end
```

## Real-Time Delays

Sometimes you want to wait a specific amount of time before doing something. Use a local timer:

```lua
local M = {}
local myTeam
local nextBuildTime = 0

function M.Init(teamID)
    myTeam = teamID
    nextBuildTime = 0  -- Can build immediately
end

function M.Update(frame)
    if frame < nextBuildTime then return end
    
    -- Try to build something
    local built = tryBuildMex()
    
    if built then
        -- Wait 5 seconds before trying again
        nextBuildTime = frame + 150  -- 150 frames = 5 seconds
    else
        -- Try again in 1 second
        nextBuildTime = frame + 30
    end
end

return M
```

**What's happening:**
- `nextBuildTime` stores the frame when we're allowed to build next.
- If current `frame < nextBuildTime`, we skip (still waiting).
- After building, we set `nextBuildTime = frame + 150` (5 seconds from now).

## Avoiding Order Spam

A common mistake is re-issuing the same order every frame:

```lua
-- BAD: This re-orders the unit every frame
function M.Update(frame)
    Spring.GiveOrderToUnit(unitID, CMD.MOVE, {x, y, z}, {})
end
```

The unit receives 30 move orders per second, which is wasteful and can cause jitter.

**Better: Throttle or check if the unit is idle:**

```lua
-- GOOD: Only re-order every 60 frames
function M.Update(frame)
    if frame % 60 ~= 0 then return end
    Spring.GiveOrderToUnit(unitID, CMD.MOVE, {x, y, z}, {})
end

-- BETTER: Only order if the unit has no commands
function M.Update(frame)
    if frame % 60 ~= 0 then return end
    
    local cmdCount = Spring.GetUnitCommandCount(unitID)
    if cmdCount == 0 then
        Spring.GiveOrderToUnit(unitID, CMD.MOVE, {x, y, z}, {})
    end
end
```

`Spring.GetUnitCommandCount(unitID)` returns how many orders are queued. If it's 0, the unit is idle and needs a new order.

## Queuing Orders

You can queue multiple orders with the "shift" option:

```lua
Spring.GiveOrderToUnit(unitID, CMD.MOVE, {x1, y1, z1}, {})
Spring.GiveOrderToUnit(unitID, CMD.MOVE, {x2, y2, z2}, {"shift"})
Spring.GiveOrderToUnit(unitID, CMD.MOVE, {x3, y3, z3}, {"shift"})
```

The unit will move to (x1, y1, z1), then (x2, y2, z2), then (x3, y3, z3).

**Without "shift"**, each order replaces the previous one.

## Synchronization Across Teams

All AIs' `Update` functions are called in the same frame. This means:

```lua
-- Frame 60: All AIs' Update(60) runs
-- Frame 61: All AIs' Update(61) runs
-- etc.
```

This is important for multiplayer fairness. If your AI decides to attack on frame 60, the enemy AI also gets to make decisions on frame 60 (they're not behind).

## Performance Tips

1. **Throttle aggressively.** Every 60-150 frames is usually fine.
2. **Cache queries.** Don't call `Spring.GetTeamUnits()` every frame; cache it and update on `UnitCreated`/`UnitDestroyed`.
3. **Use local aliases.** Store `Spring.GiveOrderToUnit` as a local variable to avoid table lookups.
4. **Avoid loops over all units every frame.** Only loop when you need to.

Example of caching:

```lua
local M = {}
local myTeam
local myUnits = {}
local spGiveOrderToUnit = Spring.GiveOrderToUnit  -- Local alias

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

function M.UnitDestroyed(unitID, unitDefID, teamID)
    myUnits[unitID] = nil
end

function M.Update(frame)
    if frame % 60 ~= 0 then return end
    
    for unitID in pairs(myUnits) do
        spGiveOrderToUnit(unitID, CMD.MOVE, {x, y, z}, {})  -- Fast lookup
    end
end

return M
```

## Next Steps

- **Next:** Read "Reading the Match State" to learn what game info is available.
- **Then:** Read "Querying the Environment" to learn how to scout the map.
