--// Knit
local Knit = shared.Knit

local services = Knit.services
local scriptmanager = Knit.scriptmanager
local playermanager = Knit.player

local utils = scriptmanager.get("utils")

local name = scriptmanager.name
local config = scriptmanager.config.set(
    {
        SilentAim = {
            Value = false
        }
    }
)

--// Services
local ReplicatedStorage = services.ReplicatedStorage
local Players = services.Players

--// Events
local FireEvent = ReplicatedStorage:WaitForChild("networkEvents"):WaitForChild("rE")

--// player
local LocalPlayer = playermanager.LocalPlayer

--// core
local core = {}

core = scriptmanager.set("core", core)

--// Silent aim

if isfunctionhooked(FireEvent.FireServer) then
    restorefunction(FireEvent.FireServer)
end

local Old; Old = hookfunction(FireEvent.FireServer, function(Self, ...)
    if Self ~= FireEvent or not config.SilentAim.Value then
        return Old(Self, ...)
    end

    local AimPart = utils["Aimbot"].GetClosest()
    local HumanoidRootPart = playermanager.HumanoidRootPart

    if not AimPart or not HumanoidRootPart then
        return Old(Self, ...)
    end

    local Args = table.pack(...)

    Args[3] = AimPart
    Args[4] = AimPart.Position
    Args[5] = (AimPart.Position - HumanoidRootPart.Position).Unit
    Args[6] = AimPart.Material

    return Old(Self, table.unpack(Args, 1, Args.n))
end)

return core