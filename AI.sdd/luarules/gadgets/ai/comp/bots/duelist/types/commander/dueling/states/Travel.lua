local S = {}

function S.new(ctx)
    local self = {}
    function self:enter(sm)
        local myX, _, myZ = Spring.GetUnitPosition(ctx.unitID)
        local target = ctx.services.scenarioUtils.GetNearestEnemyStartPosition(ctx.teamID, myX or 0, myZ or 0)
        ctx.enemySpawn = target and {x=target.x, z=target.z} or ctx.enemySpawn
    end
    function self:tick(sm)
        if not ctx.isAlive() then return nil end
        if sm.ticksInState % 180 == 1 then
            local myX, _, myZ = Spring.GetUnitPosition(ctx.unitID)
            local target = ctx.services.scenarioUtils.GetNearestEnemyStartPosition(ctx.teamID, myX or 0, myZ or 0)
            ctx.enemySpawn = target and {x=target.x, z=target.z} or ctx.enemySpawn
        end
        if sm.ticksInState % 30 == 1 then
            local tx, tz
            if ctx.isEnemyCommanderValid() then
                local ex, ey, ez = Spring.GetUnitPosition(ctx.targetEnemyComID)
                tx, tz = ex, ez
            elseif ctx.enemySpawn then
                tx, tz = ctx.enemySpawn.x, ctx.enemySpawn.z
            end
            if tx and tz then ctx.giveFight(tx, tz, {"shift"}) end
        end
        local cx, _, cz = Spring.GetUnitPosition(ctx.unitID)
        ctx.acquireEnemyCommander(cx or 0, cz or 0)
        if ctx.targetEnemyComID then return ctx.states.Engage end
        return nil
    end
    return self
end

return S
