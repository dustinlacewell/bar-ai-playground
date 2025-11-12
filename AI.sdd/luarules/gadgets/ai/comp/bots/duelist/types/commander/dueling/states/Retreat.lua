local S = {}

function S.new(ctx)
    local self = {}
    function self:tick(sm)
        if not ctx.isAlive() then return nil end
        local cx, _, cz = Spring.GetUnitPosition(ctx.unitID)
        local rx, rz
        if ctx.enemySpawn and cx then
            local dx = ctx.enemySpawn.x - cx
            local dz = ctx.enemySpawn.z - cz
            local len = math.sqrt(dx*dx + dz*dz)
            if len > 1e-3 then
                local nx, nz = dx/len, dz/len
                rx, rz = cx - nx*800, cz - nz*800
            end
        end
        rx = rx or (cx - 500)
        rz = rz or cz
        if sm.ticksInState % 30 == 1 then
            ctx.giveMove(rx, rz, {"shift"})
        end
        if ctx.isEnemyCommanderValid() then
            local myHP = Spring.GetUnitHealth(ctx.unitID) or 0
            local enemyHP = Spring.GetUnitHealth(ctx.targetEnemyComID) or 0
            local ud = UnitDefs[Spring.GetUnitDefID(ctx.unitID)]
            local maxHP = (ud and ud.health) or 0
            if maxHP > 0 and (myHP - enemyHP) > (maxHP * (ctx.HP_MARGIN_FRAC or 0.1)) then
                return ctx.states.Engage
            end
        else
            return ctx.states.Travel
        end
        return nil
    end
    return self
end

return S
