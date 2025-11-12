# Working with UnitDefs in BAR

`UnitDefs[unitDefID]` describes a unit/building. Useful fields:

- name: string (e.g., "armcom")
- isBuilding: bool
- isFactory: bool
- canMove: bool
- buildOptions: {unitDefID,...}
- weapons: array of { weaponDef = wdid }
- customParams: table (game-specific flags; e.g., `iscommander`, `metal_extractor`, `solar`)
- extractsMetal, windGenerator, tidalGenerator, energyMake
- xsize, zsize: footprint in map squares (×8 elmos)

## Discovering options

- From a factory or builder: iterate `buildOptions` to see what it can produce.
- For human-readable names, use `UnitDefs[id].name` or map to BAR’s internal aliasing.

## Quick exploration snippets

```lua
-- print your team’s unit defs once
for _, u in ipairs(Spring.GetTeamUnits(myTeam)) do
  local udid = Spring.GetUnitDefID(u)
  Spring.Echo("unit:", u, udid, UnitDefs[udid] and UnitDefs[udid].name)
end

-- list build options of a factory/builder
local opts = UnitDefs[udid].buildOptions
for i=1,#opts do Spring.Echo("can build:", opts[i], UnitDefs[opts[i]].name) end
```

## Costs and categories

```lua
local u = UnitDefs[udid]
local metalCost, energyCost = u.metalCost, u.energyCost
local isTurret = u.isBuilding and #u.weapons > 0
```

See also:
- `luarules/gadgets/ai_simpleai.lua` for practical patterns.
- `ai/comp/reference_spring.md` for common engine APIs.
