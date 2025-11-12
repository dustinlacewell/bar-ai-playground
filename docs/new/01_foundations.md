# Foundations: Spring, Lua, and Synced Code

Before you write an AI, you need to understand three things: what Spring is, what Lua is, and what "synced" means.

## What is Spring/Recoil?

Spring is an open-source RTS engine. Beyond All Reason uses **Recoil**, a modernized fork of Spring.

Think of it like this:

- **The engine** handles physics, rendering, pathfinding, and the game loop
- **Game data** (unit definitions, weapons, maps) lives in `.sdd` files
- **Your AI code** runs inside the engine and makes decisions: "build here," "attack that," "move there"

When you write an AI, you're writing code that runs inside this engine and controls units in real-time.

## What is Lua?

Lua is a lightweight scripting language. BAR uses it for:

- **AIs** (what you're writing)
- **Gadgets** (game logic and utilities)
- **Widgets** (UI and client-side features)

Why Lua? It's fast, simple, and sandboxable—perfect for a real-time strategy game where thousands of decisions happen per second.

## The Most Important Concept: Synced vs. Unsynced

This is the **critical distinction** you need to understand.

### Synced Code (Where Your AI Runs)

**Synced code** runs on all clients and the server in lockstep. It's deterministic and authoritative.

- **Your AI runs here.** It makes decisions about unit orders.
- **All players see the same thing.** If your AI orders a unit to move, everyone sees it move identically.
- **No randomness** (except seeded randomness). This ensures all clients stay in sync.
- **Limited APIs.** You can't access the file system, network, or UI. You only get game-related functions.
- **Runs in "synced gadgets."**

**Why does this matter?** Because in multiplayer, all players need to see the same game state. If your AI could access the file system or network, it could cheat. By restricting synced code to deterministic game logic, the engine ensures fairness.

### Unsynced Code (Widgets, UI, Visualization)

**Unsynced code** runs only on your local client. It's for UI, rendering, and client-specific logic.

- **Each player can see different things.** Your UI might show different info than your opponent's.
- **Full access to Lua.** File I/O, networking, debugging—all available.
- **Not authoritative.** Unsynced code can't affect the game state directly.

**For your AI:** You only care about synced code. Your AI module runs in a synced gadget.

## The Game Loop

Every frame (30 times per second by default), the engine:

1. Processes input and network messages
2. Updates physics and unit positions
3. **Calls your AI's `Update(frame)` function** (if you've implemented it)
4. Renders the screen

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

You also have access to:

- **`UnitDefs`**: A table of all unit definitions (what units can do, their costs, etc.)
- **`FeatureDefs`**: A table of all feature definitions (rocks, trees, wrecks, etc.)
- **`CMD`**: A table of command constants (MOVE, FIGHT, BUILD, etc.)
- **`Game`**: Global game info (map name, size, wind, tidal, etc.)

## Why This Matters

Understanding synced vs. unsynced helps you:

- Know what APIs are available to you (no file I/O, no networking)
- Understand why your AI runs the same way on all clients
- Debug issues (if your AI does something weird, it's deterministic—it'll do it the same way every time)

Understanding the game loop helps you:

- Know when your code runs and how often
- Throttle decisions (don't make a decision every frame; that's wasteful)
- Coordinate multi-unit tactics (all your decisions happen in the same frame)

## Next Steps

Now that you understand the basics, move to **02_first_ai.md** to write your first working AI.
