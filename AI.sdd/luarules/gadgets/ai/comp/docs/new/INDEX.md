# BAR AI Competitor's Guide - Index

## Getting Started

Start here if you're new to writing AIs:

1. **README.md** – Overview and quick start
2. **01_foundations.md** – Concepts: Spring, Lua, synced code, game loop
3. **02_first_ai.md** – Your first working AI (step-by-step)
4. **03_game_loop.md** – Frames, throttling, timing patterns

## Core Concepts

Learn how to interact with the game:

5. **04_reading_match.md** – Querying units, resources, terrain, enemies
6. **05_giving_orders.md** – Building, moving, attacking, all commands
7. **06_practical_patterns.md** – Common strategies and optimizations

## Reference

Quick lookup tables and API documentation:

- **reference_commands.md** – All commands (MOVE, FIGHT, BUILD, etc.)
- **reference_spring_api.md** – Spring functions (units, teams, resources, terrain)
- **reference_unitdefs.md** – Understanding unit definitions
- **reference_weapons.md** – Weapon definitions, finding weapons, spawning projectiles
- **troubleshooting.md** – Common problems and solutions

## Reading Order

### For Beginners

1. README.md
2. 01_foundations.md
3. 02_first_ai.md
4. 03_game_loop.md
5. 04_reading_match.md
6. 05_giving_orders.md

Then pick a topic from **06_practical_patterns.md** that interests you.

### For Experienced Programmers

1. README.md (skim)
2. 01_foundations.md (skim)
3. 02_first_ai.md (skim)
4. reference_commands.md
5. reference_spring_api.md
6. reference_unitdefs.md
7. 06_practical_patterns.md

### For Debugging

- troubleshooting.md (start here)
- reference_spring_api.md (for API questions)
- reference_commands.md (for command questions)

## Key Concepts Summary

### Synced vs. Unsynced
- **Synced:** Your AI runs here. Deterministic, all clients see the same thing.
- **Unsynced:** UI and client-specific code. Not authoritative.

### Game Loop
- 30 frames per second
- Your `Update(frame)` is called every frame
- Throttle decisions (don't decide every frame)

### Unit Tracking
- Track your units in `myUnits` table
- Update on `UnitCreated`, `UnitFinished`, `UnitDestroyed`
- Iterate over `myUnits` to give orders

### Giving Orders
- `Spring.GiveOrderToUnit(unitID, CMD.<NAME>, params, options)`
- Always test build locations with `Spring.TestBuildOrder`
- Check unit idle status before reordering

### Performance
- Cache queries (don't call `Spring.GetTeamUnits()` every frame)
- Throttle aggressively (every 60-150 frames is fine)
- Use local aliases for frequently called functions
- Stagger different AI checks across frames

## File Locations

- **Your AI:** `luarules/gadgets/ai/comp/bots/<your_ai>.lua`
- **Select in Skirmish:** "Dev AI: <your_ai>"
- **Hot-reload:** `/luarules reload` in-game
- **Logs:** `<BAR_INSTALL>/data/infolog.txt`

## Quick Reference

### Module Structure
```lua
local M = {}

function M.Init(teamID) end
function M.Update(frame) end
function M.UnitCreated(unitID, unitDefID, teamID) end
function M.UnitFinished(unitID, unitDefID, teamID) end
function M.UnitDestroyed(unitID, unitDefID, teamID) end

return M
```

### Common Patterns
```lua
-- Track units
local myUnits = {}
for unitID in pairs(myUnits) do ... end

-- Throttle decisions
if frame % 60 ~= 0 then return end

-- Check unit idle
if Spring.GetUnitCommandCount(unitID) == 0 then ... end

-- Give order
Spring.GiveOrderToUnit(unitID, CMD.MOVE, {x, y, z}, {})

-- Test build location
local ok = Spring.TestBuildOrder(defID, x, y, z, facing)
if ok == 2 then ... end

-- Query resources
local mCur, mStor = Spring.GetTeamResources(myTeam, "metal")
```

## Next Steps

1. Read **README.md** for an overview
2. Follow the reading order for your experience level
3. Write your first AI using **02_first_ai.md**
4. Use the reference docs to look up specific APIs
5. Check **troubleshooting.md** if something goes wrong

Good luck!
