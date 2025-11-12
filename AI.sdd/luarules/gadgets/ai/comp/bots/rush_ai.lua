local M = {}
local myTeam
local myUnits = {}
local scenarioUtils = VFS.Include("luarules/gadgets/ai/comp/lib/scenario_utils.lua")

function M.Init(teamID)
    myTeam = teamID
    Spring.Echo("[rush_ai] Init for team", teamID)
    local units = Spring.GetTeamUnits(teamID) or {}
    for i = 1, #units do
        myUnits[units[i]] = true
    end
end

function M.UnitCreated(unitID, unitDefID, teamID)
    if teamID == myTeam then
        myUnits[unitID] = true
    end
end

function M.UnitFinished(unitID, unitDefID, teamID)
    if teamID == myTeam then
        myUnits[unitID] = true
    end
end

function M.UnitDestroyed(unitID)
    myUnits[unitID] = nil
end

function M.Update(frame)
    if frame % 90 == 0 then
        -- Get nearest enemy start position from scenario
        local myX, _, myZ = scenarioUtils.GetTeamStartPosition(myTeam)
        local target = scenarioUtils.GetNearestEnemyStartPosition(myTeam, myX, myZ)
        
        if target then
            -- Rush all mobile units to enemy start position
            for unitID in pairs(myUnits) do
                local unitDefID = Spring.GetUnitDefID(unitID)
                local unitDef = unitDefID and UnitDefs[unitDefID]
                
                if unitDef and unitDef.canMove then
                    Spring.GiveOrderToUnit(unitID, CMD.FIGHT, {target.x, 0, target.z}, {})
                end
            end
        end
    end
end

return M
