-- // Services
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Players = game:GetService("Players")

-- // Modules
const SE_Client = getsenv(Players.LocalPlayer.PlayerGui.SE_Client)

-- // Variables
local BulletRaycast = SE_Client.BulletRaycast 

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

Utils["Aimbot"].ValidateTarget = function(Target: Instance): boolean
	if Target == Character then
		return false
	end

	const AimPart = Target:FindFirstChild(config["SilentAim"].AimPart)
	if not AimPart then
		return false
	end

	const TargetHumanoid = Target:FindFirstChildOfClass("Humanoid")
	if not TargetHumanoid or TargetHumanoid.Health <= 0 then
		return false
	end

	if config.SilentAim.TeamCheck then
		const TargetPlayer = Players:GetPlayerFromCharacter(Target)
		if TargetPlayer and TargetPlayer.Team == LocalPlayer.Team then
			return false
		end
	end

	return true
end

Utils["Aimbot"].GetTargets = function(): { Instance }
	const Targets: { Instance } = {}

	for _, Target in workspace:QueryDescendants("Model:has(Humanoid)") do
		if Utils["Aimbot"].ValidateTarget(Target) then
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

if isfunctionhooked(BulletRaycast) then
    restorefunction(BulletRaycast)
end

local Old; Old = hookfunction(BulletRaycast, function(Origin, LookVector, Ignore)
    if config.SilentAim.Enabled then
        const Target, AimPart = Utils["Aimbot"].GetClosest()
        if Target and AimPart then
            const RayOrigin = Origin or workspace.CurrentCamera.CFrame.Position
            LookVector = AimPart.Position - RayOrigin
        end
    end
    return Old(Origin, LookVector, Ignore)
end)