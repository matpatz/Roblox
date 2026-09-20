--// Knit
local Knit = shared.Knit

local scriptmanager = Knit.scriptmanager
local playermanager = Knit.player

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

local OldShootReq
OldShootReq = hookfunction(SendShootReq, function(Self, Origin, Directions, Results, ShootParams, ...)
    local AimPart, Target = utils["Aimbot"].GetClosest(Origin.Position)

    if config.SilentAim.Value and AimPart and Target then
        local Offset = AimPart.Position - Origin.Position
        local Direction = Offset.Unit

        -- silent aim: every pellet is sent at the aim part, not the crosshair
        local Range = Directions[1].Magnitude
        for Index = 1, #Directions do
            Directions[Index] = Direction * Range
        end

        -- rockets fly their own projectile, the results are for hitscan only
        if not (ShootParams and ShootParams.isRocket) then
            -- wallbang: claim the target even when geometry stopped the ray
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

            if config.SilentAim.Wallbang then
                local RaycastParams = RaycastParams.new()
                RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
                RaycastParams.FilterDescendantsInstances = { Target, playermanager.Character }

                local Blocked = workspace:Raycast(Origin.Position, Offset, RaycastParams)

                -- the server casts from this origin too: a blocked shot is started
                -- right in front of the target instead of behind the wall
                if Blocked and not Blocked.Instance:IsDescendantOf(Target) then
                    Origin = CFrame.lookAt(AimPart.Position - Direction, AimPart.Position + Direction)
                end
            end
        end
    end

    return OldShootReq(Self, Origin, Directions, Results, ShootParams, ...)
end)

return core
