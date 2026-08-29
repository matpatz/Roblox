-- // Services
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Players = game:GetService("Players")

-- // Modules
local BulletHandler = require(ReplicatedStorage.ModuleScripts.GunModules.BulletHandler)

-- // Variables
local Fire = rawget(BulletHandler, "Fire")

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

-- // config
local config = {
    Origin,
    Range = 200,
    TeamCheck = false,
    AimPart = "Head",
    Visible = true,
    EntityLists = {
        Players:GetPlayers()
    },
    Blacklist = {}
}

local Aimbot = loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/Modules/Aimbot/main.lua"))()

Utils["Aimbot"].GetClosest = function(): (BasePart?)
    config["Origin"] = HumanoidRootPart.Position

    local Targets = {}
    for _, Player in Players:GetPlayers() do
        if Player == LocalPlayer then
            continue
        end

        const TargetCharacter = Player.Character
        if not TargetCharacter then
            continue
        end

        if not TargetCharacter:FindFirstChildWhichIsA("Tool") then
            continue
        end

        table.insert(Targets, Player)
    end
    config["EntityLists"] = { Targets }

    local Target, AimPart = Aimbot.GetClosest(config)

    return AimPart
end

if isfunctionhooked(Fire) then
    restorefunction(Fire)
end

local Old; Old = hookfunction(Fire, function(p3)
    const Target = Utils["Aimbot"].GetClosest()
    const Origin = p3.Origin

    if Target and Origin then
        p3.Direction = (Target.Position - Origin).Unit
    end

    return Old(p3)
end)