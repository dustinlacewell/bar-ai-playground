# Build Tracking (No Timeouts)

Problem
- Avoid fixed waits after issuing builds; react to actual build lifecycle

Signals
- Spring.GetUnitIsBuilding(builderID) -> unitID/nil
- Spring.GetUnitHealth(unitID) -> select(5, ...) buildProgress in [0..1]
- Events: UnitCreated, UnitFinished, UnitDestroyed

Service Design: BuildTracker
- startTracking(builderID, unitDefID, wantedPos)
  - Try to capture currentBuild via GetUnitIsBuilding
  - If nil, wait for UnitCreated near wantedPos and matching unitDefID
- onUnitCreated/Finished/Destroyed
  - If created matches pending tracking, bind and emit BuildStarted(builderID, buildID)
  - On Finished/Destroyed, emit BuildCompleted/BuildFailed and clear
- query(builderID) -> { buildID, progress, finished, failed }

Controller Usage
- In BuildLLT.enter:
  - buildID = BuildTracker.startTracking(commanderID, LLTDefID, targetPos)
- In BuildWait.tick:
  - info = BuildTracker.query(commanderID)
  - if info.finished -> return prev state
  - if info.failed -> return prev or retry
  - else continue waiting

Fallbacks
- If tracking can’t bind within T frames, abort and return
- Optional periodic reissue if canceled
