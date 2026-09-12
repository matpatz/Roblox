-- // Services
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Players = game:GetService("Players")

-- // Modules
const Modules = ReplicatedStorage.Events.Modules

local RaycastModule = require(Modules.RaycastModule)

--// Functions
local Raycast = RaycastModule.Raycast

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
		TeamCheck = false,
		WallCheck = true,
	},
}

local Aimbot = loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/Modules/Aimbot/v1/main.lua"))()

-- // Utils

Utils["Aimbot"].GetTargets = function(): { Player }
	local Targets: { Player } = {}
	for _, Player in Players:GetPlayers() do
		if Player == LocalPlayer then
			continue
		end
		table.insert(Targets, Player)
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

	local _, AimPart = Aimbot.GetClosest(aimconfig)
	return AimPart
end

-- // Core

if isfunctionhooked(Raycast) then
    restorefunction(Raycast)
end

local Old; Old = hookfunction(Raycast, function(p2: Vector3, p3: Vector3, p4: { Instance }?)
    if config.SilentAim.Enabled then
        const AimPart = Utils["Aimbot"].GetClosest()
        if AimPart then
            return AimPart, AimPart.Position, (AimPart.Position - p2).Unit
        end
    end
    return Old(p2, p3, p4)
end)