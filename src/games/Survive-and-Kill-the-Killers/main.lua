-- Only tested on Endless mode, and only works for PVE

-- // Services
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Players = game:GetService("Players")

-- // Modules
local Utilities = require(ReplicatedStorage.Utilities)
local Weapons = require(ReplicatedStorage.Weapon)

-- // Workspace
const Killers = workspace.Killers

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
    Origin = Vector3.zero,
    Range = 400,
    TeamCheck = false,
    AimPart = "HumanoidRootPart",
    Visible = false,
    EntityLists = {
        Killers:GetChildren()
    },
}

const Aimbot = loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/Modules/Aimbot/main.lua"))()

Utils["Aimbot"].GetClosest = function(): (BasePart?)
    const Target, AimPart = Aimbot.GetClosest(config)

    return AimPart
end

--[[ Called line ~1500 of Weapons.lua
local v266, v267 = Utilities:cast_ray(v265, Head.Position, v260.Position - Head.Position, u255.target_ray_callback);
]]

-- Silent Aim
local old; old = hookfunction(Utilities["cast_ray"], function(p63, p64, p65, p66, p67)
    config["Origin"] = HumanoidRootPart.Position
    config["EntityLists"] = { Killers:GetChildren() }

    if p66.Magnitude > 30 then
        const AimPart = Utils["Aimbot"].GetClosest()

        if AimPart then
            const Direction = (AimPart.Position - p65).Unit * (AimPart.Position - p65).Magnitude
            return old(p63, p64, p65, Direction, p67)
        end
    end

    return old(p63, p64, p65, p66, p67)
end)

-- Wallbang
local missile_hit; missile_hit = hookfunction(Weapons["missile_hit"], function(self, part, moment, hit, missilePosition)
    if not self.is_grenade and hit and self.missile_check then
        local Humanoid = self:missile_check(hit)

        if not Humanoid then
            return
        end
    end

    return missile_hit(self, part, moment, hit, missilePosition)
end)