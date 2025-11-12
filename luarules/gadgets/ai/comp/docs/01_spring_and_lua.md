# What is Spring and Lua in BAR?

If you've played Beyond All Reason, you know the game runs on the **Recoil engine** (a fork of Spring RTS). When you write a custom AI, you're writing **Lua code** that runs inside that engine and controls units in real-time.

This doc explains what that means and why it matters.

## The Engine: Spring/Recoil

Spring is an open-source RTS engine. BAR uses **Recoil**, a modernized fork. Think of it like this:

- **The engine** handles physics, rendering, networking, unit pathfinding, and the game loop.
- **Your AI code** runs inside the engine and makes decisions: "build a mex here," "attack that unit," "move to this position."
- **The game data** (unit definitions, weapons, maps) lives in `.sdd` files (Spring Data Directories).

## Lua: The Scripting Language

Lua is a lightweight scripting language. BAR uses it for:
- **AIs** (what you're writing)
- **Gadgets** (game logic and utilities)
- **Widgets** (UI and client-side features)

Why Lua? It's fast, simple, and sandboxable—perfect for a real-time strategy game where thousands of decisions happen per second.

## Synced vs. Unsynced Code

This is the **most important concept** to understand.

### Synced Code (What Your AI Runs)

**Synced code** runs on all clients and the server in lockstep. It's deterministic and authoritative.

- **Your AI code runs here.** It makes decisions about unit orders.
- **All players see the same thing.** If your AI orders a unit to move, everyone sees it move the same way.
- **No randomness** (well, seeded randomness only). This ensures all clients stay in sync.
- **Limited APIs.** You can't access the file system, network, or UI. You only get game-related functions.
- **Runs in "gadgets"** (synced gadgets specifically).

### Unsynced Code (Widgets, UI, Visualization)

**Unsynced code** runs only on your local client. It's for UI, rendering, and client-specific logic.

- **Your AI doesn't run here.** Widgets and UI gadgets do.
- **Each player can see different things.** Your UI might show different info than your opponent's.
- **Full access to Lua.** File I/O, networking, debugging—all available.
- **Not authoritative.** Unsynced code can't affect the game state directly.

**For your AI:** You only care about synced code. Your AI module runs in a synced gadget and makes all its decisions there.

## The Game Loop

Every frame (30 times per second by default), the engine:

1. Processes input and network messages.
2. Updates physics and unit positions.
3. **Calls your AI's `Update(frame)` function** (if you've implemented it).
4. Renders the screen.

Your AI gets a chance to issue orders every frame. You decide how often to actually make decisions (e.g., every 60 frames = 2 decisions per second).

## Your AI Module

When you write an AI, you create a Lua module (a `.lua` file) that returns a table with optional functions:

```lua
local M = {}

function M.Init(teamID)
  -- Called once at game start for your team
end

function M.Update(frame)
  -- Called every frame; make decisions here
end

function M.UnitCreated(unitID, unitDefID, teamID)
  -- Called when a unit is created
end

function M.UnitFinished(unitID, unitDefID, teamID)
  -- Called when a unit finishes building
end

function M.UnitDestroyed(unitID, unitDefID, teamID)
  -- Called when a unit dies
end

return M
```

The **ai_framework** gadget (part of the mod) loads your module and forwards these events to you.

## The Spring API

Inside your AI, you have access to the `Spring` global table. It provides functions to:

- Query unit info: `Spring.GetTeamUnits(teamID)`, `Spring.GetUnitPosition(unitID)`, etc.
- Read resources: `Spring.GetTeamResources(teamID, "metal")`
- Issue orders: `Spring.GiveOrderToUnit(unitID, CMD.MOVE, {x, y, z}, {})`
- Query the map: `Spring.GetGroundHeight(x, z)`, `Spring.GetFeaturesInRectangle(...)`
- And much more.

You also have access to:
- **`UnitDefs`**: A table of all unit definitions (what units can do, their costs, etc.).
- **`FeatureDefs`**: A table of all feature definitions (rocks, trees, wrecks, etc.).
- **`CMD`**: A table of command constants (MOVE, FIGHT, BUILD, etc.).
- **`Game`**: Global game info (map name, size, wind, tidal, etc.).

## Why This Matters

Understanding synced vs. unsynced helps you:
- Know what APIs are available to you (no file I/O, no networking).
- Understand why your AI runs the same way on all clients.
- Debug issues (if your AI does something weird, it's deterministic—it'll do it the same way every time).

Understanding the game loop helps you:
- Know when your code runs and how often.
- Throttle decisions (don't make a decision every frame; that's wasteful).
- Coordinate multi-unit tactics (all your decisions happen in the same frame).

## Next Steps

Now that you know the basics:
- **Next:** Read "Your First AI Module" to see a minimal working example.
- **Then:** Read "The Game Loop and Timing" to understand when and how often to make decisions.
