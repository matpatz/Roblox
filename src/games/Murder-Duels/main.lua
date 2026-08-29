-- hi im the worst code ever written
-- AI SLOPOP SLOPPPPP

-- // Services
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Players = game:GetService("Players")

-- // Modules
local AimMagnetism = require(ReplicatedStorage:WaitForChild("Extensions"):WaitForChild("AimMagnetism"))

-- // Variables

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
	SilentAim = {
		Enabled = true,
		Range = 500,
		AimPart = "Head",
		WallCheck = false, -- camera raycast drops targets behind cover; off = reliable
		Debug = true,
	},
}

const Aimbot = loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/Modules/Aimbot/main.lua"))()

-- // Utils
Utils.GetTargets = function(): { Instance }
	const MatchSide = LocalPlayer:GetAttribute("MatchSide")
	const HasMatchSide = type(MatchSide) == "string"
	const Targets: { Instance } = {}

	local function IsLiving(Character: Instance?): boolean
		const Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
		return Humanoid ~= nil and Humanoid.Health > 0
	end

	local function IsTeammate(Player: Player): boolean
		const PlayerSide = Player:GetAttribute("MatchSide")
		if HasMatchSide and type(PlayerSide) == "string" then
			return PlayerSide == MatchSide
		end
		return Player.Team == LocalPlayer.Team
	end

	local function SameSide(Side: any?): boolean
		return HasMatchSide and type(Side) == "string" and Side == MatchSide
	end

	-- enemy players
	for _, Player in Players:GetPlayers() do
		if Player == LocalPlayer then
			continue
		end
		if not IsLiving(Player.Character) then
			continue
		end
		if IsTeammate(Player) then
			continue
		end

		table.insert(Targets, Player)
	end

	-- enemy bots / decoys
	if not HasMatchSide then
		return Targets
	end

	const Characters = workspace:FindFirstChild("Characters")
	if not Characters then
		return Targets
	end

	for _, Child in Characters:GetChildren() do
		if not Child:IsA("Model") then
			continue
		end
		if Child.Name:sub(1, 7) == "Replay" then
			continue
		end
		if not IsLiving(Child) then
			continue
		end
		if SameSide(Child:GetAttribute("MatchSide")) then
			continue
		end
		if not (Child:GetAttribute("BotMatchBot") == true or Child:GetAttribute("Decoy") == true) then
			continue
		end

		table.insert(Targets, Child)
	end

	return Targets
end

Utils["Aimbot"].GetClosest = function(): (BasePart?)
	local AimConfig = {
		Origin = workspace.CurrentCamera.CFrame.Position,
		Range = config.SilentAim.Range,
		TeamCheck = false, -- pre filtered
		AimPart = config.SilentAim.AimPart,
		Visible = config.SilentAim.WallCheck,
		EntityLists = { Utils.GetTargets() },
	}

	const Target, AimPart = Aimbot.GetClosest(AimConfig)
	if not (Target and AimPart) then
		return nil
	end

	return AimPart
end

-- // Silent Aim
if isfunctionhooked(AimMagnetism.getSecuredScreenPoint) then
	restorefunction(AimMagnetism.getSecuredScreenPoint)
end

local Old
Old = hookfunction(AimMagnetism.getSecuredScreenPoint, newlclosure(function(Self, OnEnemy, ...)
	if not config.SilentAim.Enabled then
		return Old(Self, OnEnemy, ...)
	end

	const Ok, AimPart = pcall(Utils["Aimbot"].GetClosest)
	if not Ok or not AimPart then
		return Old(Self, OnEnemy, ...)
	end

	const Screen = workspace.CurrentCamera:WorldToViewportPoint(AimPart.Position)
	if Screen.Z <= 0 then
		return Old(Self, OnEnemy, ...)
	end

	if config.SilentAim.Debug then
		const TargetModel = AimPart:FindFirstAncestorOfClass("Model")
		warn("[SilentAim] ssp -> " .. tostring(TargetModel and TargetModel.Name or AimPart.Name))
	end

	return Vector2.new(Screen.X, Screen.Y)
end))
