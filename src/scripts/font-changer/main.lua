--[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]
--// Knit
local Knit = shared.Knit
local services = Knit.services
local conmanager = Knit.conmanager
local scriptmanager = Knit.scriptmanager

--// services
local CoreGui = services.CoreGui
local Players = services.Players

local PlayerGui = Players.LocalPlayer.PlayerGui
local RobloxGui = CoreGui:FindFirstChild("RobloxGui")

--// config
local config = scriptmanager.config.set({
	Font = { Value = Enum.Font.Garamond },
		-- the font forced onto every text object

	Active = { Value = true },
		-- false reverts every change

	IncludeRoblox = { Value = true },
		-- CoreGui.RobloxGui items (Roblox's own ui)
})

local TextClasses = "TextLabel, TextButton, TextBox"

local Containers = {
	["font_changer/core"] = CoreGui,
	["font_changer/player"] = PlayerGui,
}

local old = {}

-- a second run of this script has to take over instead of stacking: it would
-- otherwise record the first run's font as every item's "original", and turning
-- that second run off can then never unfont anything
local Previous = getgenv().FontChanger

local function isRobloxUi(item)
	return not config.IncludeRoblox.Value and RobloxGui ~= nil and item:IsDescendantOf(RobloxGui)
end

-- roblox's icon fonts draw a glyph from the label's text, so forcing a text
-- font on them turns the icon into its name ("magnifying-glass"); only labels
-- already using one of Roblox's text fonts are safe to touch
local TextFamilies = {}
local HasFontFace = pcall(FontFace.new, Enum.Font.Garamond)

if HasFontFace then
	for _, font in Enum.Font:GetEnumItems() do
		local ok, face = pcall(FontFace.new, font)

		if ok then
			TextFamilies[face.Family] = true
		end
	end
end

local FamilyFilter = HasFontFace and next(TextFamilies) ~= nil

local function fontFaceOf(item)
	if not HasFontFace then
		return nil
	end

	local ok, face = pcall(function()
		return item.FontFace
	end)

	return if ok then face else nil
end

local function isTextFont(item)
	if not FamilyFilter then
		return true
	end

	local face = fontFaceOf(item)

	return face == nil or face.Family == "" or TextFamilies[face.Family] == true
end

-- a single unwritable instance must not abort the whole pass; the record is
-- either an Enum.Font or a FontFace, whichever the label carried
local function setFont(item, font)
	if typeof(font) == "EnumItem" then
		return pcall(function()
			item.Font = font
		end)
	end

	return pcall(function()
		item.FontFace = font
	end)
end

local function release(item, restore)
	local original = old[item]

	if original == nil then
		return
	end

	if restore then
		setFont(item, original)
	end

	old[item] = nil
end

local function process(item)
	if isRobloxUi(item) then
		release(item, true)

		return
	end

	-- the game swapped in an icon font, so it owns the label from here on
	if not isTextFont(item) then
		release(item, false)

		return
	end

	local face = fontFaceOf(item)

	if old[item] == nil then
		old[item] = face or item.Font
	end

	if face then
		setFont(item, FontFace.new(config.Font.Value, face.Weight, face.Style))
	else
		setFont(item, config.Font.Value)
	end
end

local function processTree(root)
	if root:IsA(TextClasses) then
		process(root)
	end

	for _, item in root:QueryDescendants(TextClasses) do
		process(item)
	end
end

local function revert()
	for item, font in old do
		if item.Parent == nil or setFont(item, font) then
			old[item] = nil
		end
	end
end

local function sweep()
	if not config.Active.Value then
		revert()

		return
	end

	for _, container in Containers do
		processTree(container)
	end
end

-- the poll thread dies for good if anything throws in it, so it never runs bare
local function poll()
	local ok, err = pcall(sweep)

	if not ok then
		warn("font_changer: " .. tostring(err))
	end
end

--// connections
local destroyUi

local function shutdown()
	config.Active.Value = false
	revert()

	conmanager.disconnect("font_changer/core")
	conmanager.disconnect("font_changer/player")
	conmanager.disconnect("font_changer/loop")

	if destroyUi then
		destroyUi()
	end
end

if Previous and Previous.shutdown then
	pcall(Previous.shutdown)
end

getgenv().FontChanger = {
	shutdown = shutdown,
	config = config,
}

for key, container in Containers do
	conmanager.connect(key, container.DescendantAdded, function(item)
		if not config.Active.Value then
			return
		end

		processTree(item)
	end)
end

conmanager.connect("font_changer/loop", 2, poll)

--// ui
local Rayfield = Knit.ui.new("Rayfield")()

local Window = Rayfield:CreateWindow({
	Name = "Font Changer",
	LoadingTitle = "Font Changer",
	LoadingSubtitle = "voltex",
	ConfigurationSaving = { Enabled = false },
})

local Main = Window:CreateTab("Main", 4483362458)
local a = Window:CreateTab("a")

destroyUi = function()
	Rayfield:Destroy()
end


Main:CreateSection("Font")

local FontNames = {}
for _, Font in Enum.Font:GetEnumItems() do
	table.insert(FontNames, Font.Name)
end

Main:CreateDropdown({
	Name = "Font",
	Options = FontNames,
	CurrentOption = { config.Font.Value.Name },
	MultipleOptions = false,
	Flag = "",

	Callback = function(Selected)
		local Font = Enum.Font[Selected[1]]

		if not Font then
			return
		end

		config.Font.Value = Font
		sweep()
	end,
})

Main:CreateSection("Settings")

Main:CreateToggle({
	Name = "Active",
	CurrentValue = config.Active.Value,
	Flag = "",

	Callback = function(Value)
		config.Active.Value = Value
		sweep()
	end,
})

Main:CreateToggle({
	Name = "Include Roblox UI",
	CurrentValue = config.IncludeRoblox.Value,
	Flag = "",

	Callback = function(Value)
		config.IncludeRoblox.Value = Value
		sweep()
	end,
})
