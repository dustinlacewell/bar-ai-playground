# UnitDefs Reference

Understanding unit definitions is key to writing effective AIs.

## What is a UnitDef?

A UnitDef is a table containing all metadata about a unit type. You access it via:

```lua
local unitDef = UnitDefs[unitDefID]
```

Every unit in the game has a unique `unitDefID`. You get it from a unit instance:

```lua
local unitDefID = Spring.GetUnitDefID(unitID)
```

## Common Fields

### Basic Info

```lua
unitDef.name              -- String name (e.g., "armcom", "armflea")
unitDef.humanName         -- Human-readable name
unitDef.description       -- Description text
unitDef.side              -- Faction (e.g., "ARM", "CORE")
```

### Movement

```lua
unitDef.canMove           -- Boolean: can this unit move?
unitDef.maxVelocity       -- Max speed in elmos/frame
unitDef.acceleration      -- Acceleration
unitDef.brakeRate         -- Brake rate
unitDef.turnRate          -- Turn rate
```

### Building

```lua
unitDef.isBuilding        -- Boolean: is this a building?
unitDef.isFactory         -- Boolean: can it build units?
unitDef.isBuilder         -- Boolean: can it build structures?
unitDef.buildOptions      -- Table of unitDefIDs it can build
unitDef.buildTime         -- Time to build this unit (frames)
unitDef.buildCostMetal    -- Metal cost (same as metalCost)
unitDef.buildCostEnergy   -- Energy cost (same as energyCost)
```

### Costs

```lua
unitDef.metalCost         -- Metal required to build
unitDef.energyCost        -- Energy required to build
unitDef.metalUpkeep        -- Metal per frame to maintain
unitDef.energyUpkeep       -- Energy per frame to maintain
```

### Footprint

```lua
unitDef.xsize             -- Width in map squares (×8 = elmos)
unitDef.zsize             -- Depth in map squares (×8 = elmos)
unitDef.footprintX        -- Same as xsize
unitDef.footprintZ        -- Same as zsize
```

### Combat

```lua
unitDef.health            -- Max health
unitDef.armor             -- Armor value
unitDef.weapons           -- Table of weapons
unitDef.canAttack         -- Boolean: can attack?
unitDef.canFly            -- Boolean: can fly?
unitDef.canHover          -- Boolean: can hover?
unitDef.canSubmerge       -- Boolean: can go underwater?
```

### Resources

```lua
unitDef.extractsMetal     -- Boolean: extracts metal?
unitDef.windGenerator     -- Boolean: generates wind power?
unitDef.tidalGenerator    -- Boolean: generates tidal power?
unitDef.energyMake        -- Energy production per frame
unitDef.metalMake         -- Metal production per frame
unitDef.metalStorage      -- Metal storage capacity
unitDef.energyStorage     -- Energy storage capacity
```

### Special

```lua
unitDef.customParams      -- Table of custom game-specific flags
unitDef.transportCapacity -- How many units can it carry?
unitDef.transportSize     -- Size of units it can carry
unitDef.isTransport       -- Boolean: is this a transport?
unitDef.isAirBase         -- Boolean: is this an air base?
unitDef.radarRadius       -- Radar range (if any)
unitDef.sonarRadius       -- Sonar range (if any)
```

## Custom Parameters

The `customParams` table contains game-specific flags:

```lua
local cp = unitDef.customParams or {}

-- Common flags
cp.iscommander            -- Boolean: is this a commander?
cp.metal_extractor        -- Boolean: extracts metal?
cp.solar                  -- Boolean: solar panel?
cp.wind                   -- Boolean: wind turbine?
cp.tidal                  -- Boolean: tidal generator?
cp.energyStorage          -- Energy storage amount
cp.metalStorage           -- Metal storage amount
```

## Practical Examples

### Find a Metal Extractor

```lua
local function findMetalExtractorDefID()
    for defID, ud in pairs(UnitDefs) do
        if ud.customParams and ud.customParams.metal_extractor then
            return defID
        end
    end
    return nil
end
```

### Find a Power Plant

```lua
local function findPowerPlantDefID()
    for defID, ud in pairs(UnitDefs) do
        local cp = ud.customParams or {}
        if cp.solar or cp.wind or cp.tidal then
            return defID
        end
    end
    return nil
end
```

### Find a Factory

```lua
local function findFactoryDefID()
    for defID, ud in pairs(UnitDefs) do
        if ud.isFactory and #ud.buildOptions > 0 then
            return defID
        end
    end
    return nil
end
```

### Find the Commander

```lua
local function findCommanderDefID()
    for defID, ud in pairs(UnitDefs) do
        if ud.customParams and ud.customParams.iscommander then
            return defID
        end
    end
    return nil
end
```

### Check What a Factory Can Build

```lua
local function getFactoryBuildOptions(factoryDefID)
    local ud = UnitDefs[factoryDefID]
    if not ud or not ud.buildOptions then return {} end
    
    local options = {}
    for _, builtDefID in ipairs(ud.buildOptions) do
        local builtUD = UnitDefs[builtDefID]
        if builtUD then
            table.insert(options, {
                defID = builtDefID,
                name = builtUD.name,
                cost = builtUD.metalCost,
                time = builtUD.buildTime
            })
        end
    end
    
    return options
end
```

### Categorize Units

```lua
local function categorizeUnitDef(unitDefID)
    local ud = UnitDefs[unitDefID]
    if not ud then return "unknown" end
    
    if ud.customParams and ud.customParams.iscommander then
        return "commander"
    elseif ud.isFactory then
        return "factory"
    elseif ud.isBuilder then
        return "builder"
    elseif ud.isBuilding then
        return "building"
    elseif ud.canMove and #(ud.weapons or {}) > 0 then
        return "combat"
    elseif ud.canMove then
        return "mobile"
    else
        return "other"
    end
end
```

### Find Cheapest Combat Unit

```lua
local function findCheapestCombatUnit(factoryDefID)
    local ud = UnitDefs[factoryDefID]
    if not ud or not ud.buildOptions then return nil end
    
    local cheapest = nil
    local cheapestCost = math.huge
    
    for _, builtDefID in ipairs(ud.buildOptions) do
        local builtUD = UnitDefs[builtDefID]
        if builtUD and #(builtUD.weapons or {}) > 0 then
            if builtUD.metalCost < cheapestCost then
                cheapest = builtDefID
                cheapestCost = builtUD.metalCost
            end
        end
    end
    
    return cheapest
end
```

## Performance Tips

### Cache UnitDefs Lookups

```lua
-- BAD: Looks up UnitDefs every time
for unitID in pairs(myUnits) do
    if UnitDefs[Spring.GetUnitDefID(unitID)].canMove then
        -- ...
    end
end

-- GOOD: Cache the lookup
for unitID in pairs(myUnits) do
    local unitDefID = Spring.GetUnitDefID(unitID)
    local ud = UnitDefs[unitDefID]
    if ud and ud.canMove then
        -- ...
    end
end
```

### Iterate UnitDefs Once at Init

```lua
local M = {}
local metalExtractorDefID
local powerPlantDefID
local factoryDefID

function M.Init(teamID)
    -- Find important unit types once
    for defID, ud in pairs(UnitDefs) do
        if not metalExtractorDefID and ud.customParams and ud.customParams.metal_extractor then
            metalExtractorDefID = defID
        end
        if not powerPlantDefID then
            local cp = ud.customParams or {}
            if cp.solar or cp.wind or cp.tidal then
                powerPlantDefID = defID
            end
        end
        if not factoryDefID and ud.isFactory then
            factoryDefID = defID
        end
    end
end

function M.Update(frame)
    -- Use cached values
    if metalExtractorDefID then
        -- Build metal extractors
    end
end

return M
```

This avoids iterating `UnitDefs` every frame.
