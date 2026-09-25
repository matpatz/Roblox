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

--// variables
local PrivateEnemies = workspace.PrivateEnemies

-- // Utils

utils["Aimbot"].GetTargets = function(): { Instance }
    local Enemies: { Instance } = {}

    for _, Enemy in PrivateEnemies:GetChildren() do
        table.insert(Enemies, Enemy)
    end

    return Enemies
end

utils["Aimbot"].GetTarget = function(): Model
    local Enemies = utils["Aimbot"].GetTargets()

    local Enemy = Enemies[math.random(1, #Enemies)]
    return Enemy
end

local aimconfig = {}

utils["Aimbot"].GetClosest = function(): (BasePart?, Instance?)
    local Config = scriptmanager.config.get().KillAura

    aimconfig["Origin"] = playermanager.HumanoidRootPart.CFrame
    aimconfig["Range"] = Config.Range
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

utils.Reload = function(Remote: RemoteEvent, Blaster)
    Remote:FireServer(Blaster)
end

scriptmanager.set("utils", utils)

return utils
