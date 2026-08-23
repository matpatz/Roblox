-- aiSLOPPPPPPPP

--[[
	Zombie-Escape Hub — Silent Aim

	Redirects every shot to the nearest zombie WITHOUT moving the camera (truly silent). -- this wasnt a reprompt idk why it said that

	How it works (based on the decompiled gun Handler, e.g. M1911):
		Every gun client script computes its aim point via
			u33:GetAimTargetPosition(u55, u56, CrosshairService, range)
		then derives the shot ray (hitscan) or sends that point to the server (projectiles).
		This method is the same seam the game's own console/mobile aim-assist drives, so
		redirecting it passes server validation while the camera never moves.

	We find the `WeaponRaycast` module inside each weapon tool, require it, and replace
	`GetAimTargetPosition` on the module table (the shared prototype). If a module instead
	creates per-instance methods inside `new`, we wrap `new` and proxy the instances.
]]

-- // Services
const Players = game:GetService("Players")
const UserInputService = game:GetService("UserInputService")

-- // LocalPlayer
const LocalPlayer = Players.LocalPlayer

-- // Workspace
const ZombieVisuals = workspace:WaitForChild("Zombie_ClientVisuals")

-- // config
local config = {
	SilentAim = {
		Enabled = false,
		Mode = "Always",   -- "Always" | "Hold Key" | "On ADS"
		LosCheck = true,   -- only lock when there is a clear line of sight
		KeyHeld = false,
		MaxRange = 500,
	},
}

-- // cheat
local cheat = {
	Utils = {},
	Core = {},
}
local Utils = cheat.Utils
local Core = cheat.Core

-- // Utils
local HEAD_PARTS = {
	"Head", "HeadCollision", "HeadHitbox",
	"HumanoidRootPart", "RootPart", "Torso",
	"UpperTorso", "LowerTorso",
}

Utils.IsAlive = function(Zombie)
	if not Zombie or not Zombie.Parent then
		return false
	end
	local Humanoid = Zombie:FindFirstChildOfClass("Humanoid")
	if Humanoid and Humanoid.Health <= 0 then
		return false
	end
	return true
end

Utils.GetAimPoint = function(Zombie)
	for _, Name in ipairs(HEAD_PARTS) do
		local Part = Zombie:FindFirstChild(Name)
		if Part and Part:IsA("BasePart") then
			return Part.Position
		end
	end
	local Ok, Pivot = pcall(function()
		return Zombie:GetPivot().Position
	end)
	return Ok and Pivot or nil
end

local RayParams = RaycastParams.new()
RayParams.FilterType = Enum.RaycastFilterType.Exclude

Utils.IsVisible = function(From, To, Zombie)
	if not config.SilentAim.LosCheck then
		return true
	end
	RayParams.FilterDescendantsInstances = { LocalPlayer.Character }
	local Result = workspace:Raycast(From, To - From, RayParams)
	if not Result then
		return true
	end
	local Instance = Result.Instance
	while Instance do
		if Instance == Zombie then
			return true
		end
		Instance = Instance.Parent
	end
	return false
end

Utils.PickTarget = function()
	local Camera = workspace.CurrentCamera
	if not Camera then
		return nil
	end

	local CamPos = Camera.CFrame.Position

	-- Pass 1: nearest candidate (no LOS raycasts yet)
	local Best, BestPos, BestDist = nil, nil, math.huge
	for _, Zombie in ipairs(ZombieVisuals:GetChildren()) do
		if Utils.IsAlive(Zombie) then
			local Pos = Utils.GetAimPoint(Zombie)
			if Pos then
				local Dist = (Pos - CamPos).Magnitude
				if Dist <= config.SilentAim.MaxRange and Dist < BestDist then
					Best, BestPos, BestDist = Zombie, Pos, Dist
				end
			end
		end
	end

	if not Best then
		return nil
	end
	if Utils.IsVisible(CamPos, BestPos, Best) then
		return Best
	end

	-- Pass 2: nearest candidate that actually has a clear line of sight
	local Visible, VisibleDist = nil, math.huge
	for _, Zombie in ipairs(ZombieVisuals:GetChildren()) do
		if Zombie ~= Best and Utils.IsAlive(Zombie) then
			local Pos = Utils.GetAimPoint(Zombie)
			if Pos then
				local Dist = (Pos - CamPos).Magnitude
				if Dist <= config.SilentAim.MaxRange and Dist < VisibleDist and Utils.IsVisible(CamPos, Pos, Zombie) then
					Visible, VisibleDist = Zombie, Dist
				end
			end
		end
	end

	return Visible
end

Utils.ShouldLock = function()
	if not config.SilentAim.Enabled then
		return false
	end
	if config.SilentAim.Mode == "Always" then
		return true
	end
	if config.SilentAim.Mode == "Hold Key" then
		return config.SilentAim.KeyHeld
	end
	if config.SilentAim.Mode == "On ADS" then
		return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
	end
	return false
end

-- // Core
local Hooked = {}

Core.AimOverride = function()
	local Target = Utils.PickTarget()
	if not Target then
		return nil
	end
	return Utils.GetAimPoint(Target)
end

Core.ApplyHooks = function(Module)
	if Hooked[Module] then
		return
	end
	Hooked[Module] = true

	-- Primary: methods live on the module table (shared prototype: __index = module)
	if type(Module.GetAimTargetPosition) == "function" then
		local Original = Module.GetAimTargetPosition
		Module.GetAimTargetPosition = function(Self, ...)
			if Utils.ShouldLock() then
				local Point = Core.AimOverride()
				if Point then
					return Point
				end
			end
			return Original(Self, ...)
		end
		return
	end

	-- Fallback: instances are built in `new` — proxy them so GetAimTargetPosition is overridden
	if type(Module.new) == "function" then
		local OriginalNew = Module.new
		Module.new = function(Options, ...)
			local Instance = OriginalNew(Options, ...)
			if type(Instance) ~= "table" then
				return Instance
			end
			return setmetatable({}, {
				__index = function(Self, Key)
					if Key == "GetAimTargetPosition" then
						return function(_, ...)
							if Utils.ShouldLock() then
								local Point = Core.AimOverride()
								if Point then
									return Point
								end
							end
							return Instance[Key](Instance, ...)
						end
					end
					return Instance[Key]
				end,
				__newindex = function(Self, Key, Value)
					Instance[Key] = Value
				end,
				__metatable = "SilentAim",
			})
		end
	end
end

Core.HookTool = function(Tool)
	if not Tool:IsA("Tool") then
		return
	end
	for _, Child in ipairs(Tool:GetDescendants()) do
		if Child:IsA("ModuleScript") and Child.Name == "WeaponRaycast" then
			local Ok, Module = pcall(require, Child)
			if Ok and type(Module) == "table" then
				Core.ApplyHooks(Module)
			end
		end
	end
end

Core.ScanAndHook = function()
	local Backpack = LocalPlayer:FindFirstChild("Backpack")
	if Backpack then
		for _, Tool in ipairs(Backpack:GetChildren()) do
			Core.HookTool(Tool)
		end
	end
	if LocalPlayer.Character then
		for _, Tool in ipairs(LocalPlayer.Character:GetChildren()) do
			Core.HookTool(Tool)
		end
	end
end

-- Hook weapons as they appear (equipped / picked up / respawned)
local function OnToolAdded(Tool)
	if Tool:IsA("Tool") then
		task.spawn(Core.HookTool, Tool)
	end
end

LocalPlayer.ChildAdded:Connect(OnToolAdded)
LocalPlayer.CharacterAdded:Connect(function()
	task.wait(2)
	Core.ScanAndHook()
	if LocalPlayer.Character then
		LocalPlayer.Character.ChildAdded:Connect(OnToolAdded)
	end
end)

local Backpack = LocalPlayer:FindFirstChild("Backpack")
if Backpack then
	Backpack.ChildAdded:Connect(OnToolAdded)
end
if LocalPlayer.Character then
	LocalPlayer.Character.ChildAdded:Connect(OnToolAdded)
end

Core.ScanAndHook()

-- // Interface
local Rayfield = loadstring(game:HttpGet("https://voltex.website/libraries/Rayfield/main.lua"))()

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
