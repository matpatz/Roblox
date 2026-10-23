--// Knit
local Knit = shared.Knit

local scriptmanager = Knit.scriptmanager

local config = scriptmanager.config.set({
    flags = {},
    SilentAim = {
        Value = false,
    },
})
local flags = config.flags

--// core
local core = {}

flags.SilentAim:OnChanged(function(enabled)
    config.SilentAim.Value = enabled
end)

core = scriptmanager.set("core", core)

return core