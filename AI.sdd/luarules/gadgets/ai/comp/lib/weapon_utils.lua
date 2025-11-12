local M = {}

function M.FindWeaponByName(name)
    local wd = WeaponDefNames and WeaponDefNames[name]
    return wd and wd.id or nil
end

function M.FindWeaponsByPattern(pattern)
    local found = {}
    if not WeaponDefNames then return found end
    for weaponName, wd in pairs(WeaponDefNames) do
        if string.find(weaponName, pattern) then
            found[#found + 1] = { name = weaponName, id = wd.id }
        end
    end
    return found
end

local function GetWeaponDamage(weaponDefID)
    local wDef = weaponDefID and WeaponDefs and WeaponDefs[weaponDefID]
    if not wDef then return 0 end
    local dmg = 0
    if type(wDef.damage) == "table" then
        dmg = tonumber(wDef.damage.default) or 0
    elseif type(wDef.damage) == "number" then
        dmg = wDef.damage
    end
    return dmg
end

function M.FindBestStarburstLauncher()
    if not WeaponDefNames then return nil end
    local bestId, bestDamage = nil, -1
    for _, wd in pairs(WeaponDefNames) do
        local wDef = WeaponDefs and WeaponDefs[wd.id]
        if wDef and (wDef.weapontype == "StarburstLauncher" or wDef.type == "StarburstLauncher") then
            local dmg = GetWeaponDamage(wd.id)
            if dmg > bestDamage then
                bestDamage = dmg
                bestId = wd.id
            end
        end
    end
    return bestId
end

function M.GetWeaponVelocity(weaponDefID, default)
    local wDef = weaponDefID and WeaponDefs and WeaponDefs[weaponDefID]
    if not wDef then return default or 1600 end
    return wDef.weaponvelocity or wDef.startvelocity or default or 1600
end

return M
