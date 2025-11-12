--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  LuaAI.lua
--
--    List of LuaAIs supported by the mod.
--
--

local list = {
}

-- Append dynamically discovered AIs from dev folder
local function basename(path)
  return path:match('([^/\\]+)%.lua$')
end

local aiDir = 'luarules/gadgets/ai/comp/bots'
if VFS and VFS.DirList then
  local files = VFS.DirList(aiDir, '*.lua', VFS.RAW_FIRST)
  Spring.Echo("[luaai.lua] Found " .. (#files or 0) .. " files in " .. aiDir)
  for _, f in ipairs(files or {}) do
    local name = basename(f)
    Spring.Echo("[luaai.lua] Processing file: " .. f .. " -> name: " .. tostring(name))
    if name and name ~= 'ai_framework' then
      list[#list+1] = {
        name = name,
        desc = 'Dev AI: '..name,
      }
      Spring.Echo("[luaai.lua] Added AI: " .. name)
    end
  end
  Spring.Echo("[luaai.lua] Total AIs loaded: " .. #list)
  for i, ai in ipairs(list) do
    Spring.Echo("[luaai.lua] AI " .. i .. ": " .. ai.name .. " - " .. ai.desc)
  end
else
  Spring.Echo("[luaai.lua] ERROR: VFS or VFS.DirList not available")
end

return list

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
