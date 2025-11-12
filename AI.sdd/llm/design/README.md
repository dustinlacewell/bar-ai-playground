# Bot Architecture Designs

This directory proposes several designs for a per-unit state-machine architecture with a central event/services layer.

- 01-overview.md — High-level goals, constraints, and core building blocks
- 02-per-unit-state-machines.md — Controller interface, lifecycle, and ticking
- 03-event-bus-and-services.md — Central gadget event routing and shared services
- 04-build-tracking.md — Build lifecycle tracking without timeouts (polling + events)
