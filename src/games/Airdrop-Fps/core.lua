--// Knit
local Knit = shared.Knit

local services = Knit.services
local scriptmanager = Knit.scriptmanager

local utils = scriptmanager.get("utils")

--// Services
local ReplicatedStorage = services.ReplicatedStorage

--// Modules
local Blaster = require(ReplicatedStorage.Scripts.Model.Blaster)
local BlasterUtility = require(ReplicatedStorage.Scripts.Util.BlasterUtility)

local LocalPlayer = services.Players.LocalPlayer

--// Variables

local SendShootReq = Blaster.SendShootReq
local castRays = BlasterUtility.castRays

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


if isfunctionhooked(SendShootReq) then
    restorefunction(SendShootReq)
end

local Old
Old = hookfunction(SendShootReq, function(Self, Origin, Directions, Results, ShootParams, ...)
    local AimPart, Target = utils["Aimbot"].GetClosest(Origin.Position)

    if config.SilentAim.Value and AimPart and Target then
        local Offset = AimPart.Position - Origin.Position
        local Direction = Offset.Unit

        if Origin.LookVector:Dot(Direction) > 0 then
            local Range = Directions[1].Magnitude
            for Index = 1, #Directions do
                Directions[Index] = Direction * Range
            end

            if not (ShootParams and ShootParams.isRocket) then
                local Hits = castRays(LocalPlayer, Origin.Position, Directions, Self:GetRayRadius())

                table.clear(Results)
                for Index, Hit in Hits do
                    if Hit.taggedEntityId then
                        Hit.isTeammate = Self:IsTeammate(Hit.taggedEntityId)
                    end

                    Results[Index] = Hit
                end
            end
        end
    end

    return Old(Self, Origin, Directions, Results, ShootParams, ...)
end)

return core
