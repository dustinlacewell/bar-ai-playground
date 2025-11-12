# Troubleshooting

Common problems and how to fix them.

## My AI Doesn't Load

### Problem: "Dev AI: my_ai" doesn't appear in Skirmish

**Causes:**
- File is in the wrong location
- Filename doesn't match
- Lua syntax error

**Solutions:**
1. Check file location: `luarules/gadgets/ai/comp/bots/my_ai.lua`
2. Check filename matches what you select (without `.lua`)
3. Check `infolog.txt` for Lua errors
4. Restart the game after creating the file

### Problem: AI loads but immediately crashes

**Causes:**
- Lua syntax error
- Missing `return M` statement
- Trying to access undefined variables

**Solutions:**
1. Check `infolog.txt` for error messages
2. Make sure you have `return M` at the end
3. Use `Spring.Echo()` to debug

## My AI Doesn't Do Anything

### Problem: Init runs but Update never runs

**Causes:**
- `Update` function not defined
- `Update` returns early every frame

**Solutions:**
```lua
-- Make sure you have Update defined
function M.Update(frame)
    -- This must exist
end

-- Make sure you're not returning early
function M.Update(frame)
    if frame % 60 ~= 0 then return end  -- OK
    -- ... code here
end
```

### Problem: Units don't get orders

**Causes:**
- `myUnits` table is empty
- Units are idle but you're not ordering them
- Orders are invalid

**Solutions:**
```lua
-- Debug: Check if you have units
if frame % 600 == 0 then
    local count = 0
    for _ in pairs(myUnits) do count = count + 1 end
    Spring.Echo("[MyAI] Unit count: " .. count)
end

-- Debug: Check if units are idle
for unitID in pairs(myUnits) do
    local cmdCount = Spring.GetUnitCommandCount(unitID)
    Spring.Echo("[MyAI] Unit " .. unitID .. " has " .. cmdCount .. " commands")
end
```

## My AI Spams Orders

### Problem: Units jitter or move erratically

**Causes:**
- Issuing the same order every frame
- Not checking if unit is idle

**Solutions:**
```lua
-- BAD: Spams orders every frame
function M.Update(frame)
    Spring.GiveOrderToUnit(unitID, CMD.MOVE, {x, y, z}, {})
end

-- GOOD: Only order idle units
function M.Update(frame)
    if frame % 60 ~= 0 then return end
    
    if Spring.GetUnitCommandCount(unitID) == 0 then
        Spring.GiveOrderToUnit(unitID, CMD.MOVE, {x, y, z}, {})
    end
end
```

## My AI Runs Slowly

### Problem: Game stutters when my AI runs

**Causes:**
- Looping over all units every frame
- Expensive queries every frame
- Too many table allocations

**Solutions:**

1. **Throttle aggressively:**
```lua
-- Instead of every frame
if frame % 60 ~= 0 then return end
```

2. **Cache unit lists:**
```lua
-- BAD: Queries every frame
function M.Update(frame)
    local units = Spring.GetTeamUnits(myTeam)
    for i, unitID in ipairs(units) do
        -- ...
    end
end

-- GOOD: Track incrementally
function M.UnitCreated(unitID, unitDefID, teamID)
    if teamID == myTeam then myUnits[unitID] = true end
end

function M.Update(frame)
    for unitID in pairs(myUnits) do
        -- ...
    end
end
```

3. **Use local aliases:**
```lua
-- At module level
local spGiveOrderToUnit = Spring.GiveOrderToUnit
local spGetUnitDefID = Spring.GetUnitDefID

-- In functions
spGiveOrderToUnit(unitID, CMD.MOVE, {x, y, z}, {})
```

4. **Stagger different checks:**
```lua
function M.Update(frame)
    if frame % 60 == 0 then
        -- Combat logic
    end
    
    if frame % 120 == 0 then
        -- Builder logic
    end
    
    if frame % 300 == 0 then
        -- Resource checks
    end
end
```

## My AI Doesn't Build

### Problem: AI tries to build but nothing happens

**Causes:**
- Not enough resources
- Invalid build location
- Builder is busy

**Solutions:**
```lua
-- Always test before building
local ok = Spring.TestBuildOrder(builtDefID, x, y, z, facing)
if ok ~= 2 then
    Spring.Echo("[MyAI] Build failed: " .. ok)
    return
end

-- Check resources
local mCur, mStor = Spring.GetTeamResources(myTeam, "metal")
if mCur < UnitDefs[builtDefID].metalCost then
    Spring.Echo("[MyAI] Not enough metal")
    return
end

-- Check builder is idle
if Spring.GetUnitCommandCount(builderID) > 0 then
    Spring.Echo("[MyAI] Builder is busy")
    return
end
```

## My AI Doesn't Find Enemies

### Problem: `GetUnitNearestEnemy` returns nil

**Causes:**
- No enemies in range
- Enemies not in line-of-sight
- Wrong radius

**Solutions:**
```lua
-- Increase search radius
local enemy = Spring.GetUnitNearestEnemy(unitID, 2000, false)  -- Larger radius, no LoS

-- Check if enemy exists
if enemy then
    local ex, ey, ez = Spring.GetUnitPosition(enemy)
    if ex then
        Spring.GiveOrderToUnit(unitID, CMD.FIGHT, {ex, ey or 0, ez}, {})
    end
else
    Spring.Echo("[MyAI] No enemy found")
end
```

## My AI Crashes with "nil" Error

### Problem: Error like "attempt to index nil value"

**Causes:**
- Accessing a table that doesn't exist
- Function returns nil when you expect a value

**Solutions:**
```lua
-- BAD: Assumes unitDef exists
local ud = UnitDefs[unitDefID]
local canMove = ud.canMove

-- GOOD: Check for nil
local ud = UnitDefs[unitDefID]
if ud then
    local canMove = ud.canMove
end

-- Or use short-circuit
local canMove = ud and ud.canMove
```

## My AI Doesn't React to Events

### Problem: `UnitCreated` or `UnitDestroyed` not called

**Causes:**
- Not checking `teamID`
- Event handler not defined
- Typo in function name

**Solutions:**
```lua
-- Make sure you check teamID
function M.UnitCreated(unitID, unitDefID, teamID)
    if teamID ~= myTeam then return end  -- Only track your units
    myUnits[unitID] = true
end

-- Make sure function names are exact
function M.UnitFinished(unitID, unitDefID, teamID)  -- Not "UnitFinishedBuilding"
    if teamID == myTeam then myUnits[unitID] = true end
end

function M.UnitDestroyed(unitID, unitDefID, teamID)  -- Not "UnitDied"
    myUnits[unitID] = nil
end
```

## Debugging Tips

### Use Spring.Echo

```lua
-- Print to console and infolog.txt
Spring.Echo("[MyAI] Debug message: " .. value)

-- Use string formatting
Spring.Echo(string.format("[MyAI] Metal: %.0f/%.0f", mCur, mStor))
```

### Check infolog.txt

Location: `<BAR_INSTALL>/data/infolog.txt`

Contains all error messages and `Spring.Echo` output.

### Use Hot-Reload

```
/luarules reload
```

Reloads all synced gadgets without restarting. Your AI will be reloaded with new code.

### Add Heartbeats

```lua
function M.Update(frame)
    if frame % 600 == 0 then
        Spring.Echo("[MyAI] Heartbeat: still running")
    end
end
```

If you don't see heartbeats, your `Update` isn't being called.

### Print Unit Info

```lua
for unitID in pairs(myUnits) do
    local unitDefID = Spring.GetUnitDefID(unitID)
    local ud = UnitDefs[unitDefID]
    local x, y, z = Spring.GetUnitPosition(unitID)
    local cmdCount = Spring.GetUnitCommandCount(unitID)
    
    Spring.Echo(string.format(
        "[MyAI] Unit %d: %s at (%.0f, %.0f) with %d commands",
        unitID, ud.name, x, z, cmdCount
    ))
end
```

## Getting Help

1. Check `infolog.txt` for error messages
2. Add `Spring.Echo()` calls to trace execution
3. Use `/luarules reload` to test changes quickly
4. Look at `luarules/gadgets/ai_simpleai.lua` for examples
5. Review the reference docs for API details
