-- Commander dueling controller factory (duelist regime)
local smLib = VFS.Include("luarules/gadgets/ai/comp/lib/state_machine.lua")

local Travel = VFS.Include("luarules/gadgets/ai/comp/bots/duelist/types/commander/dueling/states/Travel.lua")
local Engage = VFS.Include("luarules/gadgets/ai/comp/bots/duelist/types/commander/dueling/states/Engage.lua")
local Retreat = VFS.Include("luarules/gadgets/ai/comp/bots/duelist/types/commander/dueling/states/Retreat.lua")
local BuildLLT = VFS.Include("luarules/gadgets/ai/comp/bots/duelist/types/commander/dueling/states/BuildLLT.lua")

local Factory = {}

function Factory.new(teamID, unitID, services)
    local ctx = {
        teamID = teamID,
        unitID = unitID,
        services = services,
        state = smLib.Create(nil),
        states = {},
        enemySpawn = nil,
        targetEnemyComID = nil,
        HP_MARGIN_FRAC = 0.1,
        rollInterval = 30,
        rollChance = 0.15,
    }

    function ctx.isAlive()
        local u = ctx.unitID
        if not u then return false end
        if not Spring.ValidUnitID(u) then return false end
        if Spring.GetUnitIsDead(u) then return false end
        return true
    end
    function ctx.isEnemyCommanderValid()
        local id = ctx.targetEnemyComID
        return id and Spring.ValidUnitID(id) and not Spring.GetUnitIsDead(id)
    end
    function ctx.acquireEnemyCommander(px, pz)
        local bestID, bestDistSq
        local myAllyTeam = select(6, Spring.GetTeamInfo(ctx.teamID, false))
        for _, tID in ipairs(Spring.GetTeamList()) do
            if tID ~= ctx.teamID then
                local _, _, _, _, _, allyTeamID = Spring.GetTeamInfo(tID, false)
                if allyTeamID ~= myAllyTeam then
                    local units = Spring.GetTeamUnits(tID) or {}
                    for i = 1, #units do
                        local u = units[i]
                        if Spring.ValidUnitID(u) and not Spring.GetUnitIsDead(u) then
                            local udid = Spring.GetUnitDefID(u)
                            local ud = UnitDefs[udid]
                            if ud and ud.customParams and ud.customParams.iscommander then
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
        ctx.targetEnemyComID = bestID
    end
    function ctx.giveFight(x, z, opts)
        local y = Spring.GetGroundHeight(x, z)
        Spring.GiveOrderToUnit(ctx.unitID, CMD.FIGHT, {x, y, z}, opts or {})
    end
    function ctx.giveMove(x, z, opts)
        local y = Spring.GetGroundHeight(x, z)
        Spring.GiveOrderToUnit(ctx.unitID, CMD.MOVE, {x, y, z}, opts or {})
    end
    function ctx.giveAttackUnit(targetID)
        Spring.GiveOrderToUnit(ctx.unitID, CMD.ATTACK, {targetID}, {})
    end

    local mo = Spring.GetModOptions and Spring.GetModOptions() or nil
    if mo then
        local iv = tonumber(mo.ai_build_roll_interval)
        if iv and iv > 0 then ctx.rollInterval = math.floor(iv) end
        local ch = tonumber(mo.ai_build_roll_chance)
        if ch and ch >= 0 and ch <= 1 then ctx.rollChance = ch end
    end

    ctx.states.Travel = Travel.new(ctx)
    ctx.states.Engage = Engage.new(ctx)
    ctx.states.Retreat = Retreat.new(ctx)
    ctx.states.BuildLLT = BuildLLT.new(ctx)

    ctx.state:defineAll(ctx.states)
    ctx.state:setState(ctx.states.Travel)

    function ctx:tick(frame)
        if not ctx.isAlive() then return end
        local inBuild = ctx.state:isIn(ctx.states.BuildLLT)
        -- Primary retreat/engage gating based on HP margin
        if not inBuild then
            local enemyKnown = ctx.isEnemyCommanderValid()
            if not enemyKnown then
                local cx, _, cz = Spring.GetUnitPosition(ctx.unitID)
                ctx.acquireEnemyCommander(cx or 0, cz or 0)
                enemyKnown = ctx.isEnemyCommanderValid()
            end
            if enemyKnown then
                local myHP = Spring.GetUnitHealth(ctx.unitID) or 0
                local enemyHP = Spring.GetUnitHealth(ctx.targetEnemyComID) or 0
                local ud = UnitDefs[Spring.GetUnitDefID(ctx.unitID)]
                local maxHP = (ud and ud.health) or 0
                local margin = (ctx.HP_MARGIN_FRAC or 0.1) * maxHP
                if maxHP > 0 and (enemyHP - myHP) > margin then
                    if not ctx.state:isIn(ctx.states.Retreat) then
                        ctx.state:setState(ctx.states.Retreat)
                    end
                else
                    if not ctx.state:isIn(ctx.states.Engage) then
                        ctx.state:setState(ctx.states.Engage)
                    end
                end
            end
        end
        -- Periodic LLT build roll (skip during BuildLLT)
        if ctx.rollInterval > 0 and (frame % ctx.rollInterval) == 0 then
            if (not inBuild) and math.random() < ctx.rollChance then
                ctx.state:setState(ctx.states.BuildLLT)
            end
        end
        ctx.state:update()
    end

    return ctx
end

return Factory
