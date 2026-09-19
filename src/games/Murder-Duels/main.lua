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
        ["Aimbot"] = {},
        ["Wallbang"] = {}
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
	Wallbang = {
		Enabled = true,
		MaxWalls = 6, -- how many blocking parts a single shot keeps piercing
	},
}

const Aimbot = loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/Modules/Aimbot/main.lua"))()

-- // Utils
Utils.GetTargets = function(): { Instance }
	const MatchId = LocalPlayer:GetAttribute("MatchId")
	if type(MatchId) ~= "string" then
		-- not in a match (lobby / spectating): nobody else is a valid target
		return {}
	end

	const MatchSide = LocalPlayer:GetAttribute("MatchSide")
	const Targets: { Instance } = {}

	local function IsLiving(Character: Instance?): boolean
		const Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
		return Humanoid ~= nil and Humanoid.Health > 0
	end

	local function IsEnemySide(Item: Instance): boolean
		const ItemSide = Item:GetAttribute("MatchSide")
		return type(ItemSide) == "string" and ItemSide ~= MatchSide
	end

	-- every running match dumps its characters into the same workspace.Characters folder,
	-- so MatchId (not side) is what separates "in my map" from "someone else's map"
	local function IsInMyMatch(Item: Instance): boolean
		const ItemMatchId = Item:GetAttribute("MatchId")
		if type(ItemMatchId) == "string" then
			return ItemMatchId == MatchId
		end

		-- decoy models have no MatchId, only their owner
		const OwnerUserId = Item:GetAttribute("DecoyOwnerUserId")
		if type(OwnerUserId) == "number" then
			const Owner = Players:GetPlayerByUserId(OwnerUserId)
			return Owner ~= nil and Owner:GetAttribute("MatchId") == MatchId
		end

		return false
	end

	-- enemy players
	for _, Player in Players:GetPlayers() do
		if Player == LocalPlayer then
			continue
		end
		if not IsInMyMatch(Player) then
			continue
		end
		if not IsEnemySide(Player) then
			continue
		end
		if Player:GetAttribute("Alive") ~= true then -- dead players / replay watchers keep full health
			continue
		end
		if not IsLiving(Player.Character) then
			continue
		end

		table.insert(Targets, Player)
	end

	-- enemy bots / decoys
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
		if not (Child:GetAttribute("BotMatchBot") == true or Child:GetAttribute("Decoy") == true) then
			continue
		end
		if not IsInMyMatch(Child) then
			continue
		end
		if not IsEnemySide(Child) then
			continue
		end
		if not IsLiving(Child) then
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

-- // Wallbang
-- a shot is resolved by one workspace raycast, so the first wall it meets ends it. keep that
-- ray going past every non-character hit (up to MaxWalls) and the reported hit becomes
-- whatever stands behind them instead.
Utils["Wallbang"].Pierce = function(Original: (...any) -> RaycastResult?, Origin: Vector3, Direction: Vector3, Magnitude: number?, IgnoreList: { Instance }?): RaycastResult?
	const MaxRange = Magnitude or 1000
	local Result = Original(Origin, Direction, MaxRange, IgnoreList)
	local Travelled = 0
	local Pierced = 0

	while Result and Pierced < config.Wallbang.MaxWalls do
		const HitCharacter = Result.Instance:FindFirstAncestorOfClass("Model")
		if HitCharacter and HitCharacter:FindFirstChildOfClass("Humanoid") then
			break
		end

		const Step = (Result.Position - Origin).Magnitude
		if Step < 0.01 then
			break
		end

		Travelled = Travelled + Step
		const Remaining = MaxRange - Travelled
		if Remaining <= 0.01 then
			break
		end

		Origin = Result.Position + Direction * 0.05
		Result = Original(Origin, Direction, Remaining, IgnoreList)
		Pierced = Pierced + 1
	end

	return Result
end

Utils["Wallbang"].Install = function(): number
	local Installed = 0

	for _, Predict in filtergc("function", { Name = "localPredictEnemyHit" }) do
		const Source = debug.info(Predict, "s")
		if type(Source) == "string" and Source:find("RevolverClient", 1, true) then
			local Original
			Original = hookfunction(Predict, newlclosure(function(Origin, Direction, Magnitude, IgnoreList)
				if not config.Wallbang.Enabled then
					return Original(Origin, Direction, Magnitude, IgnoreList)
				end

				return Utils["Wallbang"].Pierce(Original, Origin, Direction, Magnitude, IgnoreList)
			end))
			Installed = Installed + 1
		end
	end

	return Installed
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
	if not Ok then
		warn("[SilentAim] GetClosest error: " .. tostring(AimPart))
	end
	if not (Ok and AimPart) then
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

-- // Wallbang hooks
warn("[Wallbang] installed on " .. Utils["Wallbang"].Install() .. " closures")

local function Reinstall(Container: Instance)
	if Container.Name ~= "Revolver" then
		return
	end

	task.wait(0.25) -- let the fresh RevolverClient define its closures
	warn("[Wallbang] re-installed on " .. Utils["Wallbang"].Install() .. " closures")
end

Character.ChildAdded:Connect(Reinstall)
LocalPlayer.CharacterAdded:Connect(function(NewCharacter)
	NewCharacter.ChildAdded:Connect(Reinstall)
end)
if LocalPlayer.Backpack then
	LocalPlayer.Backpack.ChildAdded:Connect(Reinstall)
end

-- // Interface
const Rayfield = assert(loadstring(game:HttpGet("https://voltex.website/libraries/Rayfield/main.lua")))()

const Window = Rayfield:CreateWindow({
	Name = "Murder Duels",
	LoadingTitle = "Murder Duels",
	LoadingSubtitle = "loading...",
})

const Combat = Window:CreateTab("Combat")
const a = Window:CreateTab("a")

-- // Silent Aim
Combat:CreateSection("Silent Aim")

Combat:CreateToggle({
	Name = "Enabled",
	CurrentValue = config.SilentAim.Enabled,
	Flag = "SilentAimEnabled",
	Callback = function(Value)
		config.SilentAim.Enabled = Value
	end,
})

Combat:CreateSlider({
	Name = "Range",
	Range = { 50, 1000 },
	Increment = 25,
	Suffix = "studs",
	CurrentValue = config.SilentAim.Range,
	Flag = "SilentAimRange",
	Callback = function(Value)
		config.SilentAim.Range = Value
	end,
})

Combat:CreateDropdown({
	Name = "Aim Part",
	Options = { "Head", "HumanoidRootPart", "UpperTorso" },
	CurrentOption = { config.SilentAim.AimPart },
	MultipleOptions = false,
	Flag = "SilentAimAimPart",
	Callback = function(Options)
		config.SilentAim.AimPart = Options[1]
	end,
})

Combat:CreateToggle({
	Name = "Wall Check",
	CurrentValue = config.SilentAim.WallCheck,
	Flag = "SilentAimWallCheck",
	Callback = function(Value)
		config.SilentAim.WallCheck = Value
	end,
})

Combat:CreateToggle({
	Name = "Debug",
	CurrentValue = config.SilentAim.Debug,
	Flag = "SilentAimDebug",
	Callback = function(Value)
		config.SilentAim.Debug = Value
	end,
})

-- // Wallbang
Combat:CreateSection("Wallbang")

Combat:CreateToggle({
	Name = "Enabled",
	CurrentValue = config.Wallbang.Enabled,
	Flag = "WallbangEnabled",
	Callback = function(Value)
		config.Wallbang.Enabled = Value
	end,
})

Combat:CreateSlider({
	Name = "Max Walls",
	Range = { 1, 12 },
	Increment = 1,
	CurrentValue = config.Wallbang.MaxWalls,
	Flag = "WallbangMaxWalls",
	Callback = function(Value)
		config.Wallbang.MaxWalls = Value
	end,
})
