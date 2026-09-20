--// Knit
local Knit = shared.Knit

local scriptmanager = Knit.scriptmanager

local utils = scriptmanager.get("utils")

local config = scriptmanager.config.set(
    {
        SilentAim = {
            Value = true,
            Range = 1000,
            AimPart = "Head",
            TeamCheck = true,
            WallCheck = false,
            Wallbang = true,
        },
    }
)

--// core
local core = {}

core = scriptmanager.set("core", core)

local SendShootReq = filtergc("function", {
        Name = "SendShootReq",
        Constants = {"blasterUid", "rayDirections", "rayResults"}
    },
    true
)

if isfunctionhooked(SendShootReq) then
    restorefunction(SendShootReq)
end

local OldShootReq
OldShootReq = hookfunction(SendShootReq, function(Self, Origin, Directions, Results, ShootParams, ...)
    local AimPart, Target = utils["Aimbot"].GetClosest(Origin.Position)

    if config.SilentAim.Value and AimPart and Target then
        local Offset = AimPart.Position - Origin.Position
        local Direction = Offset.Unit

        -- silent aim: every pellet is sent at the aim part, not the crosshair.
        -- the origin stays the game's own camera CFrame - a moved origin is the
        -- one thing a server check can throw the whole request away for
        local Range = Directions[1].Magnitude
        for Index = 1, #Directions do
            Directions[Index] = Direction * Range
        end

        -- rockets fly their own projectile, the results are for hitscan only
        if config.SilentAim.Wallbang and not (ShootParams and ShootParams.isRocket) then
            -- wallbang: the hit is reported as the target, so it lands even when
            -- a wall stopped the ray the client cast at the crosshair
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
        end
    end

    return OldShootReq(Self, Origin, Directions, Results, ShootParams, ...)
end)

return core
