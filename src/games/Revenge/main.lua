-- // Services
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Players = game:GetService("Players")

-- // Modules
const Modules = ReplicatedStorage.Shared.modules

local BlasterController = require(Modules.Weapon.Controllers.BlasterController)
-- const GameRemotes = require(Modules.GameRemotes)

-- // Events
-- const BlasterReload = GameRemotes.BlasterReload

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
        ["InfiniteAmmo"] = true,
        ["SilentAim"] = true,
        ["NoRecoil"] = true,
        ["NoSpread"] = true
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

local shoot; shoot = hookfunction(BlasterController.shoot, function(Controller)
    if config["Combat"]["InfiniteAmmo"] then
        Controller.ammo = 30
    end

    return shoot(Controller)
end)

local get_ray_directions = debug.getupvalue(shoot, 5)
local function new_ray_directions(CameraCFrame, raysPerShot, spread, ServerTimeNow)
    if config["Combat"]["NoSpread"] then
        spread = 0
    end

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

debug.setupvalue(shoot, 5, new_ray_directions)

local recoil; recoil = hookfunction(BlasterController.recoil, function(p17)
    if not config["Combat"]["NoRecoil"] then
        recoil(p17)
    end
end)