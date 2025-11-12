-- Hive: per-team manager wiring controllers and services with configurable unit-type state machines
local M = {}

local P = VFS.Include("luarules/gadgets/ai/comp/lib/predicates.lua")
local scenarioUtils = VFS.Include("luarules/gadgets/ai/comp/lib/scenario_utils.lua")
local BU = VFS.Include("luarules/gadgets/ai/comp/lib/build_utils.lua")

local BuildTracker = VFS.Include("luarules/gadgets/ai/comp/bots/hive/services/build_tracker.lua")

local teams = {}

local function newTeam(teamID)
    return {
        teamID = teamID,
        controllers = {}, -- unitID -> controller
        services = {
            buildTracker = BuildTracker.new(),
            scenarioUtils = scenarioUtils,
            BU = BU,
            P = P,
        },
        updateStride = 6,
        config = nil,
    }
end

local function ensureTeam(teamID)
    local t = teams[teamID]
    if not t then
        t = newTeam(teamID)
        teams[teamID] = t
    end
    return t
end

-- API
-- config.types is a table mapping logical unit types (e.g., 'commander') to controller factories
-- A factory is a table with .new(teamID, unitID, services)
function M.Init(teamID, config)
    local t = ensureTeam(teamID)
    t.config = config or t.config
end

function M.Ready(teamID)
    -- no-op for now; teams created in Init
end

function M.UnitCreated(unitID, unitDefID, teamID)
    local t = ensureTeam(teamID)
    local ud = UnitDefs[unitDefID]
    if not t.controllers[unitID] and t.config and t.config.types then
        -- commander routing example
        if ud and ud.customParams and ud.customParams.iscommander then
            local factory = t.config.types.commander
            if factory and factory.new then
                t.controllers[unitID] = factory.new(teamID, unitID, t.services)
            end
        end
        -- other unit types can be added here in the future
    end
    -- allow services to observe
    t.services.buildTracker:UnitCreated(unitID, unitDefID, teamID)
end

function M.UnitFinished(unitID, unitDefID, teamID)
    local t = teams[teamID]
    if not t then return end
    local c = t.controllers[unitID]
    if c and c.onUnitFinished then c:onUnitFinished(unitID, unitDefID, teamID) end
    t.services.buildTracker:UnitFinished(unitID, unitDefID, teamID)
end

function M.UnitDestroyed(unitID, unitDefID, teamID)
    local t = teams[teamID]
    if not t then return end
    local c = t.controllers[unitID]
    if c and c.onUnitDestroyed then c:onUnitDestroyed(unitID) end
    t.controllers[unitID] = nil
    t.services.buildTracker:UnitDestroyed(unitID, unitDefID, teamID)
end

function M.Update(frame)
    for _, t in pairs(teams) do
        -- tick services first
        if t.services.buildTracker.update then t.services.buildTracker:update(frame) end
        -- tick controllers (sparse cadence)
        if frame % t.updateStride == 0 then
            for unitID, ctrl in pairs(t.controllers) do
                if ctrl.tick then ctrl:tick(frame) end
            end
        end
    end
end

return M
