-- Command utilities for safe/efficient order issuing
local CU = {}

-- Ensure a FIGHT order toward (x,z) is present at the head of the queue.
-- Will not re-issue if the top command is already a similar FIGHT.
-- opts: command options array (e.g., {"shift"})
-- tolerance: max distance between existing fight target and (x,z) to consider it similar
function CU.ensureFight(unitID, x, z, opts, tolerance)
    local tol = tolerance or 64
    local q = Spring.GetCommandQueue(unitID, 1)
    if q and q[1] and q[1].id == CMD.FIGHT then
        local p = q[1].params
        if p and p[1] and p[3] then
            local dx = (p[1] - x)
            local dz = (p[3] - z)
            if (dx*dx + dz*dz) <= (tol*tol) then
                return false -- already fighting roughly this target
            end
        end
    end
    local y = Spring.GetGroundHeight(x, z)
    Spring.GiveOrderToUnit(unitID, CMD.FIGHT, {x, y, z}, opts or {})
    return true
end

return CU
