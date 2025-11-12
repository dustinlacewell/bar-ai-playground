# Event Bus and Services

Event Bus (inside gadget)
- Receives Spring events
- Routes to interested controllers/services
- API:
  - register(listener, filters)
  - emit(event, payload)
- Mappings:
  - UnitCreated/Finished/Destroyed -> controller.onX
  - UnitIdle/UnitGiven/UnitTaken (optional)

Shared Services
- BuildTracker: bind builds to builders; track progress; raise BuildStarted/Completed/Failed
- Targeting: nearest enemies, priorities, commander location cache
- Economy: metal/energy availability heuristics
- Map/Geo: height, passability, safe spots, directions
- CommandQueue: safe order batching (stop-before-build, shift-queue)

Wiring
- Services subscribe to EventBus
- Controllers call services for data/actions
- Services may call back into controllers via events (e.g., build complete)
