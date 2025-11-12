# Overview

Goals
- Per-unit autonomy via simple state machines
- Central services for global concerns (events, scanning, economy, pathing)
- Deterministic and observable: minimal hidden state, good logging hooks
- Easy to extend/compose: small interfaces, dependency-injected services

Constraints
- Spring gadget APIs (UnitCreated/Finished/Destroyed, GameFrame, etc.)
- Avoid long-running processes; tick-driven
- Cheap per-frame work; amortize via cadence and caching

Core Building Blocks
- UnitController (one per controlled unit)
- ControllerRegistry (unitID->controller)
- EventBus (fan-out Spring events to controllers)
- Services (BuildTracker, Targeting, Economy, Map/Geo, CommandQueue)
- Scheduler (per-frame, per-cadence execution)

Data Flow
- Spring -> EventBus -> Controllers + Services
- GameFrame -> Scheduler -> Controllers:tick()
- Controllers -> CommandQueue -> Spring.GiveOrderToUnit
