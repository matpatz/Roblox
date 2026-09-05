-- // Services
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Players = game:GetService("Players")

-- // Modules
local BulletRaycast = require(ReplicatedStorage.Modules.BulletRaycast)

-- // Variables
local Init = BulletRaycast.Initiate

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
    TeamCheck = true,
    AimPart = "Head",
    Visible = true,
    EntityLists = {
        {}
    }
}

local Aimbot = loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/Modules/Aimbot/main.lua"))()

Utils["Aimbot"].GetTargets = function(): { Instance }
	local Enemies: { Instance } = {}

	for _, Player in Players:GetPlayers() do
		if Player == LocalPlayer then
			continue
		end
		if not Player.Character then
			continue
		end

		table.insert(Enemies, Player)
	end

	return Enemies
end

Utils["Aimbot"].GetClosest = function(): (BasePart?)
    config["Origin"] = HumanoidRootPart.Position

    config["EntityList"] = Utils["Aimbot"].GetTargets()

    local _, AimPart = Aimbot.GetClosest(config)

    return AimPart
end

if isfunctionhooked(Init) then
    restorefunction(Init)
end

-- type InitiateFunction = (Vector3, Vector3, number, {Instance}) -> (Vector3?, Instance?, Vector3?, {{Vector3, Instance, Vector3}}, Enum.Material?)

local Old; Old = hookfunction(Init, function(p16, p17, p18, p19)
    const AimPart = Utils["Aimbot"].GetClosest()
    if AimPart then
        p17 = (AimPart.Position - p16).Unit
    end
    return Old(p16, p17, p18, p19)
end)