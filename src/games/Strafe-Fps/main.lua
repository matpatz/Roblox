-- ai slop

-- // Services
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Players = game:GetService("Players")

-- // Modules
const Handler = require(ReplicatedStorage.Classes.Handler)
const GameState = require(ReplicatedStorage.Classes.UserInterface.ReactApp.GameState)

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

local Aimbot = loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/Modules/Aimbot/v1/main.lua"))()

-- // Utils

Utils["Aimbot"].GetTargets = function(): { Instance }
	local Enemies: { Instance } = {}

	-- The game does not use Player.Team; sides live in GameState.
	local function IsTeammate(Model: Model): boolean
		local BotUniqueId = Model:GetAttribute("BotUniqueId")
		if BotUniqueId then
			return GameState.isTeammate(BotUniqueId)
		end

		local TargetPlayer = Players:GetPlayerFromCharacter(Model)
		if not TargetPlayer then
			return false
		end

		return GameState.isTeammate(TargetPlayer.UserId)
	end

	local function AddCharacter(Model: Model?)
		if not Model then
			return
		end

		local Humanoid = Model:FindFirstChildOfClass("Humanoid")
		if not Humanoid or Humanoid.Health <= 0 then
			return
		end

		if config.SilentAim.TeamCheck and IsTeammate(Model) then
			return
		end

		table.insert(Enemies, Model)
	end

	for _, Player in Players:GetPlayers() do
		if Player == LocalPlayer then
			continue
		end

		AddCharacter(Player.Character)
	end

	-- Bots, same source the game's own AimAssist uses
	local NPCS = workspace:FindFirstChild("NPCS")
	if NPCS then
		for _, Model in NPCS:GetChildren() do
			if Model:IsA("Model") then
				AddCharacter(Model)
			end
		end
	end

	return Enemies
end

local aimconfig = {
    Origin,
    Range = config.SilentAim.Range,
    TeamCheck = false, -- pre filtered in GetTargets
    AimPart = config.SilentAim.AimPart,
    Visible = config.SilentAim.WallCheck,
    EntityLists = {},
}

Utils["Aimbot"].GetClosest = function(): BasePart?
    aimconfig["Origin"] = HumanoidRootPart.Position
    aimconfig["EntityLists"] = {
        Utils["Aimbot"].GetTargets()
    }

	local _, AimPart = Aimbot.GetTarget(aimconfig)
	return AimPart
end

-- // Core

if isfunctionhooked(Handler.fireHitscanShot) then
	restorefunction(Handler.fireHitscanShot)
end

-- // Handler:fireHitscanShot reads its origin and direction straight off the gun's
-- // camera, so aiming that camera at the target for the length of the call lands
-- // the shot on them. Nothing renders in between and it is restored on return,
-- // so the view never moves.
local OldFireHitscanShot
OldFireHitscanShot = hookfunction(Handler.fireHitscanShot, function(Self, GunModule)
	if not config.SilentAim.Enabled then
		return OldFireHitscanShot(Self, GunModule)
	end

	const AimPart = Utils["Aimbot"].GetClosest()
	if not AimPart then
		return OldFireHitscanShot(Self, GunModule)
	end

	const Camera = Self.camera or workspace.CurrentCamera
	const OriginalCFrame = Camera.CFrame

	Camera.CFrame = CFrame.lookAt(OriginalCFrame.Position, AimPart.Position)

	const Results = table.pack(pcall(OldFireHitscanShot, Self, GunModule))

	Camera.CFrame = OriginalCFrame

	if not Results[1] then
		error(Results[2], 0)
	end

	return table.unpack(Results, 2, Results.n)
end)
