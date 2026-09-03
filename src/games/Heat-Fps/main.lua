-- // Services
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Players = game:GetService("Players")

-- // Modules
local SharedGunClient = require(ReplicatedStorage.Source.Combat.SharedGunClient)

-- // Variables
const GetSafeShotOrigin = SharedGunClient.GetSafeShotOrigin
local GetShotDirection = SharedGunClient.GetShotDirection

const IsValidPredictedCharacterHit = SharedGunClient.IsValidPredictedCharacterHit

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

local Aimbot = loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/Modules/Aimbot/main.lua"))()

-- // Utils

local GunSelf = { Player = LocalPlayer }

Utils["Aimbot"].IsValidEnemyHit = function(Target: Instance): boolean
	const AimPart = Target:FindFirstChild(config["SilentAim"].AimPart)
	if not AimPart then
		return false
	end
	return IsValidPredictedCharacterHit(GunSelf, { hitPart = AimPart }) == true
end

Utils["Aimbot"].GetTargets = function(): { Instance }
	const Targets: { Instance } = {}

	for _, Target in workspace:QueryDescendants("Model:has(Humanoid)") do
		if config.SilentAim.TeamCheck then
			if Utils["Aimbot"].IsValidEnemyHit(Target) then
				table.insert(Targets, Target)
			end
		else
			if Target == Character then
				continue
			end
			const TargetHumanoid = Target:FindFirstChildOfClass("Humanoid")
			if not TargetHumanoid or TargetHumanoid.Health <= 0 then
				continue
			end
			table.insert(Targets, Target)
		end
	end

	return Targets
end

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
        Utils["Aimbot"].GetTargets()
    }

	const Target, AimPart = Aimbot.GetClosest(aimconfig)
	if not Target or not AimPart then
		return nil
	end

	return Target, AimPart
end

-- // Core

if isfunctionhooked(GetShotDirection) then
    restorefunction(GetShotDirection)
end

local Old; Old = hookfunction(GetShotDirection, function(self, LookVector): Vector3
    if config.SilentAim.Enabled then
        const Target, AimPart = Utils["Aimbot"].GetClosest()
        if Target and AimPart then
            const Character = self.Player and self.Player.Character
            const ShotOrigin = if Character then GetSafeShotOrigin(self, Character, LookVector) else HumanoidRootPart.Position
            return (AimPart.Position - ShotOrigin).Unit
        end
    end
    return Old(self, LookVector)
end)