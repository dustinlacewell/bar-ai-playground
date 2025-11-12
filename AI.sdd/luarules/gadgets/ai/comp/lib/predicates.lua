-- Predicate helpers for BAR AIs (synced)
local P = {}

local function ud(udid) return udid and UnitDefs[udid] end

function P.isCommander(udid)
  local u = ud(udid); return u and u.customParams and u.customParams.iscommander or false
end

function P.isFactory(udid)
  local u = ud(udid); return u and u.isFactory and u.buildOptions and #u.buildOptions > 0 or false
end

function P.isBuilder(udid)
  local u = ud(udid); return u and u.canMove and u.isBuilder and u.buildOptions and #u.buildOptions > 0 or false
end

function P.isBuilding(udid)
  local u = ud(udid); return u and u.isBuilding or false
end

function P.isMobile(udid)
  local u = ud(udid); return u and (not u.isBuilding) and u.canMove or false
end

function P.hasWeapon(udid)
  local u = ud(udid); return u and u.weapons and #u.weapons > 0 or false
end

function P.isTurret(udid)
  local u = ud(udid); return u and u.isBuilding and u.weapons and #u.weapons > 0 or false
end

function P.isExtractor(udid)
  local u = ud(udid); return u and (u.extractsMetal or 0) > 0 or (u.customParams and u.customParams.metal_extractor)
end

function P.isGenerator(udid)
  local u = ud(udid)
  if not u then return false end
  return (u.energyMake or 0) > 19 or (u.windGenerator or 0) > 0 or (u.tidalGenerator or 0) > 0 or (u.customParams and u.customParams.solar)
end

return P
