--[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]
getgenv()["font"] = Enum.Font.Garamond
	-- the font of your choice

getgenv()["active"] = true
	-- if it's false: revert changes

local IncludeRoblox = true
	-- items parented to CoreGui.RobloxGui (Roblox's ui)

local services = {
	CoreGui = game.CoreGui,
	Player = game.Players.LocalPlayer
}

local pgui = services["Player"]["PlayerGui"]

local items = {}
for _, v in ipairs(services["CoreGui"]:GetDescendants()) do
	table.insert(items, v)
end; for _, v in ipairs(pgui:GetDescendants()) do
	table.insert(items, v)
end

local valid = {
    TextLabel = true,
    TextButton = true,
    TextBox = true
}

local old = {}
local function process(item)
	if IncludeRoblox and item.Parent == services["CoreGui"]["RobloxGui"] then
		return
	end

	if valid[item.ClassName] then
		old[item] = old[item] or item.Font
		item.Font = getgenv()["font"]
	end
end

local function main()
	for _, item in ipairs(items) do
		process(item)
	end
end

-- undo changes
local function revert()
	for item, font in pairs(old) do
		if item then
			item.Font = font
		end

		old[item] = nil
	end
end

services["CoreGui"].DescendantAdded:Connect(function(item)
	if getgenv()["active"] then
		process(item)
	end
end)

pgui.DescendantAdded:Connect(function(item)
	if getgenv()["active"] then
		process(item)
	end
end)

getgenv()["processed"] = false
task.spawn(function()
	while task.wait(2) do
		if getgenv()["active"] == true then
			main()
		elseif not getgenv()["active"] then
			revert()
		end

		getgenv()["processed"] = getgenv()["active"]
	end
end)
