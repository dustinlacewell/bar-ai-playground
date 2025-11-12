-- Duelist AI regime: exports a hive configuration mapping unit types to state-machine factories
local config = {}

-- import factories defined under duelist/types
local CommanderDueling = VFS.Include("luarules/gadgets/ai/comp/bots/duelist/types/commander/dueling/init.lua")

config.types = {
    commander = CommanderDueling,
}

return config
