# Spring API Reference

Quick lookup for commonly used Spring functions.

## Units

### Get Units

```lua
Spring.GetTeamUnits(teamID) -> {unitID, ...}
```

Get all units owned by a team.

### Unit Info

```lua
Spring.GetUnitDefID(unitID) -> unitDefID
Spring.GetUnitPosition(unitID) -> x, y, z
Spring.GetUnitHealth(unitID) -> hp, maxHp, ...
Spring.GetUnitTeam(unitID) -> teamID
Spring.GetUnitAllyTeam(unitID) -> allyTeamID
```

### Unit Commands

```lua
Spring.GetUnitCommandCount(unitID) -> count
Spring.GetCommandQueue(unitID, maxCount) -> {cmd, ...}
Spring.GiveOrderToUnit(unitID, CMD.<NAME>, params, options)
```

### Unit Search

```lua
Spring.GetUnitNearestEnemy(unitID, radius, inLos) -> enemyUnitID
```

Find nearest enemy to a unit within radius. `inLos` = line-of-sight only.

## Teams

### Team Lists

```lua
Spring.GetTeamList() -> {teamID, ...}
```

Get all team IDs in the game.

### Team Info

```lua
Spring.GetTeamInfo(teamID) -> leader, allyTeam, startMetal, startEnergy, isAI, side, allyTeamID
```

Get info about a team.

### Team Position

```lua
Spring.GetTeamStartPosition(teamID) -> x, y, z
```

Get where a team started.

### Team AI

```lua
Spring.GetTeamLuaAI(teamID) -> aiName
```

Get the AI name for a team.

## Resources

```lua
Spring.GetTeamResources(teamID, "metal"|"energy") -> current, storage, pull, income, expense, share
```

Get resource info for a team.

**Returns:**
- `current` – Current amount available
- `storage` – Storage capacity
- `pull` – Amount being pulled (negative = deficit)
- `income` – Income per frame
- `expense` – Expense per frame
- `share` – Amount shared with allies

**Example:**
```lua
local mCur, mStor = Spring.GetTeamResources(myTeam, "metal")
local eCur, eStor = Spring.GetTeamResources(myTeam, "energy")
```

## Map and Terrain

### Map Info

```lua
Game.mapName -> string
Game.mapSizeX -> width in elmos
Game.mapSizeZ -> height in elmos
Game.windMin, Game.windMax -> wind range
Game.tidal -> tidal strength
```

### Terrain

```lua
Spring.GetGroundHeight(x, z) -> height
Spring.GetGroundInfo(x, z) -> type, type2, hasMetal
```

## Features (Rocks, Trees, Wrecks)

### Find Features

```lua
Spring.GetFeaturesInRectangle(x1, z1, x2, z2) -> {featureID, ...}
```

Get all features in a rectangle.

### Feature Info

```lua
Spring.GetFeatureDefID(featureID) -> defID
Spring.GetFeaturePosition(featureID) -> x, y, z
Spring.GetFeatureResources(featureID) -> metal, energy, reclaimLeft
```

### Feature Definitions

```lua
FeatureDefs[defID].name -> string
FeatureDefs[defID].metal -> metal value
FeatureDefs[defID].energy -> energy value
FeatureDefs[defID].reclaimable -> boolean
FeatureDefs[defID].destructable -> boolean
```

## Unit Definitions

```lua
UnitDefs[unitDefID].name -> string
UnitDefs[unitDefID].isBuilding -> boolean
UnitDefs[unitDefID].isFactory -> boolean
UnitDefs[unitDefID].canMove -> boolean
UnitDefs[unitDefID].metalCost -> number
UnitDefs[unitDefID].energyCost -> number
UnitDefs[unitDefID].buildOptions -> {unitDefID, ...}
UnitDefs[unitDefID].xsize, .zsize -> footprint in squares
UnitDefs[unitDefID].extractsMetal -> boolean
UnitDefs[unitDefID].windGenerator -> boolean
UnitDefs[unitDefID].tidalGenerator -> boolean
UnitDefs[unitDefID].energyMake -> energy production
UnitDefs[unitDefID].weapons -> {weapon, ...}
UnitDefs[unitDefID].customParams -> {key=value, ...}
```

## Building

```lua
Spring.TestBuildOrder(unitDefID, x, y, z, facing) -> 0|1|2
```

Test if a build location is valid.

**Returns:**
- `0` – Invalid
- `1` – Iffy (blocked or steep)
- `2` – Valid (use this)

## Debugging

```lua
Spring.Echo(tag, value1, value2, ...)
```

Print to console and `infolog.txt`.

## Shared Utilities (GG Table)

```lua
if GG and GG.some_utility then
    GG.some_utility.doSomething()
end
```

Other gadgets may expose utilities in the `GG` table. Always check existence first.

## Random

```lua
math.random(a, b) -> number
```

Generate random number. Consider seeding with `GameID` if determinism matters.

## Common Patterns

### Check if unit can build

```lua
local ud = UnitDefs[unitDefID]
local canBuild = ud and ud.isBuilder and #ud.buildOptions > 0
```

### Find all units of a type

```lua
local function findUnitsOfType(unitType)
    local result = {}
    for unitID in pairs(myUnits) do
        local unitDefID = Spring.GetUnitDefID(unitID)
        if unitDefID == unitType then
            table.insert(result, unitID)
        end
    end
    return result
end
```

### Check if unit is idle

```lua
local isIdle = Spring.GetUnitCommandCount(unitID) == 0
```

### Get unit health percentage

```lua
local hp, maxHp = Spring.GetUnitHealth(unitID)
local healthPercent = (hp / maxHp) * 100
```

### Check if team is enemy

```lua
local function isEnemy(teamID)
    local myAllyTeam = Spring.GetTeamInfo(myTeam)
    local theirAllyTeam = Spring.GetTeamInfo(teamID)
    return myAllyTeam ~= theirAllyTeam
end
```
