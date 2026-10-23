local Knit = shared.Knit
local ui = Knit.ui
local scriptmanager = Knit.scriptmanager

local name = scriptmanager.name

local config = scriptmanager.config.get()
local core = scriptmanager.get("core")

local Amghook = ui.new("Amongus-hook")()

local Window = Amghook.windowClass.new({
    title = name,
    size = vector2(600, 500),
})

local flags = Window.flags
config.flags = flags

local tabs = {
    combat = Window:addTab("Combat"),
    visuals = Window:addTab("Visuals"),
}

--// Combat

tabs["combat"]:addToggle({
    text = "Silent Aim",
    default = config.SilentAim.Value,
    flag = "SilentAim",
}, 1)

--// Visuals

