local utils = {}

local Knit = shared.Knit
local services = Knit.services
local scriptmanager = Knit.scriptmanager

local Players = services.Players
local LocalPlayer = Players.LocalPlayer

utils.shouldredirect = function(hitchance: number): boolean
    return math.random(1, 100) <= hitchance
end

local Aimbot = Knit.require("Modules/Aimbot/v1", "main")

-- clans are this game's teams: no Teams service, it lives in a ClanId attribute
utils.GetClanId = function(Player: Player): string?
    return Player:GetAttribute("ClanId")
end

utils.IsTeammate = function(Player: Player): boolean
    local ClanId = utils.GetClanId(Player)
    return ClanId ~= nil and ClanId == utils.GetClanId(LocalPlayer)
end

utils.GetTargets = function(TeamCheck: boolean?)
    local Targets = Players:GetPlayers()
    if not TeamCheck then
        return Targets
    end

    local Filtered = {}
    for _, Player in Targets do
        if not utils.IsTeammate(Player) then
            table.insert(Filtered, Player)
        end
    end

    return Filtered
end

utils.GetClosest = function(SilentAim): (BasePart?, Instance?)
    local AimConfig = {
        Origin = workspace.CurrentCamera.CFrame.Position,
        Range = SilentAim.Range,
        Visible = SilentAim.Visible,
        -- keeps the first person viewmodel from blocking the line of sight
        Ignore = workspace.CurrentCamera,
        EntityLists = { utils.GetTargets(SilentAim.TeamCheck) },
    }

    -- check any available aimpart
    for _, Name in SilentAim.AimParts do
        AimConfig.AimPart = Name

        local Target, AimPart = Aimbot.GetTarget(AimConfig)
        if AimPart then
            return AimPart, Target
        end
    end

    return nil, nil
end

scriptmanager.set("utils", utils)

return utils