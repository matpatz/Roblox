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
            WallCheck = false,
            Wallbang = false,
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

    if config.SilentAim.Value and AimPart and Target then
        local Offset = AimPart.Position - Origin.Position
        local Direction = Offset.Unit

        local Range = Directions[1].Magnitude
        for Index = 1, #Directions do
            Directions[Index] = Direction * Range
        end

        if config.SilentAim.Wallbang and not (ShootParams and ShootParams.isRocket) then
            -- claim the hit on the target, so a wall in the way does not matter
            table.clear(Results)
            for Index = 1, math.max(#Directions, 1) do
                Results[Index] = {
                    distance = Offset.Magnitude,
                    normal = -Direction,
                    instance = AimPart,
                    taggedEntityId = Target:GetAttribute("EntityId"),
                    isTeammate = false,
                }
            end
        elseif BlasterUtility and not (ShootParams and ShootParams.isRocket) then
            -- otherwise report the same cast the game would have made for this
            -- direction, so nothing about the hit looks out of place
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

    return Old(Self, Origin, Directions, Results, ShootParams, ...)
end)

return core
