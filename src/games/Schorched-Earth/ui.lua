local Knit = shared.Knit
local ui = Knit.ui
local scriptmanager = Knit.scriptmanager

local name = scriptmanager.name

local config = scriptmanager.config.get()
local core = scriptmanager.get("core")
local utils = scriptmanager.get("utils")

local Rayfield = ui.new("Rayfield")()
local Window = Rayfield:CreateWindow({
    Name = name,
    LoadingTitle = "Loading...",
    LoadingSubtitle = "#matpatz",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "voltexconfig",
        FileName = name
    }
})

local tabs = {
	Combat = Window:CreateTab("Combat"),
	Settings = Window:CreateTab("Settings"),
}

tabs.Combat:CreateToggle({
	Name = "Silent Aim",
	CurrentValue = config.SilentAim.Value,
	Flag = "SilentAim",
	Callback = function(value)
		core.Once:Fire()
		
        config.SilentAim.Value = value
	end,
})
