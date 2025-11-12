local CU = VFS.Include("luarules/gadgets/ai/comp/lib/command_utils.lua")

local S = {}

function S.new(ctx)
    local self = {}
    function self:tick(sm)
        if not ctx.isAlive() then return nil end
        if not ctx.isEnemyCommanderValid() then
            local cx, _, cz = Spring.GetUnitPosition(ctx.unitID)
            ctx.acquireEnemyCommander(cx or 0, cz or 0)
            if not ctx.isEnemyCommanderValid() then return ctx.states.Travel end
        end
        -- Steer toward the enemy commander with a light cadence; only reissue if target changed
        if sm.ticksInState % 30 == 1 then
            local ex, ey, ez = Spring.GetUnitPosition(ctx.targetEnemyComID)
            if ex and ez then
                CU.ensureFight(ctx.unitID, ex, ez, {"shift"}, 64)
            end
        end
        return nil
    end
    return self
end

return S
