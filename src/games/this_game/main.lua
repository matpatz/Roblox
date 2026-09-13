-- // Services
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Players = game:GetService("Players")
const TweenService = game:GetService("TweenService")
const RunService = game:GetService("RunService")

-- // Modules
const core = loadstring(game:HttpGet("https://voltex.website/src/games/this_game/core.lua"))()

-- // LocalPlayer
const LocalPlayer = Players.LocalPlayer

if not LocalPlayer.Character then
	LocalPlayer.CharacterAdded:Wait()
end
local Character = LocalPlayer.Character
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

LocalPlayer.CharacterAdded:Connect(function(NewCharacter)
	Character = NewCharacter
	HumanoidRootPart = NewCharacter:WaitForChild("HumanoidRootPart")
	Humanoid = NewCharacter:WaitForChild("Humanoid")
end)

--// variables
const UserId = LocalPlayer.UserId
local Flags = {}
Flags.__index = Flags

-- // config
local config = {
    Goals = {
        AutoScore = false
    }
}

-- // cheat
local cheat = {
	Utils = {

	},
	Core = {

	}
}
local Utils = cheat.Utils
local Core = cheat.Core

-- // Core

Core.Score = function()
	return core.Solve()
end

-- // Interface

local Rayfield = loadstring(game:HttpGet("https://voltex.website/libraries/Rayfield/main.lua"))()
Flags = Rayfield.Flags

local Window = Rayfield:CreateWindow({
    Name = "this game",
    LoadingTitle = "Loading...",
    LoadingSubtitle = "subtitle",
})

local tabs = {
    Score = Window:CreateTab("Score"),
    Settings = Window:CreateTab("Settings"),
}

-- // Eggs

tabs.Score:CreateToggle({
    Name = "Auto Score Goal",
    CurrentValue = false,
    Flag = "AutoScoreGoal",
    Callback = function(Value)
        if not Value then
            return
        end
    end,
})

tabs.Score:CreateButton({
    Name = "Score Goal",
    Callback = function()
        Core.Score()
    end,
})
