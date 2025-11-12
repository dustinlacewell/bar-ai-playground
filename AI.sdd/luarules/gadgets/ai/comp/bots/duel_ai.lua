-- Commander Duel AI using state machine
local M = {}

local myTeam
local myUnits = {}
local commanderID

local smLib = VFS.Include("luarules/gadgets/ai/comp/lib/state_machine.lua")
local P = VFS.Include("luarules/gadgets/ai/comp/lib/predicates.lua")
local scenarioUtils = VFS.Include("luarules/gadgets/ai/comp/lib/scenario_utils.lua")
local BU = VFS.Include("luarules/gadgets/ai/comp/lib/build_utils.lua")

local state
local targetEnemyComID
local enemySpawn
local mySpawn
local HP_MARGIN_FRAC = 0.1
local commanderMaxHP
-- LLT roll controls
-- how often to roll (in frames) and with what probability
local BUILD_ROLL_INTERVAL_FRAMES = 300
local BUILD_ROLL_CHANCE = 0.15
-- Hoisted build-related locals so state methods can reference them safely
local BUILD_WAIT_DURATION = 180
local lastBuildFrame = 0
local buildBusyUntilFrame = 0
local BuildLLT = {}
local prevStateForBuild = nil

-- LLT detection
local LLTDefID
local function detectLLTDefID()
    for defID, ud in pairs(UnitDefs) do
        if ud and ud.isBuilding and ud.weapons and #ud.weapons > 0 then
            local n = (ud.name or ""):lower()
            local hn = (ud.humanName or ""):lower()
            if n:find("llt") or hn:find("light") and hn:find("laser") then
                LLTDefID = defID
                return
            end
        end
    end
end

-- Prefer an LLT that our commander can actually build
local function detectBuildableLLTForCommander()
    if not commanderID then return end
    local cUD = UnitDefs[Spring.GetUnitDefID(commanderID)]
    if not cUD or not cUD.buildOptions then return end
    -- pass 1: look for exact BAR names
    for _, builtDefID in ipairs(cUD.buildOptions) do
        local ud = UnitDefs[builtDefID]
        local n = ud and ud.name and ud.name:lower() or ""
        if n == "armllt" or n == "corllt" then
            LLTDefID = builtDefID
            return
        end
    end
    -- pass 2: heuristic fallback
    for _, builtDefID in ipairs(cUD.buildOptions) do
        local ud = UnitDefs[builtDefID]
        if ud and ud.isBuilding and ud.weapons and #ud.weapons > 0 then
            local n = (ud.name or ""):lower()
            local hn = (ud.humanName or ""):lower()
            if n:find("llt") or (hn:find("light") and hn:find("laser")) then
                LLTDefID = builtDefID
                return
            end
        end
    end
end

local function isUnitAlive(u)
    if not u then return false end
    if not Spring.ValidUnitID(u) then return false end
    if Spring.GetUnitIsDead(u) then return false end
    return true
end

local function findOurCommander()
    -- return first commander unit belonging to myTeam
    for unitID in pairs(myUnits) do
        local udid = Spring.GetUnitDefID(unitID)
        if P.isCommander(udid) then
            return unitID
        end
    end
    return nil
end

function BuildLLT:enter(sm, prev)
    prevStateForBuild = prev or Travel
    local frame = Spring.GetGameFrame() or 0
    if not LLTDefID then
        detectBuildableLLTForCommander()
        if not LLTDefID then detectLLTDefID() end
    end
    if commanderID and LLTDefID then
        local cx, cy, cz = Spring.GetUnitPosition(commanderID)
        local offsets
        if cx then
            local tx, tz
            if isUnitAlive(targetEnemyComID) then
                local ex, ey, ez = Spring.GetUnitPosition(targetEnemyComID)
                tx, tz = ex, ez
            elseif enemySpawn then
                tx, tz = enemySpawn.x, enemySpawn.z
            end
            if tx and tz then
                local dx = tx - cx
                local dz = tz - cz
                local len = math.sqrt(dx*dx + dz*dz)
                if len > 1e-3 then
                    local nx, nz = dx/len, dz/len
                    local px, pz = -nz, nx
                    -- place LLT toward the enemy direction, with slight lateral fallbacks
                    offsets = {
                        { nx*120,  nz*120},
                        { nx*160,  nz*160},
                        { nx*120 + px*80,  nz*120 + pz*80},
                        { nx*120 - px*80,  nz*120 - pz*80},
                    }
                end
            end
        end
        if BU.tryPlaceNear(commanderID, LLTDefID, {offsets = offsets}) then
            lastBuildFrame = frame
            buildBusyUntilFrame = frame + BUILD_WAIT_DURATION
        else
            -- couldn't place now; return to previous state immediately
            sm:setState(prevStateForBuild)
        end
    else
        sm:setState(prevStateForBuild)
    end
end

function BuildLLT:tick(sm)
    local frame = Spring.GetGameFrame() or 0
    if frame >= buildBusyUntilFrame then
        return prevStateForBuild or Travel
    end
    return nil
end

local function refreshCommanderMaxHP()
    if commanderID then
        local ud = UnitDefs[Spring.GetUnitDefID(commanderID)]
        commanderMaxHP = ud and ud.health or commanderMaxHP
    end
end

local function getNearestEnemyCommander(px, pz)
    local bestID, bestDistSq
    local myAllyTeam = select(6, Spring.GetTeamInfo(myTeam, false))
    for _, teamID in ipairs(Spring.GetTeamList()) do
        if teamID ~= myTeam then
            local _, _, _, _, _, allyTeamID = Spring.GetTeamInfo(teamID, false)
            if allyTeamID ~= myAllyTeam then
                local units = Spring.GetTeamUnits(teamID) or {}
                for i = 1, #units do
                    local u = units[i]
                    if isUnitAlive(u) then
                        local udid = Spring.GetUnitDefID(u)
                        if P.isCommander(udid) then
                            local x, y, z = Spring.GetUnitPosition(u)
                            if x and z then
                                local dx = x - px
                                local dz = z - pz
                                local d2 = dx*dx + dz*dz
                                if not bestDistSq or d2 < bestDistSq then
                                    bestDistSq = d2
                                    bestID = u
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return bestID
end

local function vecTowards(fromX, fromZ, toX, toZ, dist)
    local dx = toX - fromX
    local dz = toZ - fromZ
    local len = math.sqrt(dx*dx + dz*dz)
    if len < 0.001 then return fromX, 0, fromZ end
    local nx, nz = dx/len, dz/len
    return fromX + nx*dist, 0, fromZ + nz*dist
end

local function giveMove(unitID, x, z, opts)
    local y = Spring.GetGroundHeight(x, z)
    Spring.GiveOrderToUnit(unitID, CMD.MOVE, {x, y, z}, opts or {})
end

local function giveFight(unitID, x, z, opts)
    local y = Spring.GetGroundHeight(x, z)
    Spring.GiveOrderToUnit(unitID, CMD.FIGHT, {x, y, z}, opts or {})
end

local function giveAttackUnit(unitID, targetID)
    Spring.GiveOrderToUnit(unitID, CMD.ATTACK, {targetID}, {})
end

-- LLT placement now delegated to build_utils.tryPlaceNear with directional offsets

-- States
local Travel = {}
function Travel:enter(sm)
    -- move towards nearest enemy spawn
    local sx, _, sz = scenarioUtils.GetTeamStartPosition(myTeam)
    mySpawn = mySpawn or (sx and {x=sx, z=sz} or nil)
    local myX, _, myZ = Spring.GetUnitPosition(commanderID)
    local target = scenarioUtils.GetNearestEnemyStartPosition(myTeam, myX or 0, myZ or 0)
    enemySpawn = target and {x=target.x, z=target.z} or enemySpawn
end
function Travel:tick(sm)
    if not isUnitAlive(commanderID) then return nil end
    -- periodically refresh target enemy spawn
    if sm.ticksInState % 180 == 1 then
        local myX, _, myZ = Spring.GetUnitPosition(commanderID)
        local target = scenarioUtils.GetNearestEnemyStartPosition(myTeam, myX or 0, myZ or 0)
        enemySpawn = target and {x=target.x, z=target.z} or enemySpawn
    end
    if sm.ticksInState % 30 == 1 then
        -- steer toward enemy commander if we have a fix; else, head to their spawn
        local tx, tz
        if isUnitAlive(targetEnemyComID) then
            local ex, ey, ez = Spring.GetUnitPosition(targetEnemyComID)
            tx, tz = ex, ez
        elseif enemySpawn then
            tx, tz = enemySpawn.x, enemySpawn.z
        end
        if tx and tz then
            giveFight(commanderID, tx, tz, {"shift"})
        end
    end
    -- transition to Engage if we see enemy commander
    local cx, _, cz = Spring.GetUnitPosition(commanderID)
    targetEnemyComID = getNearestEnemyCommander(cx or 0, cz or 0)
    if targetEnemyComID then return Engage end
    return nil
end

local Engage = {}
function Engage:tick(sm)
    if not isUnitAlive(commanderID) then return nil end
    local myHP = Spring.GetUnitHealth(commanderID) or 0
    if not isUnitAlive(targetEnemyComID) then
        -- reacquire
        local cx, _, cz = Spring.GetUnitPosition(commanderID)
        targetEnemyComID = getNearestEnemyCommander(cx or 0, cz or 0)
        if not targetEnemyComID then return Travel end
    end
    local enemyHP = Spring.GetUnitHealth(targetEnemyComID) or 0
    if commanderMaxHP and (myHP - enemyHP) > (commanderMaxHP * HP_MARGIN_FRAC) then
        -- pursue and attack
        giveAttackUnit(commanderID, targetEnemyComID)
        return nil
    else
        return Retreat
    end
end

local Retreat = {}
local BuildWait = {}
function Retreat:enter(sm)
    lastBuildFrame = Spring.GetGameFrame() or 0
end
function Retreat:tick(sm)
    if not isUnitAlive(commanderID) then return nil end
    local frame = Spring.GetGameFrame() or 0
    local cx, cy, cz = Spring.GetUnitPosition(commanderID)
    -- set retreat destination: our own spawn, or just move 800 elmos away from enemy spawn direction
    local rx, ry, rz
    if mySpawn then
        rx, ry, rz = mySpawn.x, 0, mySpawn.z
    elseif enemySpawn and cx then
        rx, ry, rz = vecTowards(cx, cz, cx - (enemySpawn.x - cx), cz - (enemySpawn.z - cz), 800)
    else
        rx, ry, rz = vecTowards(cx or 0, cz or 0, (cx or 0) - 1, (cz or 0), 500)
    end
    local frame = Spring.GetGameFrame() or 0
    if sm.ticksInState % 30 == 1 and rx and frame >= buildBusyUntilFrame then
        -- queue move to avoid canceling build
        giveMove(commanderID, rx, rz, {"shift"})
    end
    -- no ad-hoc LLT building here; handled by BuildLLT state
    -- if we are healthier now than enemy commander, return to engage
    if isUnitAlive(targetEnemyComID) then
        local myHP = Spring.GetUnitHealth(commanderID) or 0
        local enemyHP = Spring.GetUnitHealth(targetEnemyComID) or 0
        if commanderMaxHP and (myHP - enemyHP) > (commanderMaxHP * HP_MARGIN_FRAC) then
            return Engage
        end
    else
        -- no target; travel again
        return Travel
    end
    return nil
end

-- Module API
function M.Init(teamID)
    myTeam = teamID
    myUnits = {}
    commanderID = nil
    targetEnemyComID = nil
    enemySpawn = nil
    mySpawn = nil
    detectLLTDefID()
    -- capture existing units
    local units = Spring.GetTeamUnits(teamID) or {}
    for i = 1, #units do
        myUnits[units[i]] = true
    end
    commanderID = findOurCommander()
    refreshCommanderMaxHP()
    -- prefer an LLT from commander's build options; fallback to generic scan
    detectBuildableLLTForCommander()
    if not LLTDefID then detectLLTDefID() end
    -- read optional modoptions to override LLT roll behavior
    local mo = Spring.GetModOptions and Spring.GetModOptions() or nil
    if mo then
        local iv = tonumber(mo.ai_build_roll_interval)
        if iv and iv > 0 then BUILD_ROLL_INTERVAL_FRAMES = math.floor(iv) end
        local ch = tonumber(mo.ai_build_roll_chance)
        if ch and ch >= 0 and ch <= 1 then BUILD_ROLL_CHANCE = ch end
    end
    -- init state machine
    state = smLib.Create(M)
    state:defineAll({
        Travel = Travel,
        Engage = Engage,
        Retreat = Retreat,
        BuildWait = BuildWait,
        BuildLLT = BuildLLT,
    })
    state:setState(Travel)
end

function M.UnitCreated(unitID, unitDefID, teamID)
    if teamID == myTeam then
        myUnits[unitID] = true
        if not commanderID and P.isCommander(unitDefID) then
            commanderID = unitID
            refreshCommanderMaxHP()
            detectBuildableLLTForCommander()
            if not LLTDefID then detectLLTDefID() end
        end
    end
end

function M.UnitFinished(unitID, unitDefID, teamID)
    if teamID == myTeam then
        myUnits[unitID] = true
    end
end

function M.UnitDestroyed(unitID)
    if unitID == commanderID then
        commanderID = nil
    end
    myUnits[unitID] = nil
end

function M.Update(frame)
    if not commanderID or not isUnitAlive(commanderID) then
        commanderID = commanderID or findOurCommander()
        if not commanderID then return end
        refreshCommanderMaxHP()
    end
    -- refresh mySpawn once
    if not mySpawn then
        local sx, _, sz = scenarioUtils.GetTeamStartPosition(myTeam)
        if sx then mySpawn = {x = sx, z = sz} end
    end
    -- update target enemy commander occasionally if lost
    if frame % 60 == 0 and commanderID then
        local cx, _, cz = Spring.GetUnitPosition(commanderID)
        targetEnemyComID = getNearestEnemyCommander(cx or 0, cz or 0)
    end
    -- periodic chance to attempt an LLT build regardless of current state
    if BUILD_ROLL_INTERVAL_FRAMES > 0
        and (frame % BUILD_ROLL_INTERVAL_FRAMES) == 0
        and not state:isIn(BuildLLT) and not state:isIn(BuildWait) then
        if math.random() < BUILD_ROLL_CHANCE then
            state:setState(BuildLLT)
        end
    end
    -- tick state machine every 6 frames to reduce spam
    if frame % 6 == 0 then
        state:update()
    end
end

return M
