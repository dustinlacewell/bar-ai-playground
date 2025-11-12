-- Scenario Utilities
-- Helper functions for AIs to query scenario-defined start positions

local M = {}

-- Get the start position for a team (from the scenario)
-- Returns {x, y, z} or nil if not available
function M.GetTeamStartPosition(teamID)
    if GG.scenarioStartPositions and GG.scenarioStartPositions[teamID] then
        local pos = GG.scenarioStartPositions[teamID]
        return pos.x, pos.y, pos.z
    end
    
    -- Fallback to Spring's default if scenario position not available
    return Spring.GetTeamStartPosition(teamID)
end

-- Get all enemy team start positions
-- Returns table of {teamID, x, y, z} for all enemy teams
function M.GetEnemyStartPositions(myTeamID)
    local enemies = {}
    local teamList = Spring.GetTeamList()
    
    for _, teamID in ipairs(teamList) do
        if teamID ~= myTeamID then
            local _, _, _, isAI, _, allyTeamID = Spring.GetTeamInfo(teamID, false)
            local myAllyTeam = select(6, Spring.GetTeamInfo(myTeamID, false))
            
            -- Only include enemy teams (different ally team)
            if allyTeamID ~= myAllyTeam then
                local x, y, z = M.GetTeamStartPosition(teamID)
                if x then
                    table.insert(enemies, {teamID = teamID, x = x, y = y, z = z})
                end
            end
        end
    end
    
    return enemies
end

-- Get the nearest enemy start position
-- Returns {teamID, x, y, z, distance} or nil
function M.GetNearestEnemyStartPosition(myTeamID, myX, myZ)
    local enemies = M.GetEnemyStartPositions(myTeamID)
    local nearest = nil
    local minDist = math.huge
    
    for _, enemy in ipairs(enemies) do
        local dx = enemy.x - myX
        local dz = enemy.z - myZ
        local dist = dx * dx + dz * dz
        
        if dist < minDist then
            minDist = dist
            nearest = {
                teamID = enemy.teamID,
                x = enemy.x,
                y = enemy.y,
                z = enemy.z,
                distance = math.sqrt(dist)
            }
        end
    end
    
    return nearest
end

return M
