-- // Services
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Players = game:GetService("Players")
const TweenService = game:GetService("TweenService")
const RunService = game:GetService("RunService")

-- // Modules
const SimpleCast = require(ReplicatedStorage.SimpleCast)

--// LocalPlayer
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

-- // cheat
local cheat = {
	Utils = {
        ["Aimbot"] = {}
	},
	Core = {

	}
}
local Utils = cheat.Utils
local Core = cheat.Core

local Aimbot = loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/Modules/Aimbot.lua"))()

Utils["Aimbot"].GetClosest = function(): (Player?, BasePart?)
    local Targets = Aimbot.GetTargets(HumanoidRootPart, 1000, {})
    return Aimbot.GetClosest(HumanoidRootPart, 1000, Targets)
end

local OldFire = SimpleCast.Fire
SimpleCast.Fire = function(self, Origin, Direction, Velocity, Config)
    local Target, TargetRoot = Utils["Aimbot"].GetClosest()

    if Target ~= nil and TargetRoot ~= nil then
        Direction = (TargetRoot.Position - Origin).Unit
    end

    return OldFire(self, Origin, Direction, Velocity, Config)
end