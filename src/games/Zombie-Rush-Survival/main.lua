-- Zombie Rush Survival — silent aim, kill aura, kill all, bullet pierce, gun mods.
-- Damage is client-registered here, so every seam below is a real damage seam.

--// Knit
local Knit = shared.Knit
local services = Knit.services

-- // Services
const Players = game:GetService("Players")
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const RunService = game:GetService("RunService")
const UserInputService = game:GetService("UserInputService")

-- // LocalPlayer
const LocalPlayer = Players.LocalPlayer

-- // Workspace
const Visuals = workspace:WaitForChild("Zombie_ClientVisuals")

-- // config
local config = {
	SilentAim = {
		Enabled = false,
		Mode = "Always",   -- "Always" | "Hold Key" | "On ADS"
		LosCheck = true,   -- only lock when there is a clear line of sight
		KeyHeld = false,
		MaxRange = 500,
	},
	KillAura = {
		Enabled = false,
		Range = 300,       -- capped at 400: the gun clamps every shot query to 400 studs
		LosCheck = true,   -- only shoot zombies the shot can actually reach
	},
	BulletPierce = {
		Enabled = false,   -- ignore world blockers so the shot resolves through walls
	},
	GunMods = {
		NoSpread = false,    -- shotguns: every pellet takes the base direction
		InfiniteMag = false, -- clip stays full, so the gun never runs dry
	},
	KillAll = {
		Enabled = false,
		Range = 400,         -- the gun clamps every shot query to 400 studs
		PerTick = 4,         -- shot packets per frame, so a horde clears over a few frames
	},
}

-- // Modules (shared; the gun modules are required in HookGun)
const Shared = ReplicatedStorage:WaitForChild("Shared")
const GunData = require(Shared:WaitForChild("Modules"):WaitForChild("GunData"))

-- ZombieProtocol only replicates in-match, so it is hooked once it shows up.
task.spawn(function()
	local Protocol = require(Shared:WaitForChild("Zombies"):WaitForChild("ZombieProtocol"))

	-- no spread: the client rays and the server's replay of the packet both use this
	local ShotGroupDirection
	ShotGroupDirection = hookfunction(Protocol.GetShotGroupDirection, function(Direction, ...)
		if config.GunMods.NoSpread and typeof(Direction) == "Vector3" then
			return Direction.Unit
		end
		return ShotGroupDirection(Direction, ...)
	end)
end)

-- // Targeting
-- live models carry ZombieClientHitboxEnabled; the game clears it on death
local function AimPart(Model)
	local Head = Model:FindFirstChild("Head")
	if Head and Head:IsA("BasePart") and Head:GetAttribute("ZombieClientHitboxEnabled") ~= false then
		return Head
	end
end

local RayParams = RaycastParams.new()
RayParams.FilterType = Enum.RaycastFilterType.Exclude

local function Visible(From, To, Model, Check)
	if not Check then
		return true
	end
	RayParams.FilterDescendantsInstances = { LocalPlayer.Character }
	local Hit = workspace:Raycast(From, To - From, RayParams)
	return Hit == nil or Hit.Instance:IsDescendantOf(Model)
end

-- nearest live model, preferring one the shot can actually reach
local function PickTarget(Range, Check)
	local Camera = workspace.CurrentCamera
	if not Camera then
		return nil
	end

	Range = Range or config.SilentAim.MaxRange
	if Check == nil then
		Check = config.SilentAim.LosCheck
	end

	local Origin = Camera.CFrame.Position
	local Best, BestPart, BestDistance = nil, nil, math.huge

	for _, Model in Visuals:GetChildren() do
		local Part = AimPart(Model)
		if Part then
			local Distance = (Part.Position - Origin).Magnitude
			if Distance <= Range and Distance < BestDistance then
				Best, BestPart, BestDistance = Model, Part, Distance
			end
		end
	end

	if not Best or Visible(Origin, BestPart.Position, Best, Check) then
		return Best, BestPart
	end

	local Seen, SeenPart, SeenDistance = nil, nil, math.huge
	for _, Model in Visuals:GetChildren() do
		if Model ~= Best then
			local Part = AimPart(Model)
			if Part then
				local Distance = (Part.Position - Origin).Magnitude
				if Distance <= Range and Distance < SeenDistance and Visible(Origin, Part.Position, Model, Check) then
					Seen, SeenPart, SeenDistance = Model, Part, Distance
				end
			end
		end
	end

	return Seen, SeenPart
end

local function Locked()
	if not config.SilentAim.Enabled then
		return false
	end
	if config.SilentAim.Mode == "Hold Key" then
		return config.SilentAim.KeyHeld
	end
	if config.SilentAim.Mode == "On ADS" then
		return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
	end
	return true
end

-- // Hooks
local Hooked = {}

-- One packet builder per gun, plus the ids Kill All hands out so every packet looks like a fresh shot.
local Clients = {}
local ShotId, AmmoActionId = 0, 0

local function HookGun(Tool)
	local Handler = Tool:FindFirstChild("Handler")
	local RaycastModule = Handler and Handler:WaitForChild("WeaponRaycast", 2)
	if not RaycastModule or Hooked[RaycastModule] then
		return
	end
	Hooked[RaycastModule] = true

	local Raycast = require(RaycastModule)
	local Settings = require(assert(Handler:FindFirstChild("WeaponClientSettings"), Tool.Name .. ": WeaponClientSettings is missing"))
	local Shots = require(assert(Handler:FindFirstChild("ZombieShotClient"), Tool.Name .. ": ZombieShotClient is missing"))

	-- silent aim: replace the aim point every shot is built from, the camera never moves
	local AimTargetPosition
	AimTargetPosition = hookfunction(Raycast.GetAimTargetPosition, function(Self, ...)
		if config.KillAura.Enabled or Locked() then
			local _, Part = PickTarget()
			if Part then
				return Part.Position
			end
		end
		return AimTargetPosition(Self, ...)
	end)

	-- kill aura: the gun's own auto-shoot loop asks these two where to shoot
	local AutoShootHit
	AutoShootHit = hookfunction(Raycast.GetAutoShootRaycastHit, function(Self, Origin, Direction, Distance)
		if config.KillAura.Enabled then
			local Reachable = config.KillAura.LosCheck and not config.BulletPierce.Enabled
			local _, Part = PickTarget(math.min(Distance, config.KillAura.Range), Reachable)
			if Part then
				return Part, Part.Position, Vector3.yAxis
			end
		end
		return AutoShootHit(Self, Origin, Direction, Distance)
	end)

	local ConeTarget
	ConeTarget = hookfunction(Raycast.HasContinuousConeZombieTarget, function(Self, Origin, Direction, WeaponInfo, Range)
		local Reachable = config.KillAura.LosCheck and not config.BulletPierce.Enabled
		if config.KillAura.Enabled and PickTarget(math.min(Range or config.KillAura.Range, config.KillAura.Range), Reachable) then
			return true
		end
		return ConeTarget(Self, Origin, Direction, WeaponInfo, Range)
	end)

	-- bullet pierce: stop the world from clipping the shot ray, so the hitbox trace reaches through walls
	local BlockingRayDistance
	BlockingRayDistance = hookfunction(Raycast.GetBlockingRayDistance, function(Self, Origin, Direction, Range, Context)
		if config.BulletPierce.Enabled then
			return Raycast.ClampTrackedQueryDistance(Range)
		end
		return BlockingRayDistance(Self, Origin, Direction, Range, Context)
	end)

	-- the gun only auto-shoots on mobile, so claim it is active while the aura is on
	local AutoShootActive
	AutoShootActive = hookfunction(Settings.IsAutoShootActive, function(Self, ...)
		if config.KillAura.Enabled then
			return true
		end
		return AutoShootActive(Self, ...)
	end)

	-- no spread: zero the spread the packet carries so the server derives the same straight line
	local FireShotGroup
	FireShotGroup = hookfunction(Shots.FireShotGroup, function(Self, Packet)
		if config.GunMods.NoSpread then
			Packet.Spread = 0
		end
		return FireShotGroup(Self, Packet)
	end)

	-- kill all sends its own packets, so keep a shot client per gun
	Clients[Tool] = Shots.new({
		ReplicatedStorage = ReplicatedStorage,
		SharedFolder = Shared,
		WeaponType = Tool.Name,
		Character = LocalPlayer.Character,
		GetGunInfo = function()
			return GunData[Tool.Name]
		end,
	})

	-- infinite mag: the handler decrements Info.Clip per shot, so push it back to full
	local Info = Tool:FindFirstChild("Info")
	local Clip = Info and Info:FindFirstChild("Clip")
	local ClipSize = Info and Info:FindFirstChild("ClipSize")
	if Clip and ClipSize then
		Clip:GetPropertyChangedSignal("Value"):Connect(function()
			if config.GunMods.InfiniteMag and Clip.Value < ClipSize.Value then
				Clip.Value = ClipSize.Value
			end
		end)
	end
end

-- Kill All arms a ZombieShotClient per model and lets the server resolve the damage: FindHit only
-- traces hitboxes (walls never matter) and the candidate lands on the ray the packet describes.
local function KillAll()
	local Tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
	local Client = Tool and Clients[Tool]
	if not Client then
		return
	end

	local Info = Tool:FindFirstChild("Info")
	local Clip = Info and Info:FindFirstChild("Clip")
	local Origin = (Tool:FindFirstChild("Exit") or LocalPlayer.Character.Head).Position
	local Range = math.min(config.KillAll.Range, 400)
	local Sent = 0

	for _, Model in Visuals:GetChildren() do
		if Sent >= config.KillAll.PerTick then
			break
		end
		local Part = AimPart(Model)
		if Part then
			local Offset = Part.Position - Origin
			if Offset.Magnitude > 0.001 and Offset.Magnitude <= Range then
				local Candidate = Client:FindHit(Origin, Offset.Unit, Range, nil)
				if Candidate then
					ShotId += 1
					AmmoActionId += 1
					Client:FireShot(Origin, Offset.Unit, Candidate, ShotId, Clip and Clip.Value or 1, AmmoActionId)
					Sent += 1
				end
			end
		end
	end
end

RunService.Heartbeat:Connect(function()
	if config.KillAll.Enabled then
		KillAll()
	end
end)

-- // Tool hooks (guns arrive with the backpack, the character or a respawn)
LocalPlayer.DescendantAdded:Connect(function(Descendant)
	if Descendant:IsA("Tool") then
		HookGun(Descendant)
	end
end)

for _, Descendant in LocalPlayer:GetDescendants() do
	if Descendant:IsA("Tool") then
		HookGun(Descendant)
	end
end

-- // Interface
local Rayfield = Knit.ui.new("Rayfield")()

local Window = Rayfield:CreateWindow({
	Name = "Zombie Rush Survival",
	LoadingTitle = "Zombie Rush Survival",
	LoadingSubtitle = "Silent Aim",
	ConfigurationSaving = { Enabled = true, FolderName = nil, FileName = "Zombie-Rush-Survival" },
})

local tabs = {
	Config = Window:CreateTab("Config"),
	Settings = Window:CreateTab("Settings"),
}

-- // Config

tabs.Config:CreateSection("Silent Aim")

tabs.Config:CreateToggle({
	Name = "Silent Aim",
	CurrentValue = false,
	Flag = "zsa_enabled",
	Callback = function(Value)
		config.SilentAim.Enabled = Value
	end,
})

tabs.Config:CreateSection("Combat")

tabs.Config:CreateToggle({
	Name = "Kill Aura",
	CurrentValue = false,
	Flag = "zka_enabled",
	Callback = function(Value)
		config.KillAura.Enabled = Value
	end,
})

tabs.Config:CreateToggle({
	Name = "Kill All",
	CurrentValue = false,
	Flag = "zall_enabled",
	Callback = function(Value)
		config.KillAll.Enabled = Value
	end,
})

tabs.Config:CreateToggle({
	Name = "Bullet Pierce",
	CurrentValue = false,
	Flag = "zbp_enabled",
	Callback = function(Value)
		config.BulletPierce.Enabled = Value
	end,
})

tabs.Config:CreateSection("Gun Mods")

tabs.Config:CreateToggle({
	Name = "No Shotgun Spread",
	CurrentValue = false,
	Flag = "zgm_nospread",
	Callback = function(Value)
		config.GunMods.NoSpread = Value
	end,
})

tabs.Config:CreateToggle({
	Name = "Infinite Mag",
	CurrentValue = false,
	Flag = "zgm_infmag",
	Callback = function(Value)
		config.GunMods.InfiniteMag = Value
	end,
})

-- // Settings

tabs.Settings:CreateSection("Silent Aim")

tabs.Settings:CreateDropdown({
	Name = "Mode",
	Options = { "Always", "Hold Key", "On ADS" },
	CurrentOption = { config.SilentAim.Mode },
	MultipleOptions = false,
	Flag = "zsa_mode",
	Callback = function(Option)
		config.SilentAim.Mode = Option[1] or "Always"
	end,
})

tabs.Settings:CreateKeybind({
	Name = "Lock Key (Hold Key mode)",
	CurrentKeybind = "E",
	HoldToInteract = true,
	Flag = "zsa_key",
	Callback = function(Holding)
		config.SilentAim.KeyHeld = Holding
	end,
})

tabs.Settings:CreateToggle({
	Name = "Line of Sight Check",
	CurrentValue = true,
	Flag = "zsa_los",
	Callback = function(Value)
		config.SilentAim.LosCheck = Value
	end,
})

tabs.Settings:CreateSection("Kill Aura")

tabs.Settings:CreateSlider({
	Name = "Range",
	Range = { 50, 400 },
	Increment = 25,
	Suffix = "studs",
	CurrentValue = config.KillAura.Range,
	Flag = "zka_range",
	Callback = function(Value)
		config.KillAura.Range = Value
	end,
})

tabs.Settings:CreateToggle({
	Name = "Line of Sight Check",
	CurrentValue = true,
	Flag = "zka_los",
	Callback = function(Value)
		config.KillAura.LosCheck = Value
	end,
})

tabs.Settings:CreateSection("Kill All")

tabs.Settings:CreateSlider({
	Name = "Range",
	Range = { 50, 400 },
	Increment = 25,
	Suffix = "studs",
	CurrentValue = config.KillAll.Range,
	Flag = "zall_range",
	Callback = function(Value)
		config.KillAll.Range = Value
	end,
})
