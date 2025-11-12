# Command Reference

Quick lookup for all common commands.

## Movement

| Command | Usage | Notes |
|---------|-------|-------|
| `CMD.MOVE` | `{x, y, z}` | Move to position and stop |
| `CMD.FIGHT` | `{x, y, z}` | Move and attack enemies |
| `CMD.PATROL` | `{x, y, z}` | Patrol between start and position |

## Attack

| Command | Usage | Notes |
|---------|-------|-------|
| `CMD.ATTACK` | `{targetUnitID}` or `{x, y, z}` | Attack unit or position |
| `CMD.DGUN` | `{targetUnitID}` | D-gun attack (if available) |

## Building

| Command | Usage | Notes |
|---------|-------|-------|
| Build | `-unitDefID, {x, y, z, facing}` | Build structure (negative DefID) |

**Facing:** 0=South, 1=East, 2=North, 3=West

**Always test first:**
```lua
local ok = Spring.TestBuildOrder(unitDefID, x, y, z, facing)
if ok == 2 then
    -- ok == 2 is valid; ok == 0 is invalid; ok == 1 is iffy
end
```

## Utility

| Command | Usage | Notes |
|---------|-------|-------|
| `CMD.STOP` | `{}` | Stop all orders |
| `CMD.GUARD` | `{targetUnitID}` | Follow and protect unit |
| `CMD.RECLAIM` | `{featureID}` | Reclaim rock/tree/wreck |
| `CMD.REPAIR` | `{targetUnitID}` | Repair unit |
| `CMD.RESURRECT` | `{featureID}` | Resurrect dead unit (if able) |
| `CMD.LOAD_UNITS` | `{targetUnitID}` | Load unit into transport |
| `CMD.UNLOAD_UNITS` | `{x, y, z}` | Unload units at position |

## States

| Command | Usage | Notes |
|---------|-------|-------|
| `CMD.FIRE_STATE` | `{0\|1\|2}` | 0=Hold, 1=Return, 2=Fire at will |
| `CMD.MOVE_STATE` | `{0\|1\|2}` | 0=Hold, 1=Maneuver, 2=Roam |
| `CMD.ONOFF` | `{0\|1}` | 0=Off, 1=On |

## Other

| Command | Usage | Notes |
|---------|-------|-------|
| `CMD.SELFD` | `{}` | Self-destruct |
| `CMD.WAIT` | `{}` | Wait (for queued orders) |

## Options

Pass as fourth parameter to `Spring.GiveOrderToUnit`:

```lua
Spring.GiveOrderToUnit(unitID, CMD.MOVE, {x, y, z}, {"shift"})
```

| Option | Effect |
|--------|--------|
| `"shift"` | Queue order (don't replace) |
| `"alt"` | Alternate mode (varies by command) |
| `"ctrl"` | Control mode (varies by command) |
| `"right"` | Right-click mode (varies by command) |

## Example: Complete Order Sequence

```lua
-- Move to position 1
Spring.GiveOrderToUnit(unitID, CMD.MOVE, {x1, y1, z1}, {})

-- Queue: move to position 2
Spring.GiveOrderToUnit(unitID, CMD.MOVE, {x2, y2, z2}, {"shift"})

-- Queue: attack position 3
Spring.GiveOrderToUnit(unitID, CMD.ATTACK, {x3, y3, z3}, {"shift"})

-- Queue: guard the commander
Spring.GiveOrderToUnit(unitID, CMD.GUARD, {commanderID}, {"shift"})
```

The unit will execute these in order.
