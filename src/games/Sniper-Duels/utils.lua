local utils = {
    ["Aimbot"] = {},
}

local Knit = shared.Knit
local services = Knit.services
local scriptmanager = Knit.scriptmanager

--// services
local ReplicatedStorage = services.ReplicatedStorage

local EntityService = require(ReplicatedStorage.Remote.EntityService)
local HumanoidEntity = require(ReplicatedStorage.Remote.EntityService.Entity.HumanoidEntity)

local Aimbot = Knit.require("Modules/Aimbot/v1", "main")

-- // Utils

-- the rewrite dropped the workspace.Characters container: rooms are separate
-- worlds and everyone in the server hangs straight off workspace, so the focused
-- world is the only safe pool. ForeachEnemies already drops the local player and
-- anyone sharing our team
utils["Aimbot"].GetTargets = function(): { Instance }
    local Enemies: { Instance } = {}

    local LocalEntity = EntityService.GetLocalEntity()
    local World = EntityService.WorldManager.GetFocusedWorld()

    if not World then
        return Enemies
    end

    World:ForeachEnemies(LocalEntity, function(Entity)
        if HumanoidEntity:is(Entity) and Entity:IsAlive() then
            table.insert(Enemies, Entity.Instance)
        end
    end)

    return Enemies
end

local aimconfig = {}

-- Origin is the shot's CFrame rather than a bare position: the module needs its
-- orientation to be able to reject anything behind the player
utils["Aimbot"].GetClosest = function(Origin: CFrame): (BasePart?, Instance?)
    local Config = scriptmanager.config.get().SilentAim

    aimconfig["Origin"] = Origin
    aimconfig["Range"] = Config.Range
    -- the module does the visibility check itself: the target has to be in front
    -- of this CFrame's view and unobstructed. The first-person viewmodel hangs off
    -- workspace.CurrentCamera, so the ignore list has to exclude the real camera
    -- or every ray stops on the viewmodel
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
