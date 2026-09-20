local utils = {
    ["Aimbot"] = {},
}

local Knit = shared.Knit
local services = Knit.services
local scriptmanager = Knit.scriptmanager
local playermanager = Knit.player

--// services
local Players = services.Players
local LocalPlayer = Players.LocalPlayer

local Aimbot = Knit.require("Modules/Aimbot/v1", "main")

-- the game's own faction test, the same gate its auto aim uses to pick targets
local IsFoeFaction = filtergc("function", { Name = "IsFoeFaction" }, true)

-- // config
-- core owns the config and loads after utils, so it is read per call
local function Setting(Key: string)
    local Config = scriptmanager.config.get()
    local Feature = Config and Config["SilentAim"]
    if type(Feature) ~= "table" then
        return nil
    end

    return Feature[Key]
end

-- // Utils

-- The game tags every character, bot and monster with EntityId / EntityType /
-- EntityState / CurHp attributes (the game's CustomEnum.EntityType: 1 player,
-- 2 monster, 0 = air drops and containers, which are not shootable targets).
local ENTITY_TYPES = { 1, 2 }

-- head first, then the parts the game's own aim assist falls back to
local AIM_PART_FALLBACKS = { "UpperTorso", "Torso", "HumanoidRootPart" }

utils["Aimbot"].IsAlive = function(Model: Model): boolean
    -- entity models carry CurHp; anything without it falls back to the Humanoid
    local CurrentHealth = Model:GetAttribute("CurHp")
    if type(CurrentHealth) == "number" then
        return CurrentHealth > 0
    end

    local Humanoid = Model:FindFirstChildOfClass("Humanoid")
    return Humanoid ~= nil and Humanoid.Health > 0
end

utils["Aimbot"].IsTeammate = function(Model: Model): boolean
    if Setting("TeamCheck") == false then
        return false
    end

    local Player = Players:GetPlayerFromCharacter(Model)
    if Player and Player.Team and LocalPlayer.Team then
        return Player.Team == LocalPlayer.Team
    end

    -- a bot owns no player, so the TeamId attribute is the only team left
    local Character = playermanager.Character
    local LocalTeamId = Character and Character:GetAttribute("TeamId")
    local TargetTeamId = Model:GetAttribute("TeamId")

    return LocalTeamId ~= nil and LocalTeamId == TargetTeamId
end

-- Only the game's own check knows who is a foe. The Team/TeamId compare above
-- is the fallback for when the function is not around.
utils["Aimbot"].IsEnemy = function(Model: Model): boolean
    if IsFoeFaction then
        return IsFoeFaction(Model) == true
    end

    return not utils["Aimbot"].IsTeammate(Model)
end

utils["Aimbot"].GetTargets = function(): { Instance }
    local Enemies: { Instance } = {}
    local Character = playermanager.Character

    -- the local player's own entity id is their UserId
    local MyEntityId = LocalPlayer.UserId

    for _, Model in workspace:QueryDescendants("Model") do
        local EntityId = Model:GetAttribute("EntityId")
        if EntityId == nil or EntityId == MyEntityId or Model == Character then
            continue
        end

        if not table.find(ENTITY_TYPES, Model:GetAttribute("EntityType")) then
            continue
        end

        if not utils["Aimbot"].IsAlive(Model) then
            continue
        end

        if not utils["Aimbot"].IsEnemy(Model) then
            continue
        end

        table.insert(Enemies, Model)
    end

    return Enemies
end

local aimconfig = {
    Origin = nil,
    Range = 1000,
    TeamCheck = false, -- already filtered in GetTargets
    AimPart = "Head",
    Visible = false, -- wallbang: the module must not require line of sight
    EntityLists = {},
}

-- Closest aim part to an origin. Returns (aim part, target model).
utils["Aimbot"].GetClosest = function(OriginPosition: Vector3): (BasePart?, Instance?)
    aimconfig["Origin"] = OriginPosition
    aimconfig["Range"] = Setting("Range") or 1000
    aimconfig["Visible"] = Setting("WallCheck") == true
    aimconfig["EntityLists"] = {
        utils["Aimbot"].GetTargets()
    }

    local AimParts = { Setting("AimPart") or "Head" }
    for _, Name in AIM_PART_FALLBACKS do
        table.insert(AimParts, Name)
    end

    -- the module drops targets without the configured part, so the rig
    -- fallbacks above get a second pass instead of being filtered out
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
