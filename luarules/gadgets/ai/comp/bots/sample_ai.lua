-- Simple example AI module for BAR Dev
local M = {}
local myTeam
local myUnits = {}

function M.Init(teamID)
    myTeam = teamID
    Spring.Echo("[sample_ai] Init for team", teamID)
    -- capture already existing units (e.g., commander at start)
    local units = Spring.GetTeamUnits(teamID) or {}
    for i = 1, #units do
        myUnits[units[i]] = true
    end
end

function M.UnitCreated(unitID, unitDefID, teamID)
    if teamID == myTeam then myUnits[unitID] = true end
end

function M.UnitFinished(unitID, unitDefID, teamID)
    if teamID == myTeam then myUnits[unitID] = true end
end

function M.UnitDestroyed(unitID)
    myUnits[unitID] = nil
end

function M.Update(frame)
    if frame % 60 == 0 then
        if frame % 600 == 0 then
            Spring.Echo("[sample_ai] heartbeat team", myTeam, "units=", (function() local c=0 for _ in pairs(myUnits) do c=c+1 end return c end)())
        end
        local sx, _, sz = Spring.GetTeamStartPosition(myTeam)
        for unitID in pairs(myUnits) do
            local udid = Spring.GetUnitDefID(unitID)
            local ud = udid and UnitDefs[udid]
            if ud and ud.canMove then
                -- try to fight nearest visible enemy, else patrol near start
                local enemy = Spring.GetUnitNearestEnemy(unitID, 1200, true)
                if enemy then
                    Spring.GiveOrderToUnit(unitID, CMD.FIGHT, {Spring.GetUnitPosition(enemy)}, {})
                elseif sx then
                    Spring.GiveOrderToUnit(unitID, CMD.FIGHT, {sx + math.random(-300,300), 0, sz + math.random(-300,300)}, {})
                end
            end
        end
    end
end

return M
