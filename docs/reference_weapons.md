# Weapons Reference

Weapons in BAR are defined separately from units. They're used by units to deal damage, and can also be spawned directly as projectiles in Lua code.

## Accessing Weapon Data

### WeaponDefs Table

`WeaponDefs` is a global table indexed by weapon ID (a number). It contains all weapon definitions in the game.

```lua
-- Access a weapon by its ID
local weaponDef = WeaponDefs[weaponID]

-- Common fields:
-- weaponDef.name          - weapon name (string)
-- weaponDef.type          - weapon type ("Cannon", "Missile", "Laser", etc.)
-- weaponDef.range         - max range in elmos
-- weaponDef.damage        - base damage value
-- weaponDef.reload        - reload time in seconds
-- weaponDef.stockpile     - can be stockpiled (boolean)
-- weaponDef.paralyzer     - is a stun weapon (boolean)
-- weaponDef.customParams  - custom parameters table
```

### WeaponDefNames Table

`WeaponDefNames` is a lookup table indexed by weapon name (string). Use it to find a weapon by name.

```lua
-- Find a weapon by name
local weaponDef = WeaponDefNames["armcannon"]
if weaponDef then
    local weaponID = weaponDef.id
    local weaponData = WeaponDefs[weaponID]
end
```

## Finding Weapons

### By Unit

Units have weapons defined in their `weapons` array:

```lua
local unitDef = UnitDefs[unitDefID]

if unitDef.weapons then
    for i, weaponData in ipairs(unitDef.weapons) do
        local weaponDefID = weaponData.weaponDef
        local weaponDef = WeaponDefs[weaponDefID]
        
        Spring.Echo("Unit has weapon: " .. weaponDef.name)
        Spring.Echo("  Range: " .. weaponDef.range)
        Spring.Echo("  Damage: " .. weaponDef.damage)
    end
end
```

### By Name Pattern

Search through `WeaponDefNames` to find weapons matching a pattern:

```lua
local function FindWeaponsByPattern(pattern)
    local found = {}
    for weaponName, weaponDef in pairs(WeaponDefNames) do
        if string.find(weaponName, pattern) then
            table.insert(found, {name = weaponName, id = weaponDef.id})
        end
    end
    return found
end

-- Example: find all nuke weapons
local nukes = FindWeaponsByPattern("nuke")
for _, nuke in ipairs(nukes) do
    Spring.Echo("Found nuke: " .. nuke.name)
end
```

### By Faction

Weapons are typically prefixed with faction abbreviations:

- `arm` - ARM faction
- `cor` - CORE faction
- `leg` - Legionnaire faction

```lua
local function FindFactionWeapon(baseName, faction)
    local weaponName = faction .. baseName
    if WeaponDefNames[weaponName] then
        return WeaponDefNames[weaponName].id
    end
    return nil
end

-- Example: find ARM cannon
local armCannonID = FindFactionWeapon("cannon", "arm")
```

## Weapon Types

Common weapon types in BAR:

- **Cannon** - Direct fire ballistic weapon
- **Missile** - Guided or unguided missile
- **Laser** - Beam weapon
- **LightningCannon** - Chain lightning weapon
- **Flame** - Flamethrower
- **Bomb** - Air-dropped ordnance
- **Melee** - Close-range physical attack

Check `weaponDef.type` to identify weapon behavior.

## Special Weapon Properties

### Stockpile Weapons

Some weapons (like nukes) can be stockpiled:

```lua
local weaponDef = WeaponDefs[weaponID]

if weaponDef.stockpile then
    Spring.Echo("This weapon can be stockpiled")
    if weaponDef.customParams and weaponDef.customParams.stockpilelimit then
        local limit = tonumber(weaponDef.customParams.stockpilelimit)
        Spring.Echo("Stockpile limit: " .. limit)
    end
end
```

### Paralyzer Weapons

Stun/paralyze weapons deal paralysis damage instead of health damage:

```lua
if weaponDef.paralyzer then
    Spring.Echo("This is a stun weapon")
    -- Paralyze damage is tracked separately from health
end
```

### Custom Parameters

Weapons can have custom parameters for mod-specific behavior:

```lua
if weaponDef.customParams then
    for key, value in pairs(weaponDef.customParams) do
        Spring.Echo("Custom param: " .. key .. " = " .. tostring(value))
    end
end
```

## Spawning Projectiles

You can spawn weapon projectiles directly using `Spring.SpawnProjectile`:

```lua
local weaponDefID = WeaponDefNames["armnuke"].id

local projectileParams = {
    pos = {x, y, z},           -- spawn position
    speed = {vx, vy, vz},      -- initial velocity
    owner = teamID,            -- team that owns the projectile
    ttl = 300                  -- time to live (optional)
}

local projectileID = Spring.SpawnProjectile(weaponDefID, projectileParams)
if projectileID then
    Spring.Echo("Projectile spawned: " .. projectileID)
end
```

### Example: Spawn a Nuke Projectile in Flight

To spawn a nuke that actually flies through the air (not just appear at a location), you need to:
1. Find the nuke weapon definition
2. Calculate velocity vector for the desired trajectory
3. Spawn with non-zero velocity

```lua
local function SpawnNukeProjectile(targetX, targetZ, teamID)
    -- Find the nuke weapon (cordesolator's crblmssl is the actual nuke missile)
    local nukeWeaponID = nil
    if WeaponDefNames["cordesolator_crblmssl"] then
        nukeWeaponID = WeaponDefNames["cordesolator_crblmssl"].id
    else
        -- Fallback: search for any high-damage StarburstLauncher
        local maxDamage = 0
        for weaponName, weaponDef in pairs(WeaponDefNames) do
            local wDef = WeaponDefs[weaponDef.id]
            if wDef and wDef.weapontype == "StarburstLauncher" then
                local damage = wDef.damage and wDef.damage.default or 0
                if damage > maxDamage then
                    maxDamage = damage
                    nukeWeaponID = weaponDef.id
                end
            end
        end
    end
    
    if not nukeWeaponID then
        return false
    end
    
    -- Spawn point: high above the target
    local startX = targetX
    local startZ = targetZ
    local startY = 5000  -- High altitude
    
    -- Weapon velocity (from weapon definition)
    local wDef = WeaponDefs[nukeWeaponID]
    local weaponSpeed = wDef.weaponvelocity or 1600
    
    -- Velocity: straight down
    local vx = 0
    local vy = -weaponSpeed  -- Negative = downward
    local vz = 0
    
    -- Spawn the projectile
    local projectileParams = {
        pos = {startX, startY, startZ},
        speed = {vx, vy, vz},
        owner = teamID,
        ttl = 300  -- Time to live in frames
    }
    
    return Spring.SpawnProjectile(nukeWeaponID, projectileParams) ~= nil
end

-- Usage: spawn nuke at map center
local mapCenterX = Game.mapSizeX / 2
local mapCenterZ = Game.mapSizeZ / 2
SpawnNukeProjectile(mapCenterX, mapCenterZ, -1)  -- -1 = Gaia (neutral)
```

**Key points:**
- `pos` is the spawn position `{x, y, z}` in elmos
- `speed` is the initial velocity `{vx, vy, vz}` in elmos/frame
- `owner` is the team ID (use `-1` for Gaia/neutral)
- `ttl` is time-to-live in frames (optional)
- Negative `vy` makes the projectile fall downward
- The projectile will follow ballistic physics and gravity

## Weapon Damage

### Direct Damage

Deal damage to a unit using a specific weapon:

```lua
local damage = 100
local weaponDefID = WeaponDefNames["armcannon"].id

Spring.AddUnitDamage(unitID, damage, 0, weaponDefID, attackerID)
```

### Damage Types

Weapons can deal different types of damage:

- **Health damage** - reduces unit health
- **Paralysis damage** - stuns the unit (for paralyzer weapons)
- **Capture damage** - captures enemy units (rare)

## Performance Tips

- Cache weapon lookups instead of searching every frame
- Use `WeaponDefNames` for name-based lookups (faster than iterating `WeaponDefs`)
- Check `weaponDef.range` before calculating if a target is in range
- Weapon data is read-only; don't modify `WeaponDefs` or `WeaponDefNames`

## See Also

- `reference_unitdefs.md` - How units use weapons
- `reference_spring_api.md` - Spring API functions for weapons
- `05_giving_orders.md` - How to command units to fire weapons
