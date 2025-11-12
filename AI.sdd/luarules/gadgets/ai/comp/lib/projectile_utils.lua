local M = {}
local WeaponUtils = VFS.Include("luarules/gadgets/ai/comp/lib/weapon_utils.lua")

function M.FindNukeWeapon()
    return WeaponUtils.FindWeaponByName("cordesolator_crblmssl") or WeaponUtils.FindBestStarburstLauncher()
end

function M.SpawnProjectileWithVelocity(weaponDefID, pos, speed, owner, ttl)
    if not weaponDefID or not pos or not speed then return nil end
    local params = {
        pos = pos,
        speed = speed,
        owner = owner or -1,
        ttl = ttl or 300,
    }
    return Spring.SpawnProjectile(weaponDefID, params)
end

function M.SpawnProjectileTowards(weaponDefID, fromPos, toPos, teamID, speed, ttl)
    if not weaponDefID or not fromPos or not toPos then return nil end
    local vx = toPos[1] - fromPos[1]
    local vy = toPos[2] - fromPos[2]
    local vz = toPos[3] - fromPos[3]
    local mag = math.sqrt(vx*vx + vy*vy + vz*vz)
    if mag == 0 then return nil end
    local v = speed or WeaponUtils.GetWeaponVelocity(weaponDefID)
    local scale = v / mag
    local vel = { vx * scale, vy * scale, vz * scale }
    return M.SpawnProjectileWithVelocity(weaponDefID, fromPos, vel, teamID or -1, ttl)
end

function M.SpawnNukeFromAbove(targetX, targetZ, teamID, opts)
    local weaponID = (opts and opts.weaponDefID) or M.FindNukeWeapon()
    if not weaponID then return nil end
    local altitude = (opts and opts.altitude) or 5000
    local v = (opts and opts.speed) or WeaponUtils.GetWeaponVelocity(weaponID)
    local pos = { targetX, altitude, targetZ }
    local vel = { 0, -v, 0 }
    local ttl = (opts and opts.ttl) or 300
    return M.SpawnProjectileWithVelocity(weaponID, pos, vel, teamID or -1, ttl)
end

return M
