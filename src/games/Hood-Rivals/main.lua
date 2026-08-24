-- // Services
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Players = game:GetService("Players")
const TweenService = game:GetService("TweenService")
const RunService = game:GetService("RunService")

-- // Events
const Impact = ReplicatedStorage.GunRemotes.Impact

--// Workspace
local Camera = workspace.CurrentCamera -- whatever lol

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

Utils["Aimbot"].GetDirection = function(TargetRoot: BasePart): Vector3
    return TargetRoot.Position - Camera.CFrame.Position
end

--[[
	SentImpact: {
		[1]: number,
		[2]: Instance,
		[3]: Vector3,
		[4]: Vector3,
		[5]: Vector3,
	}
]]

-- Impact:FireServer(shotId, hitInstance, hitPos, dir * len, normal)
local __namecall
__namecall = hookmetamethod(game, "__namecall", function(self, ...)
    local Method = getnamecallmethod()
    if Method == "FireServer" and self == Impact then
        local Args = { ... }

        local Target, TargetRoot = Utils["Aimbot"].GetClosest()
        if Target and TargetRoot then
            Args[2] = TargetRoot
            Args[3] = TargetRoot.Position
            Args[4] = Utils["Aimbot"].GetDirection(TargetRoot)
        end
    end

    return __namecall(self, table.unpack(Args, 1, Args.n))
end)