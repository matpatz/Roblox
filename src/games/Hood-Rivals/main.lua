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

Utils["Aimbot"].GetClosest = function(): Player?
    local Targets = Aimbot.GetTargets(HumanoidRootPart, 500, {})
    return Aimbot.GetClosest(HumanoidRootPart, 500, Targets)
end

Utils["Aimbot"].Raycast = function(Target): Vector3?
    local Origin = Camera.CFrame.Position
    return Aimbot.Raycast(Origin, Target)
end

Utils["Aimbot"].GetDirection = function(Target): Vector3
    if not Target then
        local Target = Utils["Aimbot"].GetClosest()
    end
    local Direction = Utils["Aimbot"].Raycast(Target)

    return Direction
end

type SentImpact = {
    [1]: number,
    [2]: Instance,
    [3]: Vector3,
    [4]: Vector3,
    [5]: Vector3,
}

local __namecall; __namecall = hookmetamethod(game, "__namecall", function(self, ...)
    local Method = getnamecallmethod()
    local Args = table.unpack(...)

    if Method == "FireServer" and self == Impact then
        local Target = Utils["Aimbot"].GetClosest()
        local Direction = Utils["Aimbot"].Raycast(Target)

        if Target and Direction then
            Args[1] = Target
            Args[4] = Direction
        end
    end

    return __namecall(self, ...)
end)