-- Commander Duel AI using state machine
local M = {}
local hive = VFS.Include("luarules/gadgets/ai/comp/bots/hive/init.lua")
local duelistConfig = VFS.Include("luarules/gadgets/ai/comp/bots/duelist/init.lua")

function M.Init(teamID)
    hive.Init(teamID, duelistConfig)
end

function M.Ready(teamID)
    hive.Ready(teamID)
end

function M.UnitCreated(unitID, unitDefID, teamID)
    hive.UnitCreated(unitID, unitDefID, teamID)
end

function M.UnitFinished(unitID, unitDefID, teamID)
    hive.UnitFinished(unitID, unitDefID, teamID)
end

function M.UnitDestroyed(unitID, unitDefID, teamID)
    hive.UnitDestroyed(unitID, unitDefID, teamID)
end

function M.Update(frame)
    hive.Update(frame)
end

return M
