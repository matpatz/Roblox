local aimbot = {}

local Helpers = loadstring(game:HttpGet(
	"https://roblox-alpha-murex.vercel.app/src/Modules/Aimbot/v1/Helpers.lua"
))()
assert(Helpers, "Aimbot: failed to load Helpers.lua")

const Players = game:GetService("Players")
const LocalPlayer = Players.LocalPlayer

-- Types
type OriginType = CFrame | Vector3 | BasePart
type AimPartType = string | { string } | Instance
type IgnoreType = Instance | { Instance }
type BlacklistType = Instance | string | { Instance | string }
type EntityListType = { Instance }
type EntityListsType = { { Instance } } | { [string]: { Instance } }

export type AimbotConfig = {
	Origin: OriginType?,
	Range: number?,
	MinDistance: number?,
	TeamCheck: boolean?,
	AimPart: AimPartType?,
	Visible: boolean?,
	Ignore: IgnoreType?,
	Blacklist: BlacklistType?,
	EntityList: EntityListType?,
	EntityLists: EntityListsType?,
	MaxTargets: number?,
}

function aimbot.GetOrigin(Origin: OriginType): Vector3
	return Helpers["Get"].Origin(Origin)
end

function aimbot.GetCharacter(Target: Instance): Model?
	return Helpers["Get"].Character(Target)
end

function aimbot.GetAimPart(Target: Instance, AimPart: AimPartType?): BasePart?
	return Helpers["Get"].AimPart(Target, AimPart)
end

function aimbot.Range(Origin: OriginType, TargetPart: BasePart): number
	return (Helpers["Get"].Origin(Origin) - TargetPart.Position).Magnitude
end

function aimbot.IsVisible(Origin: OriginType, Target: Instance, Config: AimbotConfig?): boolean
	assert(Config, "Aimbot.IsVisible: Config is required")
	return Helpers["Is"].LineOfSight(Helpers["Get"].Origin(Origin), Target, Config)
end

function aimbot.Raycast(Origin: OriginType, Target: Instance, Config: AimbotConfig?): Vector3?
	assert(Config, "Aimbot.Raycast: Config is required")
	const OriginPosition = Helpers["Get"].Origin(Origin)

	const AimPart = Helpers["Get"].AimPart(Target, Config.AimPart)
	if not AimPart then
		return nil
	end

	const RaycastParams = RaycastParams.new()
	RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
	RaycastParams.FilterDescendantsInstances = Helpers["Get"].IgnoreList(Target, Config)

	const Direction = AimPart.Position - OriginPosition
	const Result = workspace:Raycast(OriginPosition, Direction, RaycastParams)
	if Result then
		return Result.Position
	end
	return OriginPosition + Direction
end

function aimbot.GetTargets(Config: AimbotConfig): { Instance }
	if Config.Origin == nil then
		error("Aimbot.GetTargets: Config.Origin is required")
	end
	const OriginPosition = Helpers["Get"].Origin(Config.Origin)
	const MaxTargets = Config.MaxTargets or 1e9
	const Targets: { Instance } = {}

	const Candidates = Helpers["Collect"].TargetLists(Config)
	if Candidates ~= nil then
		for _, Object in Candidates do
			if not Helpers["Validate"].Target(Object, Config, OriginPosition) then
				continue
			end
			table.insert(Targets, Object)
			if #Targets >= MaxTargets then
				break
			end
		end
		return Targets
	end

	-- No explicit lists: scan other players.
	for _, Object in Players:GetPlayers() do
		if Object == LocalPlayer then
			continue
		end
		if not Helpers["Validate"].Target(Object, Config, OriginPosition) then
			continue
		end
		table.insert(Targets, Object)
		if #Targets >= MaxTargets then
			break
		end
	end

	return Targets
end

function aimbot.GetTarget(Config: AimbotConfig): (Instance?, BasePart?)
	const Targets = aimbot.GetTargets(Config)
	const OriginPosition = Helpers["Get"].Origin(Config.Origin)

	local Closest: Instance? = nil
	local ClosestPart: BasePart? = nil
	local ClosestDistance = math.huge

	for _, Target in Targets do
		const AimPart = Helpers["Get"].AimPart(Target, Config.AimPart)
		if not AimPart then
			continue
		end
		const Distance = (OriginPosition - AimPart.Position).Magnitude
		if Distance < ClosestDistance then
			ClosestDistance = Distance
			Closest = Target
			ClosestPart = AimPart
		end
	end

	return Closest, ClosestPart
end

return aimbot