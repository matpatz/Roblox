local utils = {}

local Knit = shared.Knit
local services = Knit.services
local scriptmanager = Knit.scriptmanager

local LocalPlayer = services.Players.LocalPlayer

local Aimbot = Knit.require("Modules/Aimbot/v1", "main")

local RANGE = 1000
local AIM_PARTS = { "Head", "UpperTorso", "Torso", "HumanoidRootPart" }

-- every other player's character; no team check
utils.GetTargets = function(): { Model }
    local Targets = {}

    for _, Player in services.Players:GetPlayers() do
        if Player == LocalPlayer then
            continue
        end

        local Character = Player.Character
        if not Character then
            continue
        end

        table.insert(Targets, Character)
    end

    return Targets
end

utils.GetClosest = function(OriginPosition: Vector3?): (BasePart?, Instance?)
    local Origin = workspace.CurrentCamera.CFrame.Position

    local AimConfig = {
        Origin = Origin,
        Range = RANGE,
        Visible = true,
        -- keeps the first person viewmodel from blocking the line of sight
        Ignore = workspace.CurrentCamera,
        EntityLists = { utils.GetTargets() },
    }

    for _, Name in AIM_PARTS do
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