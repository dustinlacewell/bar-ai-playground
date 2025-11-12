-- Build utility functions for placing structures near a builder unit
local BU = {}

local function isUnitAlive(u)
    if not u then return false end
    if not Spring.ValidUnitID(u) then return false end
    if Spring.GetUnitIsDead(u) then return false end
    return true
end

-- Try to place unitDefID near builderID using a small set of offsets around current position.
-- opts:
--   offsets: array of {dx, dz} offsets; if absent, a sensible default is used
--   stopBefore: bool, default true (issue CMD.STOP before build)
--   facings: {0..3} list, optional (default 0..3)
function BU.tryPlaceNear(builderID, unitDefID, opts)
    if not isUnitAlive(builderID) or not unitDefID then return false end
    opts = opts or {}
    local cx, cy, cz = Spring.GetUnitPosition(builderID)
    if not cx then return false end

    local offsets = opts.offsets or {
        { 64,  0}, { 96,  0}, {-64,  0},
        {  0, 64}, {  0,-64}, { 64, 64}, { 64,-64},
    }
    local facings = opts.facings or {0,1,2,3}

    for i = 1, #offsets do
        local off = offsets[i]
        local bx = cx + off[1]
        local bz = cz + off[2]
        local by = Spring.GetGroundHeight(bx, bz)
        for _, facing in ipairs(facings) do
            local ok = Spring.TestBuildOrder(unitDefID, bx, by, bz, facing)
            if ok == 2 then
                if opts.stopBefore ~= false then
                    Spring.GiveOrderToUnit(builderID, CMD.STOP, {}, {})
                end
                Spring.GiveOrderToUnit(builderID, -unitDefID, {bx, by, bz, facing}, {})
                return true
            end
        end
    end
    return false
end

return BU
