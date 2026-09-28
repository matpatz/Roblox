local utils = {
    ["Aimbot"] = {},
}

local Knit = shared.Knit
local services = Knit.services
local scriptmanager = Knit.scriptmanager

--// services
local Players = services.Players
local LocalPlayer = Players.LocalPlayer

local Aimbot = Knit.require("Modules/Aimbot/v1", "main")

-- // Utils

utils["Aimbot"].GetTargets = function(): { Instance }
    local LocalCharacter = LocalPlayer.Character
    local LocalContainer = LocalCharacter and LocalCharacter.Parent
    local Characters = workspace.Characters
    local Enemies: { Instance } = {}

    for _, Player in Players:GetPlayers() do
        local Character = Player.Character

        if Player == LocalPlayer or not Character or not Character.Parent then
            continue
        end

        -- teammates share a team container; in FFA every character hangs
        -- directly off workspace.Characters
        if Character.Parent == LocalContainer and LocalContainer ~= Characters then
            continue
        end

        table.insert(Enemies, Character)
    end

    return Enemies
end

local aimconfig = {}

utils["Aimbot"].GetClosest = function(OriginPosition: Vector3): (BasePart?, Instance?)
    local Config = scriptmanager.config.get().SilentAim

    aimconfig["Origin"] = OriginPosition
    aimconfig["Range"] = Config.Range
    -- the module does the line of sight check itself. The camera has no such
    -- property as workspace.Camera, and the first-person viewmodel hangs off
    -- workspace.CurrentCamera (which is why Fire filters it), so the ignore list
    -- has to exclude the real camera or every ray stops on the viewmodel
    aimconfig["Visible"] = true
    aimconfig["Ignore"] = workspace.CurrentCamera
    aimconfig["EntityLists"] = { utils["Aimbot"].GetTargets() }

    local AimParts = { Config.AimPart, "UpperTorso", "Torso", "HumanoidRootPart" }

    for _, Name in AimParts do
        aimconfig["AimPart"] = Name

        local Target, AimPart = Aimbot.GetTarget(aimconfig)
        if AimPart then
            return AimPart, Target
        end
    end

    return nil, nil
end

scriptmanager.set("utils", utils)

return utils
