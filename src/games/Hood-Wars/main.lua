-- // Services
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Players = game:GetService("Players")

-- // Modules
const Modules = ReplicatedStorage.Modules

local Utility = require(Modules.GlobalModules.Utility)

-- // Variables
local Raycast = Utility.CastRays

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

local Aimbot = loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/Modules/Aimbot/main.lua"))()

-- // Utils

Utils["Aimbot"].GetTargets = function(): { Instance }
    return Players:GetPlayers()
end

local aimconfig = {
    Origin,
    Range = config.SilentAim.Range,
    TeamCheck = config.SilentAim.TeamCheck,
    AimPart = config.SilentAim.AimPart,
    Visible = config.SilentAim.WallCheck,
    EntityLists = {},
}

Utils["Aimbot"].GetClosest = function(): BasePart?
    aimconfig["Origin"] = HumanoidRootPart.Position
    aimconfig["EntityLists"] = {
        Utils["Aimbot"].GetTargets()
    }

	const Target, AimPart = Aimbot.GetClosest(aimconfig)
	if not Target or not AimPart then
		return nil
	end
	const Character = Target.Character

    return Character, AimPart
end

-- // Core

if isfunctionhooked(Raycast) then
    restorefunction(Raycast)
end

type Results = {
    position: Vector3,
    normal: Vector3,
    instance: Instance?,
    taggedHumanoid: Humanoid?,
}

local Old; Old = hookfunction(Raycast, function(p3: userdata, p4: vector, p5: table, p6: number, p7: table?, p8: boolean?)
    if config.SilentAim.Enabled then
        const Target, AimPart = Utils["Aimbot"].GetClosest()
        if Target and AimPart then
            return {
                {
                    position = AimPart.Position,
                    instance = AimPart,
                    normal = (AimPart.Position - HumanoidRootPart.Position).Unit,
                    taggedHumanoid = Target.Humanoid
                },
            }
        end
    end
    return Old(p3, p4, p5, p6, p7, p8)
end)