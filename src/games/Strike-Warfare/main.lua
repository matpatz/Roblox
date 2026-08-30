-- // Services
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Players = game:GetService("Players")

-- // Modules
local WeaponInstance = require(ReplicatedStorage.Shared.WeaponSystem.WeaponInstance)
local GunRaycaster = require(ReplicatedStorage.Shared.WeaponSystem.GunRaycaster)

-- // Variables
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
    for _, Player in next, Players:GetPlayers() do
        if Player == LocalPlayer then
            continue
        end
        
        if Player:GetAttribute("Team") == Team then
            continue
        end
        if Player:GetAttribute("IsDead") then
            continue
        end

        table_insert(EntityList, Player)
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