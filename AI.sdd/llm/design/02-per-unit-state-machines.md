# Per-Unit State Machines

Controller Interface
- init(teamID, unitID, services)
- ready(frame)
- tick(frame)
- onUnitCreated(unitID, unitDefID, teamID)
- onUnitFinished(unitID, unitDefID, teamID)
- onUnitDestroyed(unitID)
- getDebugState()

State Machine (lightweight)
- states: { name -> { enter(sm, prev), tick(sm), exit(sm, next) } }
- setState(name)
- update() increments ticksInState and runs current:tick(sm)

Commander Controller Example (duel)
- Travel: fight toward enemy spawn/commander
- Engage: ATTACK target commander while we have HP margin
- Retreat: kite; periodically issues movement away
- BuildLLT: place LLT via BuildService/BU.tryPlaceNear; wait until build completes

Tick Cadence
- Controller.tick is called each frame or every N frames via Scheduler
- Use small internal counters for sub-cadence tasks (e.g., retarget every 60f)

Ownership
- Controller owns its state machine and minimal per-unit data
- Heavy logic lives in services (e.g., BuildTracker, Targeting)
