--// Knit
local Knit = shared.Knit

local services = Knit.services
local scriptmanager = Knit.scriptmanager

local utils = scriptmanager.get("utils")

local LocalPlayer = services.Players.LocalPlayer

local config = scriptmanager.config.set(
    {
        SilentAim = {
            Value = true,
            Range = 1000,
            AimPart = "Head",
            WallCheck = true,
        },
    }
)

--// core
local core = {}

core = scriptmanager.set("core", core)

-- the game's own bullet cast, used to report the hit for our direction
local BlasterUtility = filtergc("table", { Keys = { "castRays" } }, true)

local SendShootReq = filtergc("function", {
        Name = "SendShootReq",
        Constants = {"blasterUid", "rayDirections", "rayResults"}
    },
    true
)

if isfunctionhooked(SendShootReq) then
    restorefunction(SendShootReq)
end

local Old
Old = hookfunction(SendShootReq, function(Self, Origin, Directions, Results, ShootParams, ...)
    local AimPart, Target = utils["Aimbot"].GetClosest(Origin.Position)

    -- the server resolves the hit from the direction, so only fire at something
    -- the camera is actually facing - a shot pointing behind you hits nothing
    if config.SilentAim.Value and AimPart and Target then
        local Offset = AimPart.Position - Origin.Position
        local Direction = Offset.Unit

        if Origin.LookVector:Dot(Direction) > 0 then
            -- silent aim: every pellet is sent at the aim part, not the crosshair
            local Range = Directions[1].Magnitude
            for Index = 1, #Directions do
                Directions[Index] = Direction * Range
            end

            -- report the cast the game would have made for these directions, so
            -- packet and local VFX agree
            if BlasterUtility and not (ShootParams and ShootParams.isRocket) then
                local Hits = BlasterUtility.castRays(LocalPlayer, Origin.Position, Directions, Self:GetRayRadius())

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
