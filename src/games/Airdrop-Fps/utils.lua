local utils = {
    ["Aimbot"] = {},
}

local Knit = shared.Knit
local services = Knit.services
local scriptmanager = Knit.scriptmanager
local playermanager = Knit.player

--// services
local LocalPlayer = services.Players.LocalPlayer

local Aimbot = Knit.require("Modules/Aimbot/v1", "main")

local PlayerHelper = filtergc("table", { Keys = { "IsFoeFaction" } }, true)

-- // Utils

-- 1 player, 2 monster, 0 = air drops) -- whats a monster? not sure.
local ENTITY_TYPES = { 1, 2 }

utils["Aimbot"].GetTargets = function(): { Instance }
    local Enemies: { Instance } = {}
    local Character = playermanager.Character

    for _, Model in workspace:QueryDescendants("Model") do
        local EntityId = Model:GetAttribute("EntityId")
        if EntityId == nil or EntityId == LocalPlayer.UserId or Model == Character then
            continue
        end

        if not table.find(ENTITY_TYPES, Model:GetAttribute("EntityType")) then
            continue
        end

        if (Model:GetAttribute("CurHp") or 0) <= 0 then
            continue
        end

        if PlayerHelper and not PlayerHelper.IsFoeFaction(Model) then
            continue
        end

        table.insert(Enemies, Model)
    end

    return Enemies
end

local aimconfig = {}

utils["Aimbot"].GetClosest = function(OriginPosition: Vector3): (BasePart?, Instance?)
    local Config = scriptmanager.config.get().SilentAim

    aimconfig["Origin"] = OriginPosition
    aimconfig["Range"] = Config.Range
    aimconfig["Visible"] = Config.WallCheck
    aimconfig["EntityLists"] = {
        utils["Aimbot"].GetTargets()
    }

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
