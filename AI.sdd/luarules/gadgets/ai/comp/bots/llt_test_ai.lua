-- LLT Test AI: builds a single Light Laser Tower near the commander
local M = {}

local myTeam
local commanderID
local built = false
local BU = VFS.Include("luarules/gadgets/ai/comp/lib/build_utils.lua")

local function isUnitAlive(u)
    if not u then return false end
    if not Spring.ValidUnitID(u) then return false end
    if Spring.GetUnitIsDead(u) then return false end
    return true
end

local function findCommander(teamID)
    local units = Spring.GetTeamUnits(teamID) or {}
    for i = 1, #units do
        local u = units[i]
        local udid = Spring.GetUnitDefID(u)
        local ud = udid and UnitDefs[udid]
        if ud and ud.customParams and ud.customParams.iscommander then
            return u
        end
    end
    return nil
end

local function detectLLTDefFromCommander(commanderID)
    local cUD = UnitDefs[Spring.GetUnitDefID(commanderID)]
    if not cUD or not cUD.buildOptions then return nil end
    -- exact names
    for _, defID in ipairs(cUD.buildOptions) do
        local ud = UnitDefs[defID]
        local n = ud and ud.name and ud.name:lower() or ""
        if n == "armllt" or n == "corllt" then
            return defID
        end
    end
    -- heuristic fallback
    for _, defID in ipairs(cUD.buildOptions) do
        local ud = UnitDefs[defID]
        if ud and ud.isBuilding and ud.weapons and #ud.weapons > 0 then
            local n = (ud.name or ""):lower()
            local hn = (ud.humanName or ""):lower()
            if n:find("llt") or (hn:find("light") and hn:find("laser")) then
                return defID
            end
        end
    end
    return nil
end

function M.Init(teamID)
    myTeam = teamID
    commanderID = findCommander(teamID)
    built = false
end

function M.Update(frame)
    if built then return end
    if not commanderID or not isUnitAlive(commanderID) then
        commanderID = findCommander(myTeam)
        if not commanderID then return end
    end
    local lltDefID = detectLLTDefFromCommander(commanderID)
    if lltDefID and BU.tryPlaceNear(commanderID, lltDefID) then
        built = true
    end
end

-- track commander if newly created
function M.UnitCreated(unitID, unitDefID, teamID)
    if teamID ~= myTeam then return end
    local ud = UnitDefs[unitDefID]
    if ud and ud.customParams and ud.customParams.iscommander then
        commanderID = unitID
    end
end

function M.UnitDestroyed(unitID)
    if unitID == commanderID then
        commanderID = nil
    end
end

return M
