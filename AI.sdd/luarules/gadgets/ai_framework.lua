Spring.Echo("[AIComp] AI Framework loading...")

function gadget:GetInfo()
    return {
        name = "AIComp Framework",
        desc = "Loads participant AIs from luarules/gadgets/ai and forwards game events",
        author = "Cascade",
        date = "2025-11-11",
        license = "MIT",
        layer = 1000,
        enabled = true,
    }
end

if not gadgetHandler:IsSyncedCode() then
    Spring.Echo("[AIComp] AI Framework unsynced code - disabled")
    return
end

local aiModules = {}
local readyTeams = {}

local function SafeCall(mod, fname, ...)
    local f = mod and mod[fname]
    if type(f) == "function" then
        local ok, err = pcall(f, ...)
        if not ok then
            Spring.Echo("[AIComp] Error in " .. tostring(fname) .. ": " .. tostring(err))
        end
    end
end

local function LoadAIForTeam(teamID, aiName)
    local path = "luarules/gadgets/ai/comp/bots/" .. aiName .. ".lua"
    if not VFS.FileExists(path) then
        Spring.Echo("[AIComp] AI file not found for team " .. teamID .. " at " .. path)
        return
    end
    local chunk, err = VFS.LoadFile(path)
    if not chunk then
        Spring.Echo("[AIComp] Failed to load " .. path .. ": " .. tostring(err))
        return
    end
    local env = {
        Spring = Spring,
        Game = Game,
        CMD = CMD,
        GG = GG,
        math = math,
        table = table,
        pairs = pairs,
        ipairs = ipairs,
        tostring = tostring,
        tonumber = tonumber,
        next = next,
        type = type,
        setmetatable = setmetatable,
        getmetatable = getmetatable,
        select = select,
    }
    setmetatable(env, { __index = _G })

    local fn, loadErr = loadstring(chunk, path)
    if not fn then
        Spring.Echo("[AIComp] Compile error in " .. path .. ": " .. tostring(loadErr))
        return
    end
    setfenv(fn, env)
    local ok, ret = pcall(fn)
    if not ok then
        Spring.Echo("[AIComp] Runtime error evaluating " .. path .. ": " .. tostring(ret))
        return
    end

    aiModules[teamID] = ret or env
    if aiModules[teamID] and type(aiModules[teamID].Init) == 'function' then
        SafeCall(aiModules[teamID], 'Init', teamID)
    end
    Spring.Echo("[AIComp] Loaded AI '" .. aiName .. "' for team " .. teamID)
end

-- Helper to load all selected AIs (used on GameStart and after /luarules reload)
local function LoadAllSelectedAIs()
    for _, teamID in ipairs(Spring.GetTeamList()) do
        local _, _, _, isAI = Spring.GetTeamInfo(teamID)
        if isAI and not aiModules[teamID] then
            local aiName = Spring.GetTeamLuaAI(teamID)
            if aiName and aiName ~= "" then
                local aiPath = "luarules/gadgets/ai/comp/bots/" .. aiName .. ".lua"
                if VFS.FileExists(aiPath) then
                    LoadAIForTeam(teamID, aiName)
                end
            end
        end
    end
end

function gadget:Initialize()
    -- Called on gadget load and on /luarules reload
    LoadAllSelectedAIs()
end

function gadget:GameStart()
    LoadAllSelectedAIs()
end

function gadget:GameFrame(f)
    -- Lazy load in case teams were added or we reloaded after start
    if f % 30 == 0 then
        LoadAllSelectedAIs()
    end
    for teamID, mod in pairs(aiModules) do
        -- Wait for scenario readiness before updating bots; also skip frame 1 to avoid ordering races
        if GG and GG.scenarioReady and f > 1 then
            if not readyTeams[teamID] then
                readyTeams[teamID] = true
                if mod.Ready then SafeCall(mod, 'Ready', teamID) end
            end
            if mod.Update then
                SafeCall(mod, 'Update', f)
            end
        end
    end
end

function gadget:UnitCreated(unitID, unitDefID, teamID)
    local mod = aiModules[teamID]
    if mod and mod.UnitCreated then SafeCall(mod, 'UnitCreated', unitID, unitDefID, teamID) end
end

function gadget:UnitFinished(unitID, unitDefID, teamID)
    local mod = aiModules[teamID]
    if mod and mod.UnitFinished then SafeCall(mod, 'UnitFinished', unitID, unitDefID, teamID) end
end

function gadget:UnitDestroyed(unitID, unitDefID, teamID, attackerID, attackerDefID, attackerTeam)
    local mod = aiModules[teamID]
    if mod and mod.UnitDestroyed then
        SafeCall(mod, 'UnitDestroyed', unitID, unitDefID, teamID, attackerID, attackerDefID,
            attackerTeam)
    end
end

function gadget:TeamDied(teamID)
    local mod = aiModules[teamID]
    if mod and mod.TeamDied then SafeCall(mod, 'TeamDied', teamID) end
end
