--[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]
local antiafk =  true	

local player = game:GetService("Players").LocalPlayer
local vu = game:GetService("VirtualUser")

player.Idled:Connect(function()
	if not antiafk then return end

    vu:CaptureController()
    vu:ClickButton2(Vector2.new())
end)

-- == --

local lighting = game:GetService("Lighting")

local atmosphere = lighting.PollutionAtmosphere
local pcolor = lighting.PollutionColorCorrection

local white = function()
	return Color3.fromRGB(255, 255, 255)
end

local c1; c1 = atmosphere:GetPropertyChangedSignal("Density"):Connect(function()
	atmosphere.Density = 0
end); atmosphere.Density = 0
local c2; c2 = pcolor:GetPropertyChangedSignal("TintColor"):Connect(function()
	pcolor.TintColor = white()
end); pcolor.TintColor = white()
local c3; c3 = lighting:GetPropertyChangedSignal("OutdoorAmbient"):Connect(function()
	lighting.OutdoorAmbient = white()
end); lighting.OutdoorAmbient = white()
