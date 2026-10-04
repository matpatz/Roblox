--// Knit
local Knit = shared.Knit

local services = Knit.services
local scriptmanager = Knit.scriptmanager

local utils = scriptmanager.get("utils")

--// Services
local ReplicatedStorage = services.ReplicatedStorage

--// Modules
local CameraController = require(ReplicatedStorage.Client.CameraController)
local ClientShootableComponent = require(ReplicatedStorage.Client.CombatController.ClientComponent.ClientShootableComponent)

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

local CombatOriginFn = debug.getupvalue(ClientShootableComponent.Shoot, 2)

assert(CombatOriginFn, "core: CameraController origin closure not found")

if isfunctionhooked(CombatOriginFn) then
    restorefunction(CombatOriginFn)
end

local Old
Old = hookfunction(CombatOriginFn, function(...)
    local Origin, DetectAt, Info = Old(...)

    if not (config.SilentAim.Value and typeof(Origin) == "CFrame") then
        return Origin, DetectAt, Info
    end

    local AimPart = utils["Aimbot"].GetClosest(Origin)

    if not AimPart then
        return Origin, DetectAt, Info
    end

    return CFrame.lookAt(Origin.Position, AimPart.Position), DetectAt, Info
end)

return core
