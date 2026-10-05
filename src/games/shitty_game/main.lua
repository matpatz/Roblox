--// Knit
local Knit = shared.Knit
local services = Knit.services

-- // Services
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Players = game:GetService("Players")

-- // Modules
const GunRemotes = require(ReplicatedStorage.GunRemotes)

--// functions

local ProjectileShot = GunRemotes.Network.packets.C2SProjectileShot.Fire
local HitscanShot = GunRemotes.Network.packets.C2SHitscanShot.Fire

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
		["Aimbot"] = {},
	},
	Core = {},
}
local Utils = cheat.Utils
local Core = cheat.Core

-- // config
local config = {
	SilentAim = {
		Enabled = true,
		Range = 400,
		AimPart = "Head",
		TeamCheck = true,
		WallCheck = true,
	},
}

local Aimbot = Knit.require("Modules/Aimbot/v1", "main")

-- // Utils

local aimconfig = {
    Origin,
    Range = config.SilentAim.Range,
    TeamCheck = false,
    AimPart = config.SilentAim.AimPart,
    Visible = config.SilentAim.WallCheck,
    EntityLists = {},
}

Utils["Aimbot"].GetClosest = function(): BasePart?
    aimconfig["Origin"] = HumanoidRootPart.Position
    aimconfig["EntityLists"] = {
        Players:GetPlayers()
    }

	local _, AimPart = Aimbot.GetTarget(aimconfig)
	return AimPart
end

-- // core

-- different bullet type support

if isfunctionhooked(ProjectileShot) then
	restorefunction(ProjectileShot)
end

if isfunctionhooked(HitscanShot) then
	restorefunction(HitscanShot)
end

local OldProjectileShot
OldProjectileShot = hookfunction(ProjectileShot, function(shotdata, barrel)
    print("hooked (projectile)")

    const AimPart = Utils["Aimbot"].GetClosest()
    if AimPart and AimPart.Position then
        print("hooked and aimpart found")
        shotdata.dir = (AimPart.Position - shotdata.origin).Unit * shotdata.dir.Magnitude
    end

    return OldProjectileShot(shotdata, barrel)
end)

local OldHitscanShot
OldHitscanShot = hookfunction(HitscanShot, function(shotdata, barrel, hitInstance)
    print("hooked (hitscan)")

    const AimPart = Utils["Aimbot"].GetClosest()
    if AimPart and AimPart.Position then
        print("hooked and aimpart found")
        shotdata.hitPos = AimPart.Position
        shotdata.hitNormal = (shotdata.origin - AimPart.Position).Unit
        hitInstance = AimPart
    end

    return OldHitscanShot(shotdata, barrel, hitInstance)
end)

--[[
    GunRemotes.Network.packets.C2SProjectileShot.Fire({
        mode = u15,
        origin = child.Position,
        dir = v177,
        velocity = u14[u15].ProjectileVelocity / 10
    }, child);

    GunRemotes.Network.packets.C2SHitscanShot.Fire({
        mode = u15,
        origin = child.Position,
        hitPos = v186,
        hitNormal = v195,
        sendGfx = p185 or false
    }, child, v188 and v188.Instance or nil);
]]