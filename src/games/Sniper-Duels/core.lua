--// Knit
local Knit = shared.Knit

local services = Knit.services
local scriptmanager = Knit.scriptmanager

local utils = scriptmanager.get("utils")

--// Services
local ReplicatedStorage = services.ReplicatedStorage

--// Modules
local Gun = require(ReplicatedStorage.Modules.Controllers.WeaponController.Gun)
local MultiRaycast = require(ReplicatedStorage.Modules.Misc.MultiRaycast)

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

if isfunctionhooked(MultiRaycast) then
    restorefunction(MultiRaycast)
end

-- Fire ends its shot packet at the last hit of its own ray (v73 = last.Instance.Position)
-- and reports that same part, so the bullet is redirected by re-aiming the ray it
-- casts. The camera is never moved - the view stays exactly where the player points it.
local AimPart: BasePart?

local OldFire
OldFire = hookfunction(Gun.Fire, function(Self, ...)
    AimPart = nil

    if config.SilentAim.Value then
        AimPart = utils["Aimbot"].GetClosest(workspace.CurrentCamera.CFrame.Position)
    end

    local Results = OldFire(Self, ...)

    AimPart = nil

    return Results
end)

local OldMultiRaycast
OldMultiRaycast = hookfunction(MultiRaycast, function(OriginPosition, Direction, RaycastParams, ...)
    if AimPart then
        Direction = (AimPart.Position - OriginPosition).Unit * Direction.Magnitude
    end

    return OldMultiRaycast(OriginPosition, Direction, RaycastParams, ...)
end)

return core
