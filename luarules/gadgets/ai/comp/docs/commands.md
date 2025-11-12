# Common Commands (CMD) Cheat Sheet

Issue with Spring.GiveOrderToUnit(unitID, CMD.<NAME>, params, options)

- Move: CMD.MOVE {x,y,z}
- Fight/Patrol: CMD.FIGHT {x,y,z}, CMD.PATROL {x,y,z}
- Attack: CMD.ATTACK {targetUnitID} or {x,y,z}
- Stop: CMD.STOP {}
- Guard/Repair/Reclaim/Resurrect: CMD.GUARD {target}, CMD.REPAIR {...}, CMD.RECLAIM {...}, CMD.RESURRECT {...}
- Load/Unload (transports): CMD.LOAD_UNITS {unitID}, CMD.UNLOAD_UNITS {x,y,z}
- Set states: CMD.FIRE_STATE {0..2}, CMD.MOVE_STATE {0..2}, CMD.ONOFF {0/1}, CMD.WAIT {}
- Self-destruct: CMD.SELFD {}
- Build: negative unitDefID e.g. -builtDefID {x,y,z,facing}

Options flags example: {"shift","alt","ctrl","right"}

Query per-unit queue: Spring.GetCommandQueue(unitID, n)
Cancel: Spring.GiveOrderToUnit(unitID, CMD.REMOVE, {cmdTag}, {}) (advanced)
