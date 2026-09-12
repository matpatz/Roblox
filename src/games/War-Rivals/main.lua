-- ai slop

-- // Services
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Players = game:GetService("Players")
const CollectionService = game:GetService("CollectionService")

-- // Modules
const Knit = require(ReplicatedStorage.Packages.Knit)
const Raycast = require(ReplicatedStorage.Shared.Libraries.Raycast)
const Teams = require(ReplicatedStorage.Shared.Aeon.Combat.Teams)

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

-- // Enemies come from the client ActorController: every non-local actor whose
-- // rig owns the configured aim part. Covers PvP players and NPC/mob actors.
Utils["Aimbot"].GetTargets = function(): { Instance }
	const Targets: { Instance } = {}
	-- // Same team store Teams:GetActorTeam falls back to for owned actors.
	const LocalTeam = if config.SilentAim.TeamCheck and LocalPlayer.Team then LocalPlayer.Team.Name else nil

	for _, Actor in Knit.GetController("ActorController").Actors do
		if Actor.Owner == LocalPlayer then
			continue
		end
		if Actor.IsAlive and not Actor:IsAlive() then
			continue
		end

		const Rig = Actor.AnimatedRig or Actor.Subject
		if not Rig or not Rig:FindFirstChild(config.SilentAim.AimPart, true) then
			continue
		end

		-- Team comes from the actor (Subject "Team" attribute, else Owner.Team).
		-- A teamless actor is not a teammate, so it stays a valid target.
		if config.SilentAim.TeamCheck then
			const ActorTeam = Teams:GetActorTeam(Actor)
			if ActorTeam ~= nil and ActorTeam == LocalTeam then
				continue
			end
		end

		if config.SilentAim.WallCheck and not Utils["Aimbot"].IsVisible(HumanoidRootPart.Position, Rig) then
			continue
		end

		table.insert(Targets, Rig)
	end

	return Targets
end

-- // Mirrors the game's own bullet world-hit rule (Raycast.FireRayWithoutTargeting):
-- // a part only blocks the shot when it CanCollide and is not tagged BulletPass.
-- // A plain workspace:Raycast also stops on BulletPass barriers, non-colliding
-- // props and other actors' limbs, which made WallCheck drop valid targets.
-- // (Rig parts - yours included - are all CanCollide = false, so no rig ignore
-- // list is needed beyond the CharacterController itself.)
Utils["Aimbot"].IsVisible = function(OriginPosition: Vector3, Target: Instance): boolean
	const AimPart = Target:FindFirstChild(config.SilentAim.AimPart, true)
	if not AimPart then
		return false
	end

	const Filter: { Instance } = { Character, workspace.CurrentCamera, Target }

	const RaycastParams = RaycastParams.new()
	RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
	RaycastParams.FilterDescendantsInstances = Filter
	RaycastParams.IgnoreWater = true

	local From = OriginPosition
	local Delta = AimPart.Position - OriginPosition

	for _ = 1, 8 do
		const Result = workspace:Raycast(From, Delta, RaycastParams)
		if not Result then
			return true
		end
		if Result.Instance.CanCollide and not CollectionService:HasTag(Result.Instance, "BulletPass") then
			return false
		end

		table.insert(Filter, Result.Instance)

		const Remaining = Delta.Magnitude - (Result.Position - From).Magnitude - 0.05
		if Remaining <= 0 then
			return true
		end

		From = Result.Position + Delta.Unit * 0.05
		Delta = Delta.Unit * Remaining
	end

	return true
end

local aimconfig = {
    Origin = Vector3.zero,
    Range = config.SilentAim.Range,
    TeamCheck = false, -- pre filtered in GetTargets
    AimPart = config.SilentAim.AimPart,
    Visible = false, -- wall check is done in GetTargets (see Utils["Aimbot"].IsVisible)
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

const FireRayWithTargeting = Raycast.FireRayWithTargeting
const FireRayWithoutTargeting = Raycast.FireRayWithoutTargeting

if isfunctionhooked(FireRayWithTargeting) then
	restorefunction(FireRayWithTargeting)
end
if isfunctionhooked(FireRayWithoutTargeting) then
	restorefunction(FireRayWithoutTargeting)
end

-- // Every shot resolves its hit through Raycast:FireRay*Targeting. Returning
-- // the enemy's aim part here lands the reported hit on them while the camera
-- // keeps pointing wherever the player is looking.
local function ResolveShot(Origin: Vector3?): (BasePart?, Vector3?, Vector3?, Enum.Material?)
	if not config.SilentAim.Enabled then
		return nil
	end

	const AimPart = Utils["Aimbot"].GetClosest()
	if not AimPart then
		return nil
	end

	const Normal = if typeof(Origin) == "Vector3" then (Origin - AimPart.Position).Unit else AimPart.CFrame.LookVector
	return AimPart, AimPart.Position, Normal, AimPart.Material
end

local OldWithTargeting
OldWithTargeting = hookfunction(FireRayWithTargeting, function(self, Origin: Vector3, Direction: Vector3, Subjects, Ignore, Weapon)
	const AimPart, Position, Normal, Material = ResolveShot(Origin)
	if AimPart then
		return AimPart, Position, Normal, Material
	end

	return OldWithTargeting(self, Origin, Direction, Subjects, Ignore, Weapon)
end)

local OldWithoutTargeting
OldWithoutTargeting = hookfunction(FireRayWithoutTargeting, function(self, Origin: Vector3, Direction: Vector3, Subjects, Ignore)
	const AimPart, Position, Normal, Material = ResolveShot(Origin)
	if AimPart then
		return AimPart, Position, Normal, Material
	end

	return OldWithoutTargeting(self, Origin, Direction, Subjects, Ignore)
end)
