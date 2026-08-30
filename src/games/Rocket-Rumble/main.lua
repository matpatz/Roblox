-- silent aim in a game like this isnt very useful

-- // Services
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Players = game:GetService("Players")

-- // Modules
local BlasterController = require(ReplicatedStorage.Blaster.Scripts.BlasterController)

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
        ["Aimbot"] = {}
	},
	Core = {

	}
}
local Utils = cheat.Utils
local Core = cheat.Core

-- // config
local aimconfig = {
    Range = 400,
    TeamCheck = true,
    AimPart = "Head",
    Visible = true,
    EntityLists = {
        {}
    },
}
local config = {
    ["Combat"] = {
        ["SilentAim"] = true
    }
}

local Aimbot = loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/Modules/Aimbot/main.lua"))()

Utils["Aimbot"].GetClosest = function(): (BasePart?)
    aimconfig["Origin"] = HumanoidRootPart.Position

    local Filtered = {}
    for _, Target in workspace:QueryDescendants("Model:has(Humanoid)") do
        if Target ~= Character then
            table.insert(Filtered, Target)
        end
    end
    aimconfig["EntityLists"] = { Filtered }

    const Target, AimPart = Aimbot.GetClosest(aimconfig)

    return AimPart
end

local shoot = BlasterController.shootLauncher

local get_ray_directions = debug.getupvalue(shoot, 4)
local function new_ray_directions(CameraCFrame, raysPerShot, spread, ServerTimeNow)
    local AimPart = nil
    if config["Combat"]["SilentAim"] then
        AimPart = Utils["Aimbot"].GetClosest()
    end

    if not AimPart then
        return get_ray_directions(CameraCFrame, raysPerShot, spread, ServerTimeNow)
    end

    local AimDirection = AimPart.Position - CameraCFrame.Position

    if AimDirection.Magnitude < 1 then
        return get_ray_directions(CameraCFrame, raysPerShot, spread, ServerTimeNow)
    end

    local aim_cframe = CFrame.lookAt(CameraCFrame.Position, AimPart.Position, CameraCFrame.UpVector)

    return get_ray_directions(aim_cframe, raysPerShot, spread, ServerTimeNow)
end

debug.setupvalue(shoot, 4, new_ray_directions)
