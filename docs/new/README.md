# BAR AI Competitor's Guide

Welcome! This guide teaches you how to write a Lua AI for Beyond All Reason's AI Competition framework.

## What You'll Learn

This guide progresses from **concepts** to **practice** to **advanced patterns**:

1. **Foundations** – What Spring, Lua, and synced code mean
2. **Your First AI** – A minimal working example
3. **Game Loop & Timing** – When your code runs and how to throttle decisions
4. **Reading the Match** – Querying units, resources, and the map
5. **Giving Orders** – Building, moving, fighting, and other commands
6. **Practical Patterns** – Common AI strategies and optimizations

## Quick Start

1. Create a file: `luarules/gadgets/ai/comp/bots/my_ai.lua`
2. Copy the minimal example from **Your First AI**
3. Select "Dev AI: my_ai" in Skirmish
4. Use `/luarules reload` to hot-reload during a match

## File Structure

- **01_foundations.md** – Concepts: Spring, Lua, synced vs. unsynced
- **02_first_ai.md** – Your first working AI
- **03_game_loop.md** – Frames, throttling, timing patterns
- **04_reading_match.md** – Querying units, resources, terrain
- **05_giving_orders.md** – Building, moving, attacking
- **06_practical_patterns.md** – Common strategies and optimizations
- **reference/** – Quick lookup tables

## Key Concepts at a Glance

- **Synced code:** Your AI runs here. Deterministic, all clients see the same thing.
- **Frames:** 30 per second. Throttle decisions (don't decide every frame).
- **UnitDefs:** Metadata about unit types (costs, abilities, build options).
- **Spring API:** Functions to query and control the game.
- **GG table:** Shared utilities from other gadgets.

## Where to Get Help

- Check `infolog.txt` in your BAR installation for error messages
- Use `Spring.Echo(...)` to print debug info
- Look at `luarules/gadgets/ai_simpleai.lua` for practical examples
- Reload with `/luarules reload` to test changes without restarting

## Next Steps

Start with **01_foundations.md** to understand the basics, then move to **02_first_ai.md** to write your first AI.
