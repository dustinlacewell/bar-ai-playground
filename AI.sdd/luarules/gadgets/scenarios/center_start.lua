-- Default Scenario: Commander vs Commander
-- Both commanders start near the center of the map, close to each other
local projectileUtils = VFS.Include("luarules/gadgets/ai/comp/lib/projectile_utils.lua")

local function GetTeamStartPositions()
    local mapWidth = Game.mapSizeX
    local mapHeight = Game.mapSizeZ
    
    -- Center of map
    local centerX = mapWidth / 2
    local centerZ = mapHeight / 2
    
    -- Offset commanders slightly from center (so they're close but not on top of each other)
    local spacing = 300
    
    return {
        -- Team 0: Slightly southwest of center
        {x = centerX - spacing, z = centerZ - spacing},
        -- Team 1: Slightly northeast of center
        {x = centerX + spacing, z = centerZ + spacing}
    }
end

local function SendNukes(frame)
    -- Spawn a nuke projectile flying from off-map to center
    local centerX = Game.mapSizeX / 2
    local centerZ = Game.mapSizeZ / 2

    projectileUtils.SpawnNukeFromAbove(centerX, centerZ, -1, { altitude = 5000, ttl = 300 })
    projectileUtils.SpawnNukeFromAbove(centerX + 100, centerZ, -1, { altitude = 5000, ttl = 300 })
    projectileUtils.SpawnNukeFromAbove(centerX + 200, centerZ, -1, { altitude = 5000, ttl = 300 })
end

return {
    name = "Commander vs Commander",
    description = "Both commanders start near map center for quick combat",
    
    -- events = {
    --     {
    --         frame = 900 / 3,  -- 30 seconds
    --         action = SendNukes
    --     }
    -- },
    
    teams = {
        {
            startX = GetTeamStartPositions()[1].x,
            startZ = GetTeamStartPositions()[1].z,
            units = {
                {
                    defName = "armmex",
                    x = 100,
                    z = 100,
                    facing = 0
                },
                {
                    defName = "armsolar",
                    x = -100,
                    z = 100,
                    facing = 0
                },
                {
                    defName = "armlab",
                    x = 200,
                    z = -100,
                    facing = 0
                }
            }
        },
        {
            startX = GetTeamStartPositions()[2].x,
            startZ = GetTeamStartPositions()[2].z,
            units = {
                {
                    defName = "armmex",
                    x = -100,
                    z = -100,
                    facing = 0
                },
                {
                    defName = "armsolar",
                    x = 100,
                    z = -100,
                    facing = 0
                },
                {
                    defName = "armlab",
                    x = -200,
                    z = 100,
                    facing = 0
                }
            }
        }
    }
}
