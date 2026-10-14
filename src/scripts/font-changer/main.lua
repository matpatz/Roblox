--[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]
--// Knit
local Knit = shared.Knit
local services = Knit.services
local conmanager = Knit.conmanager

--// services
local CoreGui = services.CoreGui
local Players = services.Players

local PlayerGui = Players.LocalPlayer.PlayerGui
local RobloxGui = CoreGui:FindFirstChild("RobloxGui")

--// config
getgenv()["font"] = Enum.Font.Garamond
	-- the font of your choice

getgenv()["active"] = true
	-- if it's false: revert changes

local IncludeRoblox = true
	-- items parented to CoreGui.RobloxGui (Roblox's ui)

local Containers = { CoreGui, PlayerGui }

local old = {}

local function process(item)
	if IncludeRoblox and item.Parent == RobloxGui then
		return
	end

	old[item] = old[item] or item.Font
	item.Font = getgenv()["font"]
end

local function main()
	for _, Container in Containers do
		for _, item in Container:QueryDescendants("TextLabel, TextButton, TextBox") do
			process(item)
		end
	end
end

local function revert()
	for item, font in old do
		item.Font = font

		old[item] = nil
	end
end

--// connections
conmanager.connect("font_changer/core", CoreGui.DescendantAdded, function(item)
	if getgenv()["active"] then
		process(item)
	end
end)

conmanager.connect("font_changer/player", PlayerGui.DescendantAdded, function(item)
	if getgenv()["active"] then
		process(item)
	end
end)

getgenv()["processed"] = false

conmanager.connect("font_changer/loop", 2, function()
	if getgenv()["active"] then
		main()
	else
		revert()
	end

	getgenv()["processed"] = getgenv()["active"]
end)
