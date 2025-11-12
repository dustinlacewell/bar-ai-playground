# BAR Dev AI Guide (Lua)

This guide explains the basics of writing a simple Lua AI module for Beyond All Reason (Recoil engine) using the file-based loader we added.

- Place your bot here:
  - `luarules/gadgets/ai/comp/bots/<your_bot>.lua`
- Select it in Skirmish as `Dev AI: <your_bot>`.
- Hot-reload code during a match with `/luarules reload`.

Your bot returns a table with optional hooks that the framework forwards:

```lua
-- minimal bot
local M = {}
function M.Init(teamID) end
function M.Update(frame) end
function M.UnitCreated(unitID, unitDefID, teamID) end
function M.UnitFinished(unitID, unitDefID, teamID) end
function M.UnitDestroyed(unitID, unitDefID, teamID) end
return M
```

## 1) Getting your commander and units at start

```lua
local myTeam
local myUnits = {}

function M.Init(teamID)
  myTeam = teamID
  -- capture existing units (e.g., commander)
  local units = Spring.GetTeamUnits(teamID) or {}
  for i = 1, #units do
    myUnits[units[i]] = true
  end
end

function M.UnitFinished(unitID, unitDefID, teamID)
  if teamID == myTeam then myUnits[unitID] = true end
end

function M.UnitDestroyed(unitID)
  myUnits[unitID] = nil
end
```

To find which unit is your commander:

```lua
local function isCommander(unitDefID)
  local ud = UnitDefs[unitDefID]
  return ud and ud.customParams and ud.customParams.iscommander
end
```

## 2) Reading resources (metal/energy)

```lua
local function getResources()
  local mCur, mStor = Spring.GetTeamResources(myTeam, "metal")
  local eCur, eStor = Spring.GetTeamResources(myTeam, "energy")
  return mCur or 0, mStor or 0, eCur or 0, eStor or 0
end
```

## 3) Understanding units and buildings

You can query any UnitDef through `UnitDefs[unitDefID]`:

```lua
local function isFactory(unitDefID)
  local ud = UnitDefs[unitDefID]
  return ud and ud.isFactory and #ud.buildOptions > 0
end

local function isBuilder(unitDefID)
  local ud = UnitDefs[unitDefID]
  return ud and ud.canMove and ud.isBuilder and #ud.buildOptions > 0
end

local function isBuilding(unitDefID)
  local ud = UnitDefs[unitDefID]
  return ud and ud.isBuilding
end
```

To inspect what a factory can build:

```lua
local function factoryBuildOptions(unitDefID)
  local ud = UnitDefs[unitDefID]
  local options = {}
  if ud and ud.buildOptions then
    for i = 1, #ud.buildOptions do
      local builtDefID = ud.buildOptions[i]
      options[#options+1] = builtDefID
      -- name: UnitDefs[builtDefID].name
    end
  end
  return options
end
```

## 4) Inspecting the environment

Team info and start position:

```lua
local function getStartPos(teamID)
  local x, y, z = Spring.GetTeamStartPosition(teamID)
  return x, y, z
end

local function nearestEnemyVisible(unitID, radius)
  return Spring.GetUnitNearestEnemy(unitID, radius or 1200, true)
end
```

Terrain queries:

```lua
local h = Spring.GetGroundHeight(x, z)
local _,_, hasMetal = Spring.GetGroundInfo(x, z)
```

Features (rocks/trees/wrecks) and reclaim:

```lua
-- scan a rectangle (x1,z1,x2,z2)
for _, featID in ipairs(Spring.GetFeaturesInRectangle(x1, z1, x2, z2) or {}) do
  local defID = Spring.GetFeatureDefID(featID)
  local fd = defID and FeatureDefs[defID]
  if fd then
    -- reclaim amounts (from def)
    local m = fd.metal or 0
    local e = fd.energy or 0
    -- or dynamic:
    local dm, de, reclaimed = Spring.GetFeatureResources(featID)
    local fx, fy, fz = Spring.GetFeaturePosition(featID)
    -- filter by fd.destructable, fd.reclaimable, fd.name/category
  end
end
```

## 5) Giving orders

Common commands come from `CMD`:

- Move/Fight: `CMD.MOVE`, `CMD.FIGHT`
- Build: negative unitDefID (e.g., `Spring.GiveOrderToUnit(builderID, -builtDefID, {x,y,z,facing}, opts)`)  
- Stop/Attack/Reclaim/Repair: `CMD.STOP`, `CMD.ATTACK`, `CMD.RECLAIM`, `CMD.REPAIR`

Examples:

```lua
-- Move or fight
Spring.GiveOrderToUnit(unitID, CMD.FIGHT, {tx, 0, tz}, {})

-- Place a building near a reference point
local function tryBuild(builderID, builtDefID, rx, ry, rz)
  local facing = 0
  local ok = Spring.TestBuildOrder(builtDefID, rx, ry, rz, facing)
  if ok == 2 then
    Spring.GiveOrderToUnit(builderID, -builtDefID, {rx, ry, rz, facing}, {})
    return true
  end
end
```

About `Spring.TestBuildOrder`:

- Returns 0 = invalid, 1 = buildable but blocked/iffy, 2 = fully OK (use 2).
- Respect unit footprints: buildings use `UnitDefs[id].xsize/zsize` tiles (×8 elmos per tile).
- Check spacing around structures to avoid overlap; you can search offsets around a reference.
- `facing` is 0..3 (South, East, North, West). Some structures care about facing on slopes/coasts.

## 6) Basic loop (decision making)

Tick at a regular cadence (e.g., every 60 frames ~ 2/sec):

```lua
function M.Update(frame)
  if frame % 60 ~= 0 then return end

  local sx, _, sz = Spring.GetTeamStartPosition(myTeam)
  for unitID in pairs(myUnits) do
    local udid = Spring.GetUnitDefID(unitID)
    local ud = udid and UnitDefs[udid]
    if ud then
      if isBuilder(udid) then
        -- example: ensure we have a factory or mex
        local mCur, mStor, eCur, eStor = getResources()
        -- pick something reasonable to build
        -- tryBuild(unitID, someBuiltDefID, sx+128, 0, sz)
      elseif not ud.isBuilding and ud.canMove then
        -- example: fight toward nearest enemy or patrol
        local enemy = Spring.GetUnitNearestEnemy(unitID, 1200, true)
        if enemy then
          local ex, ey, ez = Spring.GetUnitPosition(enemy)
          if ex then Spring.GiveOrderToUnit(unitID, CMD.FIGHT, {ex, ey or 0, ez}, {}) end
        elseif sx then
          Spring.GiveOrderToUnit(unitID, CMD.FIGHT, {sx + math.random(-300,300), 0, sz + math.random(-300,300)}, {})
        end
      end
    end
  end
end
```

## 7) Finding unitDefIDs to build

- Use any existing unit in game to discover its `unitDefID`: `Spring.GetUnitDefID(unitID)`.
- From that `unitDefID`, explore `UnitDefs[unitDefID]` fields (names, buildOptions, costs, categories).
- Look at existing BAR logic for examples:
  - `luarules/gadgets/ai_simpleai.lua` shows how SimpleAI selects constructions and issues orders.
  - `luarules/gadgets/AILoader.lua` (Shard/STAI) shows an object-style AI with many callins and helpers.

Predicates library: consider sharing helpers under `luarules/gadgets/ai/comp/lib/predicates.lua` (see stub in this folder). Example functions: `isCommander`, `isFactory`, `isBuilder`, `isMobile`, `isCombatUnit`.

## 8) Debugging and logs

- In match:
  - `/luarules reload` to hot-reload synced gadgets (our framework rebinds your bot).
  - Add `Spring.Echo("tag", values...)` for debug; messages go to in-game console and `<install>/data/infolog.txt`.
- Bind a hotkey:
  - `/bind ctrl+shift+r luarules reload`

## 9) Tips

- Use `FIGHT` instead of `MOVE` for roaming combat units.
- Track units via `UnitFinished` and initial capture in `Init` so you include the commander.
- Be careful with order spam; throttle in `Update`, and avoid resetting timers (e.g., self-destruct).
- For building placement: test with `Spring.TestBuildOrder` and keep spacing around existing structures.

## 10) Where to put your bot

- Code: `luarules/gadgets/ai/comp/bots/<your_bot>.lua`
- Select in Skirmish: `Dev AI: <your_bot>`
- Hot reload during a match: `/luarules reload`

That’s enough to start: get a commander, read resources, inspect `UnitDefs`, scan the world, and issue basic build/attack orders. Iterate quickly with hot-reload and inspect SimpleAI for practical patterns.

## 11) Shared tables GG/WG

- `GG` is a global table shared among synced gadgets. Gadgets register utilities/data on it (e.g., `GG.resource_spot_finder`).
- `WG` is the unsynced analogue for widgets. Do not write unsynced state into `GG`.
- Use presence checks (e.g., `if GG and GG.some_tool then ... end`).

## 12) Command reference and Spring API

- See `ai/comp/commands.md` for common CMD constants and patterns.
- See `ai/comp/reference_spring.md` for a quick reference of frequently used Spring functions grouped by domain (Units, Teams, Resources, Features, Map).
