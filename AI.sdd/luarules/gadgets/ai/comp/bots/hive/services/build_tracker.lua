-- BuildTracker: tracks builds started by builders and reports progress/completion
local M = {}
M.__index = M

function M.new()
    local self = setmetatable({}, M)
    self.byBuilder = {}   -- builderID -> { buildID, defID, x,z, startedFrame }
    self.byBuild   = {}   -- buildID -> builderID
    return self
end

-- helpers
local function dist2(x1,z1,x2,z2)
    local dx, dz = (x1-x2), (z1-z2)
    return dx*dx + dz*dz
end

-- Begin tracking a requested build near targetPos (x,z)
function M:startTracking(builderID, unitDefID, targetPos)
    local bx = targetPos and targetPos.x or nil
    local bz = targetPos and targetPos.z or nil
    local buildID = Spring.GetUnitIsBuilding(builderID)
    if buildID then
        self.byBuilder[builderID] = { buildID = buildID, defID = unitDefID, x = bx, z = bz, startedFrame = Spring.GetGameFrame() or 0 }
        self.byBuild[buildID] = builderID
        return buildID
    end
    -- not yet known; create pending entry without buildID
    self.byBuilder[builderID] = { buildID = nil, defID = unitDefID, x = bx, z = bz, startedFrame = Spring.GetGameFrame() or 0 }
    return nil
end

function M:UnitCreated(unitID, unitDefID, teamID)
    -- bind pending builder if close to intended pos and def matches
    for builderID, rec in pairs(self.byBuilder) do
        if not rec.buildID and rec.defID == unitDefID and rec.x and rec.z then
            local x, y, z = Spring.GetUnitPosition(unitID)
            if x and dist2(x, z, rec.x, rec.z) <= (200*200) then
                rec.buildID = unitID
                self.byBuild[unitID] = builderID
                break
            end
        end
    end
end

function M:UnitFinished(unitID, unitDefID, teamID)
    local builderID = self.byBuild[unitID]
    if builderID then
        -- mark finished by clearing tracking; controllers can query before this tick if needed
        self.byBuild[unitID] = nil
        self.byBuilder[builderID] = nil
    end
end

function M:UnitDestroyed(unitID, unitDefID, teamID)
    local builderID = self.byBuild[unitID]
    if builderID then
        self.byBuild[unitID] = nil
        self.byBuilder[builderID] = nil
    end
end

function M:update(frame)
    -- optional: could clean stale pending records
end

-- Query current build info for a builder
-- returns { buildID, progress, finished } or nil
function M:query(builderID)
    local rec = self.byBuilder[builderID]
    if not rec then return nil end
    local buildID = rec.buildID or Spring.GetUnitIsBuilding(builderID)
    if buildID and not rec.buildID then
        rec.buildID = buildID
        self.byBuild[buildID] = builderID
    end
    local finished = false
    local progress = 0
    if buildID then
        local _, _, _, _, bp = Spring.GetUnitHealth(buildID)
        progress = bp or 0
        -- finished will be observed via UnitFinished; treat >=1 as finished as well
        finished = (progress >= 1)
    end
    return { buildID = buildID, progress = progress, finished = finished, defID = rec.defID }
end

return M
