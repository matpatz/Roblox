-- Aimbot low-level logic, loaded by main.lua (not public API).

const Players = game:GetService("Players")
const LocalPlayer = Players.LocalPlayer

-- Types (kept in sync with main.lua).

type OriginType = CFrame | Vector3 | BasePart
type AimPartType = string | { string } | Instance
type IgnoreType = Instance | { Instance }
type BlacklistType = Instance | string | { Instance | string }
type EntityListType = { Instance }
type EntityListsType = { { Instance } } | { [string]: { Instance } }

-- Caller config; all fields optional (defaults applied at read time).
type AimbotConfig = {
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

local Helpers = { ["Get"] = {}, ["Is"] = {}, ["Validate"] = {}, ["Collect"] = {} }

-- Classify any value: "Players" for Player objects, "BasePart" for any part,
-- else ClassName for Instances, and the value's kind otherwise (CFrame,
-- Vector3, table, ...). The only place that uses typeof/IsA.
Helpers["Get"].Type = function(Object: any): string
	const Kind = typeof(Object)
	if Kind ~= "Instance" then
		return Kind
	end
	if Object:IsA("Player") then
		return "Players"
	elseif Object:IsA("BasePart") then
		return "BasePart"
	end
	return Object.ClassName
end

-- Origin resolution

Helpers["Get"].Origin = function(Origin: OriginType): Vector3
	const Kind = Helpers["Get"].Type(Origin)
	if Kind == "CFrame" then
		return (Origin :: CFrame).Position
	elseif Kind == "Vector3" then
		return Origin :: Vector3
	elseif Kind == "BasePart" then
		return (Origin :: BasePart).Position
	end
	error("Aimbot.GetOrigin: expected CFrame, Vector3, or BasePart, got " .. tostring(Kind))
end

-- Target helpers

Helpers["Get"].Character = function(Target: Instance): Model?
	const TargetType = Helpers["Get"].Type(Target)
	if TargetType == "Players" then
		return (Target :: Player).Character
	elseif TargetType == "Model" then
		return Target :: Model
	elseif TargetType == "BasePart" and Target.Parent then
		return Target.Parent :: Model
	end
	return nil
end

Helpers["Get"].AimPart = function(Target: Instance, AimPart: AimPartType?): BasePart?
	const Character = Helpers["Get"].Character(Target)
	if not Character then
		return nil
	end

	if AimPart ~= nil and type(AimPart) ~= "string" and type(AimPart) ~= "table" then
		const Part = AimPart :: Instance
		if Helpers["Get"].Type(Part) == "BasePart" and Part:IsDescendantOf(Character) then
			return Part :: BasePart
		end
		return nil
	end

	if AimPart == "Random" then
		local Candidates: { BasePart } = {}
		for _, Descendant in Character:GetDescendants() do
			if Helpers["Get"].Type(Descendant) == "BasePart" then
				table.insert(Candidates, Descendant :: BasePart)
			end
		end
		if #Candidates == 0 then
			return nil
		end
		return Candidates[math.random(#Candidates)]
	end

	if type(AimPart) == "table" then
		const Names = AimPart :: { string }
		if #Names == 0 then
			return nil
		end
		return Character:FindFirstChild(Names[math.random(#Names)], true) :: BasePart?
	end

	const Name = if type(AimPart) == "string" then AimPart :: string else "HumanoidRootPart"
	return Character:FindFirstChild(Name, true) :: BasePart?
end

-- Is the candidate usable as a target? Never the local player; with TeamCheck
-- on, same-team players are skipped too. Models/BaseParts resolve to their owner.
Helpers["Is"].Target = function(Target: Instance, TeamCheck: boolean?): boolean
	-- Resolve Player | Model | BasePart to the owning player (if any).
	local TargetPlayer: Player? = nil
	if Helpers["Get"].Type(Target) == "Players" then
		TargetPlayer = Target :: Player
	else
		const Character = Helpers["Get"].Character(Target)
		if Character then
			-- pcall: GetPlayerFromCharacter can fail on NPCs/non-character models.
			local Success, Player = pcall(Players.GetPlayerFromCharacter, Players, Character)
			if Success then
				TargetPlayer = Player
			end
		end
	end

	-- Never aim at the local player's own character.
	if TargetPlayer == LocalPlayer then
		return false
	end

	if not TeamCheck then
		return true
	end

	-- Non-players (NPCs, bots) are always valid targets when TeamCheck is on.
	if not TargetPlayer then
		return true
	end

	-- TeamCheck compares teams, so both must have one.
	if TargetPlayer.Team == nil or LocalPlayer.Team == nil then
		error("Aimbot.IsTarget: TeamCheck is on, but one or both players have no Team")
	end

	return TargetPlayer.Team ~= LocalPlayer.Team
end

-- Blacklist: matches instances/characters; strings match by name.
Helpers["Is"].Blacklisted = function(Target: Instance, Blacklist: BlacklistType?): boolean
	if Blacklist == nil then
		return false
	end
	const TargetCharacter = Helpers["Get"].Character(Target)
	local function Matches(Item: Instance | string): boolean
		if Item == Target then
			return true
		end
		if type(Item) == "string" then
			return Target.Name == Item or (TargetCharacter ~= nil and TargetCharacter.Name == Item)
		end
		const ItemCharacter = Helpers["Get"].Character(Item)
		if ItemCharacter and TargetCharacter then
			return ItemCharacter == TargetCharacter
		end
		return false
	end
	if type(Blacklist) == "table" then
		for _, Item in (Blacklist :: { Instance | string }) do
			if Matches(Item) then
				return true
			end
		end
		return false
	end
	return Matches(Blacklist :: Instance | string)
end

Helpers["Is"].InRange = function(OriginPosition: Vector3, TargetPosition: Vector3, MinDistance: number, MaxDistance: number): boolean
	const Distance = (OriginPosition - TargetPosition).Magnitude
	return Distance >= MinDistance and Distance <= MaxDistance
end

Helpers["Get"].IgnoreList = function(Target: Instance, Config: AimbotConfig): { Instance }
	const IgnoreList: { Instance } = {}

	if Config.Ignore ~= nil then
		if type(Config.Ignore) == "table" then
			for _, Item in (Config.Ignore :: { Instance }) do
				table.insert(IgnoreList, Item)
			end
		else
			table.insert(IgnoreList, Config.Ignore :: Instance)
		end
	end

	if LocalPlayer.Character then
		table.insert(IgnoreList, LocalPlayer.Character)
	end

	const Character = Helpers["Get"].Character(Target)
	if Character then
		table.insert(IgnoreList, Character)
	end

	return IgnoreList
end

-- Line of sight to the target's aim part (already-resolved config); backs aimbot.IsVisible.
Helpers["Is"].LineOfSight = function(OriginPosition: Vector3, Target: Instance, Config: AimbotConfig): boolean
	const AimPart = Helpers["Get"].AimPart(Target, Config.AimPart)
	if not AimPart then
		return false
	end

	const RaycastParams = RaycastParams.new()
	RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
	RaycastParams.FilterDescendantsInstances = Helpers["Get"].IgnoreList(Target, Config)

	const Result = workspace:Raycast(OriginPosition, AimPart.Position - OriginPosition, RaycastParams)
	return Result == nil
end

Helpers["Validate"].Target = function(Target: Instance, Config: AimbotConfig, OriginPosition: Vector3): boolean
	if Helpers["Is"].Blacklisted(Target, Config.Blacklist) then
		return false
	end
	if not Helpers["Is"].Target(Target, Config.TeamCheck) then
		return false
	end
	const AimPart = Helpers["Get"].AimPart(Target, Config.AimPart)
	if not AimPart then
		return false
	end
	if not Helpers["Is"].InRange(OriginPosition, AimPart.Position, Config.MinDistance or 0, Config.Range or 200) then
		return false
	end
	if Config.Visible and not Helpers["Is"].LineOfSight(OriginPosition, Target, Config) then
		return false
	end
	return true
end

-- Flatten EntityList/EntityLists; nil when none were provided.
Helpers["Collect"].TargetLists = function(Config: AimbotConfig): { Instance }?
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

return Helpers
