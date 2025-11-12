local S = {}

local function detectLLTDefFromCommander(unitID)
    local cUD = UnitDefs[Spring.GetUnitDefID(unitID)]
    if not cUD or not cUD.buildOptions then return nil end
    for _, defID in ipairs(cUD.buildOptions) do
        local ud = UnitDefs[defID]
        local n = ud and ud.name and ud.name:lower() or ""
        if n == "armllt" or n == "corllt" then
            return defID
        end
    end
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

function S.new(ctx)
    local self = {}
    function self:enter(sm, prev)
        local unitID = ctx.unitID
        local LLTDefID = detectLLTDefFromCommander(unitID)
        if not LLTDefID then return sm:setState(prev or ctx.states.Travel) end
        local cx, cy, cz = Spring.GetUnitPosition(unitID)
        local offsets
        if cx then
            local tx, tz
            if ctx.isEnemyCommanderValid() then
                local ex, ey, ez = Spring.GetUnitPosition(ctx.targetEnemyComID)
                tx, tz = ex, ez
            elseif ctx.enemySpawn then
                tx, tz = ctx.enemySpawn.x, ctx.enemySpawn.z
            end
            if tx and tz then
                local dx = tx - cx
                local dz = tz - cz
                local len = math.sqrt(dx*dx + dz*dz)
                if len > 1e-3 then
                    local nx, nz = dx/len, dz/len
                    local px, pz = -nz, nx
                    offsets = {
                        { nx*120,  nz*120},
                        { nx*160,  nz*160},
                        { nx*120 + px*80,  nz*120 + pz*80},
                        { nx*120 - px*80,  nz*120 - pz*80},
                    }
                end
            end
        end
        if ctx.services.BU.tryPlaceNear(unitID, LLTDefID, {offsets = offsets}) then
            local targetPos
            if offsets and offsets[1] and cx then
                targetPos = { x = cx + offsets[1][1], z = cz + offsets[1][2] }
            end
            ctx._pendingBuild = ctx.services.buildTracker:startTracking(unitID, LLTDefID, targetPos)
        else
            sm:setState(prev or ctx.states.Travel)
        end
    end
    function self:tick(sm)
        local info = ctx.services.buildTracker:query(ctx.unitID)
        if info and (info.finished or (info.progress or 0) >= 1) then
            return sm.previous or ctx.states.Travel
        end
        if not info then
            return sm.previous or ctx.states.Travel
        end
        return nil
    end
    return self
end

return S
