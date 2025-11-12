# Spring (Recoil) Lua API Quick Reference (synced)

This is a practical subset for BAR Lua AIs. Full API lives in the engine source; this cheatsheet groups common calls.

- Modules available: `Spring`, `Game`, `CMD`, `UnitDefs`, `FeatureDefs`, `WeaponDefs`, `VFS`.
- Synced vs Unsynced: AI runs in synced gadgets; avoid `debug`, IO, and widget-only APIs.

## Units
- Get team units: `Spring.GetTeamUnits(teamID) -> {unitID,...}`
- Unit info: `Spring.GetUnitDefID(unitID) -> unitDefID`
- Position: `Spring.GetUnitPosition(unitID) -> x,y,z`
- Health: `Spring.GetUnitHealth(unitID) -> hp, maxhp, ...`
- Commands: `Spring.GetUnitCommandCount(unitID)`, `Spring.GetCommandQueue(unitID, n)`
- Team/ally: `Spring.GetUnitTeam(unitID)`, `Spring.GetUnitAllyTeam(unitID)`
- Nearest enemy: `Spring.GetUnitNearestEnemy(unitID, radius, inLos) -> enemyUnitID`
- Orders: `Spring.GiveOrderToUnit(unitID, CMD.<NAME>, params, opts)`

## Teams & AIs
- Teams: `Spring.GetTeamList() -> {teamID,...}`
- Team info: `Spring.GetTeamInfo(teamID) -> leader, allyTeam, startMetal, startEnergy, isAI, side, allyTeamID`
- LuaAI per team: `Spring.GetTeamLuaAI(teamID) -> string`
- Start pos: `Spring.GetTeamStartPosition(teamID) -> x,y,z`

## Resources
- Team resources: `Spring.GetTeamResources(teamID, "metal"|"energy") -> current, storage, pull, income, expense, share`
- Set (cheats/testing): `Spring.SetTeamResource(teamID, "m"|"e", amount)`

## Map & Env
- Map name/size: `Game.mapName`, `Game.mapSizeX`, `Game.mapSizeZ`
- Wind/tidal: `Game.windMin`, `Game.windMax`, `Game.tidal`
- Ground: `Spring.GetGroundHeight(x,z)`; `Spring.GetGroundInfo(x,z) -> type, type2, metal`

## Features (rocks/trees/wrecks)
- Search: `Spring.GetFeaturesInRectangle(x1,z1,x2,z2) -> {featureID,...}`
- Def & pos: `Spring.GetFeatureDefID(featureID) -> defID`, `Spring.GetFeaturePosition(featureID)`
- Resources: `Spring.GetFeatureResources(featureID) -> metal, energy, reclaimLeft`
- Def table: `FeatureDefs[defID]` (has `metal`, `energy`, `reclaimable`, etc.)

## Building
- Test placement: `Spring.TestBuildOrder(unitDefID, x,y,z, facing) -> 0|1|2`
- Give build: `Spring.GiveOrderToUnit(builderID, -unitDefID, {x,y,z,facing}, opts)`
- Footprint: `UnitDefs[unitDefID].xsize`, `.zsize` (tiles; ×8 elmos)

## Definitions
- Unit def table: `UnitDefs[unitDefID]` (fields: `name`, `isBuilding`, `canMove`, `isFactory`, `buildOptions`, `customParams`, etc.)
- Weapon def via unit: `UnitDefs[udid].weapons[i].weaponDef -> wdid`, then `WeaponDefs[wdid]`
- Feature defs: `FeatureDefs[defID]`

## VFS helpers
- Exists: `VFS.FileExists(path)`
- Read file: `VFS.LoadFile(path)`
- List dir: `VFS.DirList(dir, pattern, mode)`

## GG shared table (synced)
- Some gadgets expose utilities in `GG` (e.g., `GG.resource_spot_finder.metalSpotsList`).
- Always check existence: `if GG and GG.foo then ... end`
- Do not rely on it in isolation; add fallbacks if missing.

## Common CMDs
- MOVE, FIGHT, PATROL, STOP, ATTACK, RECLAIM, REPAIR, GUARD, RESURRECT, DGUN, SELFD
- See `ai/comp/commands.md` for parameters and usage patterns.

## Misc
- Random: `math.random(a,b)`, consider seeding via `GameID` if needed.
- Frame: many gadgets tick on `gadget:GameFrame(n)` / `Update(frame)`.
