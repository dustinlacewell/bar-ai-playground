local M = {}
local myTeam
local myUnits = {}
local ordered = {}

function M.Init(teamID)
    myTeam = teamID
    Spring.Echo("[suicide_ai] Init for team", teamID)
    local units = Spring.GetTeamUnits(teamID) or {}
    for i = 1, #units do
        local u = units[i]
        myUnits[u] = true
        M._orderSelfD(u)
    end
end

function M.UnitCreated(unitID, unitDefID, teamID)
    if teamID == myTeam then
        myUnits[unitID] = true
        M._orderSelfD(unitID)
    end
end

function M.UnitFinished(unitID, unitDefID, teamID)
    if teamID == myTeam then
        myUnits[unitID] = true
        M._orderSelfD(unitID)
    end
end

function M.UnitDestroyed(unitID)
    myUnits[unitID] = nil
    ordered[unitID] = nil
end

function M.Update(frame)
    if frame % 30 == 0 then
        for unitID in pairs(myUnits) do
            if not ordered[unitID] then
                M._orderSelfD(unitID)
            end
        end
    end
end

-- internal helpers
function M._selfdQueued(unitID)
    local q = Spring.GetCommandQueue(unitID, 1)
    if q and q[1] and q[1].id == CMD.SELFD then
        return true
    end
    return false
end

function M._orderSelfD(unitID)
    if not unitID then return end
    if M._selfdQueued(unitID) then
        ordered[unitID] = true
        return
    end
    Spring.GiveOrderToUnit(unitID, CMD.SELFD, {}, {})
    ordered[unitID] = true
end

return M
