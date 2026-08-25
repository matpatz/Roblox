-- ai slop, kinda

-- // Services
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Players = game:GetService("Players")

-- // LocalPlayer
const LocalPlayer = Players.LocalPlayer
const PlayerScripts = LocalPlayer.PlayerScripts

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
local u1 = {} -- script

local WeaponClient = PlayerScripts.WeaponClient
local WeaponScript = WeaponClient:QueryDescendants(":has(> #BackupSounds):has(> #LocalModules):has(> #Modules)")[1]

local BandageFunc = getsenv(WeaponScript)["_G"].BandageFunc
u1 = debug.getupvalue(BandageFunc, 1)

local FireShot = u1.FireShot -- from the Combat script
if not FireShot then
    error("no FireShot")
end

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
	SilentAim = {
		Enabled = true,
		Range = 600,
		AimPart = "Head",
		TeamCheck = true,
		WallCheck = true,
	},
}

const Aimbot = loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/Modules/Aimbot/main.lua"))()

-- // Utils
Utils.GetTargets = function(): { Instance }
	local Enemies: { Instance } = {}

	for _, Player in Players:GetPlayers() do
		if Player == LocalPlayer then
			continue
		end
		if not Player.Character then
			continue
		end

		if config.SilentAim.TeamCheck and u1._isTeammate then
			local IsTeammate = u1._isTeammate(Player)
			if IsTeammate then
				continue
			end
		end

		table.insert(Enemies, Player)
	end

	return Enemies
end

-- ignore our weapon and viewmodel
Utils.ShotIgnore = function(): { Instance }
	local Ignore: { Instance } = {}

	local Vars = u1.Vars
	local Assets = Vars and Vars.Assets
	if Assets then
		if Assets.GunModel then
			table.insert(Ignore, Assets.GunModel)
		end
		if Assets.Viewmodel then
			table.insert(Ignore, Assets.Viewmodel)
		end
	end

	return Ignore
end

Utils["Aimbot"].GetClosest = function(): BasePart?
	local Muzzle = u1.Vars.muzzle or HumanoidRootPart
	local AimConfig = {
		Origin = Muzzle,
		Range = config.SilentAim.Range,
		TeamCheck = false, -- pre filtered
		AimPart = config.SilentAim.AimPart,
		Visible = config.SilentAim.WallCheck,
		Ignore = Utils.ShotIgnore(),
		EntityLists = { Utils.GetTargets() },
	}

	local Target, AimPart = Aimbot.GetClosest(AimConfig)
	if Target and AimPart then
		return AimPart
	end

	return nil
end

local Old; Old = hookfunction(u1.randomConeDirection, function(Direction: Vector3, SpreadDegrees: number): Vector3
	if config.SilentAim.Enabled then
		local AimPart = Utils["Aimbot"].GetClosest()
		local Muzzle = u1.Vars.muzzle

		if AimPart and Muzzle then
			return (AimPart.Position - Muzzle.CFrame.Position).Unit
		end
	end

	return Old(Direction, SpreadDegrees)
end)