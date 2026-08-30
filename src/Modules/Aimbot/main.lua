-- Aimbot Module
-- src/Modules/Aimbot/main.lua
-- Config-table based aimbot: origin / range / teamcheck / aimpart / visibility / blacklist.

local aimbot = {}

const Players = game:GetService("Players")
const LocalPlayer = Players.LocalPlayer

-- Types

-- Origin can be a CFrame, a Vector3, or any BasePart
-- (HumanoidRootPart, camera, muzzle part, ...).
type OriginType = CFrame | Vector3 | BasePart

-- AimPart can be a part name, a list of names (random pick), or an actual BasePart.
type AimPartType = string | { string } | Instance

-- Ignore can be a single Instance or a list of Instances.
type IgnoreType = Instance | { Instance }

-- Blacklist can be a single Instance or a list of Instances
-- (Players, Models, parts) that should never be targeted.
type BlacklistType = Instance | { Instance }

-- A single target list (Models/Players/Parts).
type EntityListType = { Instance }

-- Multiple target lists: an array of lists, or named lists
-- (e.g. { NPCs = ..., Players = ... }). All of them are combined.
type EntityListsType = { { Instance } } | { [string]: { Instance } }

-- One config table instead of 30 positional parameters.
export type AimbotConfig = {
	-- Where the aimbot aims from (CFrame, Vector3, or BasePart like HumanoidRootPart).
	Origin: OriginType?,
	-- Maximum targeting distance.
	Range: number?,
	-- Minimum targeting distance.
	MinDistance: number?,
	-- Skip players on the same team as the local player.
	TeamCheck: boolean?,
	-- Which part to aim at: "Head", "HumanoidRootPart", "Random",
	-- { "Head", "Torso" } (random pick), or an actual BasePart.
	AimPart: AimPartType?,
	-- Only keep targets with line-of-sight (uses Raycast).
	Visible: boolean?,
	-- Extra parts/models to ignore during raycast visibility checks.
	Ignore: IgnoreType?,
	-- Players/instances to never target (single or list).
	Blacklist: BlacklistType?,
	-- One explicit target list (Models/Players/Parts).
	EntityList: EntityListType?,
	-- Multiple explicit target lists (NPCs, players, ...) to combine.
	-- If both EntityList and EntityLists are nil, scans other players.
	EntityLists: EntityListsType?,
	-- Cap on how many targets GetTargets returns.
	MaxTargets: number?,
}

-- Fully resolved config (defaults filled in, every field type-checked).
type ResolvedConfig = {
	Origin: OriginType?,
	Range: number,
	MinDistance: number,
	TeamCheck: boolean,
	AimPart: AimPartType?,
	Visible: boolean,
	Ignore: IgnoreType?,
	Blacklist: BlacklistType?,
	EntityList: EntityListType?,
	EntityLists: EntityListsType?,
	MaxTargets: number,
}

-- Defaults
const DefaultConfig = {
	Range = 200,
	MinDistance = 0,
	TeamCheck = false,
	AimPart = "HumanoidRootPart",
	Visible = false,
	MaxTargets = 1e9,
}

-- Validation and type checking

-- Resolve any Origin input into a Vector3 position.
local function GetOrigin(Origin: OriginType): Vector3
	const Kind = typeof(Origin)
	if Kind == "CFrame" then
		return (Origin :: CFrame).Position
	elseif Kind == "Vector3" then
		return Origin :: Vector3
	elseif Kind == "Instance" then
		const Part = Origin :: Instance
		if Part:IsA("BasePart") then
			return Part.Position
		end
		error("Aimbot.GetOrigin: origin instance must be a BasePart, got " .. Part.ClassName)
	end
	error("Aimbot.GetOrigin: expected CFrame, Vector3, or BasePart, got " .. tostring(Kind))
end

local function ValidateNumber(Value: any?, Name: string, Fallback: number): number
	if Value == nil then
		return Fallback
	end
	assert(type(Value) == "number", "Aimbot: " .. Name .. " must be a number, got " .. type(Value))
	return Value
end

local function ValidateBoolean(Value: any?, Name: string, Fallback: boolean): boolean
	if Value == nil then
		return Fallback
	end
	assert(type(Value) == "boolean", "Aimbot: " .. Name .. " must be a boolean, got " .. type(Value))
	return Value
end

-- Merge a config table over the defaults and type-check every field.
local function NormalizeConfig(Config: AimbotConfig?): ResolvedConfig
	local Normalized: ResolvedConfig = {
		Range = DefaultConfig.Range,
		MinDistance = DefaultConfig.MinDistance,
		TeamCheck = DefaultConfig.TeamCheck,
		AimPart = DefaultConfig.AimPart,
		Visible = DefaultConfig.Visible,
		MaxTargets = DefaultConfig.MaxTargets,
	}

	if not Config then
		return Normalized
	end

	-- Origin is validated by resolving it (also catches bad instances).
	if Config.Origin ~= nil then
		GetOrigin(Config.Origin)
		Normalized.Origin = Config.Origin
	end
	Normalized.Range = ValidateNumber(Config.Range, "Range", DefaultConfig.Range)
	Normalized.MinDistance = ValidateNumber(Config.MinDistance, "MinDistance", DefaultConfig.MinDistance)
	Normalized.TeamCheck = ValidateBoolean(Config.TeamCheck, "TeamCheck", DefaultConfig.TeamCheck)
	Normalized.Visible = ValidateBoolean(Config.Visible, "Visible", DefaultConfig.Visible)
	Normalized.MaxTargets = ValidateNumber(Config.MaxTargets, "MaxTargets", DefaultConfig.MaxTargets)
	Normalized.AimPart = Config.AimPart
	Normalized.Ignore = Config.Ignore
	Normalized.Blacklist = Config.Blacklist
	if Config.EntityList ~= nil then
		assert(type(Config.EntityList) == "table", "Aimbot: EntityList must be a table of targets")
		Normalized.EntityList = Config.EntityList
	end
	if Config.EntityLists ~= nil then
		assert(type(Config.EntityLists) == "table", "Aimbot: EntityLists must be a table of target lists")
		Normalized.EntityLists = Config.EntityLists
	end

	return Normalized
end

-- Target helpers

-- Resolve a target (Player, Model, or BasePart) into a character Model.
local function GetCharacter(Target: Instance): Model?
	if Target:IsA("Player") then
		return Target.Character
	elseif Target:IsA("Model") then
		return Target
	elseif Target:IsA("BasePart") and Target.Parent then
		return Target.Parent :: Model
	end
	return nil
end

-- Resolve which part to aim at for a target based on the AimPart config.
local function GetAimPart(Target: Instance, AimPart: AimPartType?): BasePart?
	const Character = GetCharacter(Target)
	if not Character then
		return nil
	end

	-- Direct BasePart instance.
	if typeof(AimPart) == "Instance" then
		const Part = AimPart :: Instance
		if Part:IsA("BasePart") and Part:IsDescendantOf(Character) then
			return Part
		end
		return nil
	end

	-- "Random": pick any BasePart of the character.
	if AimPart == "Random" then
		local Candidates: { BasePart } = {}
		for _, Descendant in Character:GetDescendants() do
			if Descendant:IsA("BasePart") then
				table.insert(Candidates, Descendant)
			end
		end
		if #Candidates == 0 then
			return nil
		end
		return Candidates[math.random(#Candidates)]
	end

	-- List of names: pick one at random.
	if type(AimPart) == "table" then
		const Names = AimPart :: { string }
		if #Names == 0 then
			return nil
		end
		return Character:FindFirstChild(Names[math.random(#Names)], true) :: BasePart?
	end

	-- Single part name (falls back to the default).
	const Name = if type(AimPart) == "string" then AimPart :: string else "HumanoidRootPart"
	return Character:FindFirstChild(Name, true) :: BasePart?
end

-- Team check: when enabled, same-team players are not valid targets.
-- Resolves Models/BaseParts to their owning player, so TeamCheck still works
-- when callers pass character Models instead of Player objects.
local function IsEnemy(Target: Instance, TeamCheck: boolean): boolean
	if not TeamCheck then
		return true
	end

	-- Resolve Player | Model | BasePart to the owning player (if any).
	local TargetPlayer: Player? = nil
	if Target:IsA("Player") then
		TargetPlayer = Target :: Player
	else
		const Character = GetCharacter(Target)
		if Character then
			-- pcall: GetPlayerFromCharacter can fail on NPCs/non-character models.
			local Success, Player = pcall(Players.GetPlayerFromCharacter, Players, Character)
			if Success then
				TargetPlayer = Player
			end
		end
	end

	if not TargetPlayer then
		-- NPCs, bots, and non-player targets are always valid enemies.
		return true
	end

	return TargetPlayer.Team ~= LocalPlayer.Team
end

-- Check whether a target is on the blacklist.
-- Matches by instance or by character model, so blacklisting a Player
-- also blocks their character (and vice versa). No special-casing of
-- the local player: whatever is blacklisted is simply never a target.
local function IsBlacklisted(Target: Instance, Blacklist: BlacklistType?): boolean
	if Blacklist == nil then
		return false
	end
	const TargetCharacter = GetCharacter(Target)
	local function Matches(Item: Instance): boolean
		if Item == Target then
			return true
		end
		const ItemCharacter = GetCharacter(Item)
		if ItemCharacter and TargetCharacter then
			return ItemCharacter == TargetCharacter
		end
		return false
	end
	if typeof(Blacklist) == "Instance" then
		return Matches(Blacklist :: Instance)
	end
	for _, Item in (Blacklist :: { Instance }) do
		if Matches(Item) then
			return true
		end
	end
	return false
end

local function InRange(OriginPosition: Vector3, TargetPosition: Vector3, MinDistance: number, MaxDistance: number): boolean
	const Distance = (OriginPosition - TargetPosition).Magnitude
	return Distance >= MinDistance and Distance <= MaxDistance
end

-- Build the raycast ignore list: config.Ignore + shooter's character + target's character.
local function GetIgnoreList(Target: Instance, Config: ResolvedConfig): { Instance }
	const IgnoreList: { Instance } = {}

	if Config.Ignore ~= nil then
		if typeof(Config.Ignore) == "Instance" then
			table.insert(IgnoreList, Config.Ignore :: Instance)
		elseif type(Config.Ignore) == "table" then
			for _, Item in (Config.Ignore :: { Instance }) do
				table.insert(IgnoreList, Item)
			end
		end
	end

	if LocalPlayer.Character then
		table.insert(IgnoreList, LocalPlayer.Character)
	end

	const Character = GetCharacter(Target)
	if Character then
		table.insert(IgnoreList, Character)
	end

	return IgnoreList
end

-- Validate a single candidate target against the resolved config.
local function IsValidTarget(Target: Instance, Config: ResolvedConfig, OriginPosition: Vector3): boolean
	if IsBlacklisted(Target, Config.Blacklist) then
		return false
	end
	if not IsEnemy(Target, Config.TeamCheck) then
		return false
	end
	const AimPart = GetAimPart(Target, Config.AimPart)
	if not AimPart then
		return false
	end
	if not InRange(OriginPosition, AimPart.Position, Config.MinDistance, Config.Range) then
		return false
	end
	if Config.Visible and not aimbot.IsVisible(OriginPosition, Target, Config) then
		return false
	end
	return true
end

-- Combine every target list in the config into one flat list.
-- Returns nil when no lists were provided (caller falls back to scanning players).
local function CollectTargetLists(Config: ResolvedConfig): { Instance }?
	local Provided = false
	const Combined: { Instance } = {}

	if Config.EntityList ~= nil then
		Provided = true
		for _, Object in Config.EntityList do
			table.insert(Combined, Object)
		end
	end

	if Config.EntityLists ~= nil then
		Provided = true
		for _, List in Config.EntityLists do
			if type(List) == "table" then
				for _, Object in List do
					table.insert(Combined, Object)
				end
			end
		end
	end

	if not Provided then
		return nil
	end

	return Combined
end

-- Public API

-- Resolve any origin (CFrame | Vector3 | BasePart) to a Vector3 position.
function aimbot.GetOrigin(Origin: OriginType): Vector3
	return GetOrigin(Origin)
end

-- Resolve a target (Player | Model | BasePart) to its character Model.
function aimbot.GetCharacter(Target: Instance): Model?
	return GetCharacter(Target)
end

-- Resolve the part to aim at for a target.
function aimbot.GetAimPart(Target: Instance, AimPart: AimPartType?): BasePart?
	return GetAimPart(Target, AimPart)
end

-- Distance between an origin and a target part.
function aimbot.Range(Origin: OriginType, TargetPart: BasePart): number
	return (GetOrigin(Origin) - TargetPart.Position).Magnitude
end

-- Is there line-of-sight from Origin to the target's aim part? (Raycast based)
function aimbot.IsVisible(Origin: OriginType, Target: Instance, Config: AimbotConfig?): boolean
	const Normalized = NormalizeConfig(Config)
	const OriginPosition = GetOrigin(Origin)

	const AimPart = GetAimPart(Target, Normalized.AimPart)
	if not AimPart then
		return false
	end

	const RaycastParams = RaycastParams.new()
	RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
	RaycastParams.FilterDescendantsInstances = GetIgnoreList(Target, Normalized)

	const Direction = AimPart.Position - OriginPosition
	const Result = workspace:Raycast(OriginPosition, Direction, RaycastParams)

	-- No hit means nothing is blocking the line of sight.
	return Result == nil
end

-- Raycast from Origin toward a target's aim part; returns the hit point,
-- or the point past the target if unobstructed.
function aimbot.Raycast(Origin: OriginType, Target: Instance, Config: AimbotConfig?): Vector3?
	const Normalized = NormalizeConfig(Config)
	const OriginPosition = GetOrigin(Origin)

	const AimPart = GetAimPart(Target, Normalized.AimPart)
	if not AimPart then
		return nil
	end

	const RaycastParams = RaycastParams.new()
	RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
	RaycastParams.FilterDescendantsInstances = GetIgnoreList(Target, Normalized)

	const Direction = AimPart.Position - OriginPosition
	const Result = workspace:Raycast(OriginPosition, Direction, RaycastParams)
	if Result then
		return Result.Position
	end
	return OriginPosition + Direction
end

-- Collect all valid targets based on the config.
function aimbot.GetTargets(Config: AimbotConfig): { Instance }
	const Normalized = NormalizeConfig(Config)
	if Normalized.Origin == nil then
		error("Aimbot.GetTargets: Config.Origin is required")
	end
	const OriginPosition = GetOrigin(Normalized.Origin)
	const MaxTargets = Normalized.MaxTargets
	const Targets: { Instance } = {}

	-- Use the provided target lists (single EntityList and/or multiple EntityLists).
	const Candidates = CollectTargetLists(Normalized)
	if Candidates ~= nil then
		for _, Object in Candidates do
			if not IsValidTarget(Object, Normalized, OriginPosition) then
				continue
			end
			table.insert(Targets, Object)
			if #Targets >= MaxTargets then
				break
			end
		end
		return Targets
	end

	-- No lists provided: fall back to scanning other players.
	for _, Object in Players:GetPlayers() do
		if Object == LocalPlayer then
			continue
		end
		if not IsValidTarget(Object, Normalized, OriginPosition) then
			continue
		end
		table.insert(Targets, Object)
		if #Targets >= MaxTargets then
			break
		end
	end

	return Targets
end

-- Return the closest valid target and its aim part.
function aimbot.GetClosest(Config: AimbotConfig): (Instance?, BasePart?)
	const Normalized = NormalizeConfig(Config)
	const Targets = aimbot.GetTargets(Normalized)

	if Normalized.Origin == nil then
		error("Aimbot.GetClosest: Config.Origin is required")
	end
	const OriginPosition = GetOrigin(Normalized.Origin)

	local Closest: Instance? = nil
	local ClosestPart: BasePart? = nil
	local ClosestDistance = math.huge

	for _, Target in Targets do
		const AimPart = GetAimPart(Target, Normalized.AimPart)
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

-- Convenience alias for GetClosest.
function aimbot.GetTarget(Config: AimbotConfig): (Instance?, BasePart?)
	return aimbot.GetClosest(Config)
end

--[[
local Target, AimPart = Aimbot.GetClosest({
    Origin = v14.StartCFrame,          -- CFrame / Vector3 / BasePart all work
    Range = 200,
    TeamCheck = true,
    AimPart = "Head",
    Visible = true,
    Blacklist = { myFriend, adminPlayer },  -- Player/Instance or list, never targeted
    EntityLists = {
        NPCs    = workspace.Zombies:GetChildren(),
        Players = Players:GetPlayers(),
    },
})
--]]

return aimbot