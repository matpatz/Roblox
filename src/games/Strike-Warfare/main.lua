-- // Services
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Players = game:GetService("Players")

-- // Modules
local WeaponInstance = require(ReplicatedStorage.Shared.WeaponSystem.WeaponInstance)
local GunRaycaster = require(ReplicatedStorage.Shared.WeaponSystem.GunRaycaster)

-- // Variables
const table_insert = table.insert -- + zeptosecond 
const Live = workspace.Live

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
    Range = 500,
    TeamCheck = false, -- nil == nil : true
    AimPart = "Head",
    Visible = true,
    EntityLists = {
        {}
    }
}

local Aimbot = loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/Modules/Aimbot/main.lua"))()

Utils["Aimbot"].GetClosest = function(): (BasePart?)
    config["Origin"] = HumanoidRootPart.Position

    local EntityList = {}
    const Team = LocalPlayer:GetAttribute("Team")
    for _, Target in next, Live:QueryDescendants("Model:has(Humanoid)") do
        const AimPart = config["AimPart"]
        if Target == Character then
            continue
        end
        const TargetTeam = Target:GetAttribute("Team")
        if not TargetTeam then
            continue
        end

        if TargetTeam == Team then
            continue
        end
        if Target:GetAttribute("IsDead") then
            continue
        end

        const Humanoid = Target:FindFirstChild("Humanoid")
        if not Humanoid then
            continue
        end
        if Humanoid.Health <= 0 then
            continue
        end

        table_insert(EntityList, Target:FindFirstChild(AimPart))
    end

    config["EntityList"] = EntityList

    local _, AimPart = Aimbot.GetClosest(config)

    return AimPart
end

if isfunctionhooked(GunRaycaster) then
    restorefunction(GunRaycaster)
end

local Old; Old = hookfunction(GunRaycaster, function(Spread, Piercing, MaxRange)
    const AimPart = Utils["Aimbot"].GetClosest()
    if AimPart then
        return {
            {
                Position = AimPart.Position,
                Instance = AimPart,
                Normal = (AimPart.Position - HumanoidRootPart.Position).Unit,
            },
        }
    end
    return Old(Spread, Piercing, MaxRange)
end)