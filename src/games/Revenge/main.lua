-- // Services
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Players = game:GetService("Players")
const Workspace = game:GetService("Workspace")

-- // Modules
const Modules = ReplicatedStorage.Shared.modules

local BlasterController = require(Modules.Weapon.Controllers.BlasterController)
local TeamUtil = require(Modules.TeamUtil)
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
-- TeamCheck has to stay false: this game has no Team service sides, sides live in a
-- team attribute read by TeamUtil (Player.Team is nil for everyone, so the module
-- would drop every player). Enemies are filtered in GetClosest instead.
local aimconfig = {
    Range = 400,
    TeamCheck = false,
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
        ["NoRecoil"] = true
    }
}

local Aimbot = loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/Modules/Aimbot/main.lua"))()

Utils["Aimbot"].GetClosest = function(): (BasePart?)
    aimconfig["Origin"] = HumanoidRootPart.Position

    local Filtered = {}
    for _, Target in workspace:QueryDescendants("Model:has(Humanoid)") do
        if Target ~= Character and TeamUtil.areEnemies(LocalPlayer, Target) then
            table.insert(Filtered, Target)
        end
    end
    aimconfig["EntityLists"] = { Filtered }

    const Target, AimPart = Aimbot.GetClosest(aimconfig)

    return AimPart
end

if isfunctionhooked(BlasterController.shoot) then
    restorefunction(BlasterController.shoot)
end

local shoot; shoot = hookfunction(BlasterController.shoot, function(Controller)
    if config["Combat"]["InfiniteAmmo"] then
        Controller.ammo = Controller.stats.magazineSize
    end

    if not config["Combat"]["SilentAim"] then
        return shoot(Controller)
    end

    local AimPart = Utils["Aimbot"].GetClosest()

    if not AimPart then
        return shoot(Controller)
    end

    -- shoot() builds its rays from Workspace.CurrentCamera.CFrame AND sends that same
    -- CFrame to BlasterShoot:FireServer, so the camera itself has to look at the target
    -- for the local rays and the server's copy of them to agree.
    const Camera = Workspace.CurrentCamera
    const CameraCFrame = Camera.CFrame
    const AimDirection = AimPart.Position - CameraCFrame.Position

    if AimDirection.Magnitude < 1 then
        return shoot(Controller)
    end

    Camera.CFrame = CFrame.lookAt(CameraCFrame.Position, AimPart.Position, CameraCFrame.UpVector)
    local Result = shoot(Controller)
    Camera.CFrame = CameraCFrame

    return Result
end)

if isfunctionhooked(BlasterController.recoil) then
    restorefunction(BlasterController.recoil)
end

local recoil; recoil = hookfunction(BlasterController.recoil, function(Controller)
    if not config["Combat"]["NoRecoil"] then
        recoil(Controller)
    end
end)