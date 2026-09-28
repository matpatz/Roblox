--// Knit
local Knit = shared.Knit

local services = Knit.services
local scriptmanager = Knit.scriptmanager

local utils = scriptmanager.get("utils")

--// Services
local ReplicatedStorage = services.ReplicatedStorage

--// Modules
local Gun = require(ReplicatedStorage.Modules.Controllers.WeaponController.Gun)

local config = scriptmanager.config.set(
    {
        SilentAim = {
            Value = true,
            Range = 1000,
            AimPart = "Head",
        },
    }
)

--// core
local core = {}

core = scriptmanager.set("core", core)


if isfunctionhooked(Gun.Fire) then
    restorefunction(Gun.Fire)
end

-- Fire builds both its ray and the Remotes.Weapons.Gun.Fire endpoint straight
-- from workspace.CurrentCamera, so pointing the camera at the target for the
-- duration of the call makes the game's own ray find the target and the server
-- receive a shot it would expect from someone who simply looked at them. The
-- camera is put back before the frame renders, so the view never moves.
local Old
Old = hookfunction(Gun.Fire, function(Self, ...)
    local AimPart = utils["Aimbot"].GetClosest(workspace.CurrentCamera.CFrame.Position)

    if not config.SilentAim.Value or not AimPart then
        return Old(Self, ...)
    end

    local Camera = workspace.CurrentCamera
    local CameraCFrame = Camera.CFrame

    Camera.CFrame = CFrame.lookAt(CameraCFrame.Position, AimPart.Position)
    Old(Self, ...)
    Camera.CFrame = CameraCFrame

    -- Fire sampled the camera for its spin tracking before returning; re-seed
    -- it from the real camera so the snap is not recorded as a 360
    local LookVector = CameraCFrame.LookVector
    Self.ThreesixtyYawLast = math.atan2(LookVector.X, LookVector.Z)
    Self.ThreesixtyYawDegrees = 0
    Self.ThreeSixtyWindowStart = 0
end)

return core
