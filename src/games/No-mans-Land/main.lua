-- // Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- // Modules
local ProjectileHandler = require(game.ReplicatedStorage.Modules.Other.WeaponStuff.ProjectileHandler)

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

-- // Variables
local PropagateBullet = debug.getupvalue(ProjectileHandler.HandleBullets, 8)
assert(PropagateBullet, "PropagateBullet not found")

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

Utils["Aimbot"].GetClosest = function(): (BasePart?)
    -- local Targets = Aimbot.GetTargets(HumanoidRootPart, 400, nil)
    local Target, AimPart = Aimbot.GetClosest(config)

    return AimPart
end

debug.setupvalue(ProjectileHandler.HandleBullets, 8, function(v14, u1)
    if v14.IsMainClient then
        local Origin = v14.StartCFrame.Position  -- muzzle
        config["Origin"] = Origin

        local AimPart = Utils["Aimbot"].GetClosest()
        if AimPart then
            local Speed = v14.BulletVector.Magnitude
            v14.BulletVector = (AimPart.Position - Origin).Unit * Speed
        end
    end
    return PropagateBullet(v14, u1)
end)