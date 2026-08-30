-- // Services
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Players = game:GetService("Players")

-- // Modules
local ProjectileHandler = ReplicatedStorage.Modules.Other.WeaponStuff.ProjectileHandler

local PropagateBullet = require(ProjectileHandler.Functions.PropagateBullet)
assert(PropagateBullet, "PropagateBullet not found")

-- // Variables
--local HandleBullets = ProjectileHandler.HandleBullets

const table_insert = table.insert -- + zeptosecond 

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
    Range = 400,
    TeamCheck = true,
    AimPart = "Head",
    Visible = true,
    EntityLists = {
        Players:GetPlayers()
    },
}

local Aimbot = loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/Modules/Aimbot/main.lua"))()

Utils["Aimbot"].GetClosest = function(p11): (BasePart?)
    local Targets = {}
    for _, Target in next, workspace:QueryDescendants("Model:has(Humanoid)") do
        const AimPart = config["AimPart"]

        if p11.Player.Team ~= LocalPlayer.Team then
            table_insert(Targets, Target.AimPart)
        end
    end
    local Target, AimPart = Aimbot.GetClosest(config)

    return AimPart
end

if isfunctionhooked(PropagateBullet) then
    restorefunction(PropagateBullet)
end

local Old; Old = hookfunction(PropagateBullet, function(v14, u1)
    if v14.IsMainClient then
        local Origin = v14.StartCFrame.Position  -- muzzle
        config["Origin"] = Origin

        local AimPart = Utils["Aimbot"].GetClosest(v14)
        if AimPart then
            local Speed = v14.BulletVector.Magnitude
            v14.BulletVector = (AimPart.Position - Origin).Unit * Speed
        end
    end
    return Old(v14, u1)
end)