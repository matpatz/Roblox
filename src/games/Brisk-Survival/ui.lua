local Knit = shared.Knit
local ui = Knit.ui
local scriptmanager = Knit.scriptmanager
local services = Knit.services

local name = scriptmanager.name

local config = scriptmanager.config.get()

--// Services
local CollectionService = services.CollectionService

local Lighting = game:GetService("Lighting")

-- // Workspace
--[[ sentinels
    parented simply under workspace
    model
    has a BriskRuntimeSentinel tag
    the SentinelWreck attribute should be false
]]

local SpawnedHarvestables = workspace.SpawnedHarvestables
    -- IronOre, NitrateOre, Stone
        -- all models

local PlacedDeployables = workspace.PlacedDeployables
    -- totems (theyre named Flag and theyre models here)

--[[ backpacks
    parented simply under workspace
    named DroppedContainer
    model with 5 children all parts (idk how many desendants)
    have a InventoryContainer tag
]]

local Amghook = ui.new("Amongus-hook")()

local Esp = Knit.require("Libraries/Esp/v2", "main")

local Window = Amghook.windowClass.new({
    title = name,
    size = Vector2.new(600, 500),
})

local flags = Window.flags
config.flags = flags

local tabs = {
    combat = Window:addTab("Combat"),
    visuals = Window:addTab("Visuals"),
    world = Window:addTab("World"),
    ui = Window:addTab("ui"),
}

local function mdiv(tab)
    tabs[tab].offsets[1] += 16 
end

--// Combat

tabs["combat"]:addToggle({
    text = "Silent Aim",
    default = false,
    flag = "SilentAim",
}, 1)

tabs["combat"]:addSlider({
    text = "hitchance",
    min = 1,
    max = 100,
    default = 100,
    increment = 1,
    suffix = "%",
    flag = "SilentAim.hitchance",
}, 1)

Window.flags["SilentAim.hitchance"]:OnChanged(function(value)
    config.SilentAim.hitchance = value
end)

tabs["combat"]:addSlider({
    text = "range",
    min = 50,
    max = 600,
    default = 400,
    increment = 10,
    suffix = " studs",
    flag = "SilentAim.Range",
}, 1)

Window.flags["SilentAim.Range"]:OnChanged(function(value)
    config.SilentAim.Range = value
end)

-- aimpart

tabs["combat"]:addToggle({
    text = "Visible Check",
    default = true,
    flag = "SilentAim.Visible",
}, 1)

Window.flags["SilentAim.Visible"]:OnChanged(function(value)
    config.SilentAim.Visible = value
end)

tabs["combat"]:addToggle({
    text = "Team Check",
    default = true,
    flag = "SilentAim.TeamCheck",
}, 1)

Window.flags["SilentAim.TeamCheck"]:OnChanged(function(value)
    config.SilentAim.TeamCheck = value
end)

--// Target HUD

local core = scriptmanager.get("core")

core.TargetHUD = Amghook.targethudClass.new({
    active = false,
})

--// Visuals

-- v2 hands back the class, so each system gets its own instance (own settings,
-- own targets, own Highlight folder) instead of sharing one global config.
local function newEsp(Name: string, Extra: { [string]: any }?)
    local Config = {
        Name = Name,
        ShowBox = false,
        ShowHeld = false,
        ShowTracer = false,
        Containers = {},
    }

    for Key, Value in next, Extra or {} do
        Config[Key] = Value
    end

    return Esp.new(Config)
end

local PlayerEsp = newEsp("PlayerESP", {
    Containers = {
        Players = { Location = services.Players },
    },
})

tabs["visuals"]:addToggle({
    text = "player esp",
    default = false,
    flag = "playeresp",
}, 1)

tabs["visuals"]:addToggle({
    text = "tracer",
    default = false,
    flag = "playeresp.tracer",
}, 1)

tabs["visuals"]:addToggle({
    text = "distance",
    default = false,
    flag = "playeresp.distance",
}, 1)

tabs["visuals"]:addToggle({
    text = "weapon",
    default = false,
    flag = "playeresp.weapon",
}, 1)

tabs["visuals"]:addToggle({
    text = "health",
    default = false,
    flag = "playeresp.health",
}, 1)

tabs["visuals"]:addToggle({
    text = "chams",
    default = false,
    flag = "playeresp.chams",
}, 1)

tabs["visuals"]:addToggle({
    text = "perf mode",
    default = false,
    flag = "playeresp.perf",
}, 1)

local function espOption(Instance, flag: string, property: string)
    flags[flag]:OnChanged(function(value)
        Instance:SetProperty(property, value)
    end)
end

espOption(PlayerEsp, "playeresp.tracer", "ShowTracer")
espOption(PlayerEsp, "playeresp.distance", "ShowDistance")
espOption(PlayerEsp, "playeresp.weapon", "ShowHeld")
espOption(PlayerEsp, "playeresp.health", "ShowHealth")
espOption(PlayerEsp, "playeresp.chams", "ShowChams")
espOption(PlayerEsp, "playeresp.perf", "PerformanceMode")

flags["playeresp"]:OnChanged(function(value)
    if value then
        PlayerEsp:Enable()
    else
        PlayerEsp:Disable()
    end
end)

--// Sentinel esp
mdiv("visuals")

tabs["visuals"]:addToggle({
    text = "sentinel esp",
    default = false,
    flag = "sentinelesp",
}, 1)

tabs["visuals"]:addToggle({
    text = "tracer",
    default = false,
    flag = "sentinelesp.tracer",
}, 1)

tabs["visuals"]:addToggle({
    text = "distance",
    default = false,
    flag = "sentinelesp.distance",
}, 1)

-- they have a BodyHealth and BodyMaxHealth attribute
tabs["visuals"]:addToggle({
    text = "health",
    default = false,
    flag = "sentinelesp.health",
}, 1)

-- use the Body:MeshPart
tabs["visuals"]:addToggle({
    text = "chams",
    default = false,
    flag = "sentinelesp.chams",
}, 1)

tabs["visuals"]:addToggle({
    text = "perf mode",
    default = false,
    flag = "sentinelesp.perf",
}, 1)

local SentinelEsp = newEsp("SentinelESP", {
    MaxDist = 1000,
    Containers = {
        Sentinels = {
            Tag = "BriskRuntimeSentinel",
            -- wrecked ones keep the tag, so both markers have to be checked
            Filter = function(Model)
                return Model:GetAttribute("SentinelDead") ~= true
                    and Model:GetAttribute("SentinelWreck") ~= true
            end,
            Target = "BasePart:Body",
            HealthAttribute = "BodyHealth",
            MaxHealthAttribute = "BodyMaxHealth",
            Color = Color3.fromRGB(255, 120, 0),
        },
    },
})

espOption(SentinelEsp, "sentinelesp.tracer", "ShowTracer")
espOption(SentinelEsp, "sentinelesp.distance", "ShowDistance")
espOption(SentinelEsp, "sentinelesp.health", "ShowHealth")
espOption(SentinelEsp, "sentinelesp.chams", "ShowChams")
espOption(SentinelEsp, "sentinelesp.perf", "PerformanceMode")

flags["sentinelesp"]:OnChanged(function(value)
    if value then
        SentinelEsp:Enable()
    else
        SentinelEsp:Disable()
    end
end)

-- // Entity Esp

tabs["visuals"]:addToggle({
    text = "entity esp",
    default = false,
    flag = "entityesp",
}, 2)

tabs["visuals"]:addToggle({
    text = "distance",
    default = false,
    flag = "entityesp.distance",
}, 2)

tabs["visuals"]:addToggle({
    text = "chams",
    default = false,
    flag = "entityesp.chams",
}, 2)

tabs["visuals"]:addToggle({
    text = "perf mode",
    default = false,
    flag = "entityesp.perf",
}, 2)

tabs["visuals"]:addToggle({
    text = "nitrate esp",
    default = false,
    flag = "entityesp.nitrate",
}, 2)

tabs["visuals"]:addToggle({
    text = "stone esp",
    default = false,
    flag = "entityesp.stone",
}, 2)

tabs["visuals"]:addToggle({
    text = "iron esp",
    default = false,
    flag = "entityesp.iron",
}, 2)

tabs["visuals"]:addToggle({
    text = "totem esp",
    default = false,
    flag = "entityesp.totem",
}, 2)

tabs["visuals"]:addToggle({
    text = "backpack esp",
    default = false,
    flag = "entityesp.backpack",
}, 2)

local EntityEsp = newEsp("EntityESP", {
    MaxDist = 800,
})

local function harvestable(Name: string, Color: Color3)
    return {
        Location = SpawnedHarvestables,
        Filter = function(Model)
            return Model.Name == Name
        end,
        Color = Color,
    }
end

local EntityTypes = {
    {
        key = "iron",
        containers = {
            IronOre = harvestable("IronOre", Color3.fromRGB(205, 205, 215)),
        },
    },
    {
        key = "stone",
        containers = {
            Stone = harvestable("Stone", Color3.fromRGB(150, 150, 150)),
        },
    },
    {
        key = "nitrate",
        containers = {
            NitrateOre = harvestable("NitrateOre", Color3.fromRGB(120, 200, 255)),
        },
    },
    {
        key = "totem",
        containers = {
            Totems = {
                Location = PlacedDeployables,
                Filter = function(Model)
                    return Model.Name == "Flag" or Model.Name == "AdvancedFlag"
                end,
                Color = Color3.fromRGB(255, 200, 80),
            },
        },
    },
    {
        key = "backpack",
        containers = {
            Backpacks = {
                -- dropped containers are tagged but parented straight to workspace,
                -- the deployables that also carry InventoryContainer are not
                Location = workspace,
                Filter = function(Model)
                    return Model:HasTag("InventoryContainer")
                end,
                Color = Color3.fromRGB(255, 140, 220),
            },
        },
    },
}

local EntityMaster = false
local EntityTypeFlags = {}

-- Rebuilds the container map from the toggles. Clear() drops the targets of an
-- off system instead of leaving a few thousand hidden drawings behind.
local function refreshEntityEsp()
    local Containers = {}

    for _, Type in next, EntityTypes do
        if EntityMaster and EntityTypeFlags[Type.key] then
            for Name, Definition in next, Type.containers do
                Containers[Name] = Definition
            end
        end
    end

    if not next(Containers) then
        EntityEsp:Clear()
        return
    end

    EntityEsp:SetContainer(Containers)
    EntityEsp:Enable()
end

for _, Type in next, EntityTypes do
    flags[`entityesp.{Type.key}`]:OnChanged(function(value)
        EntityTypeFlags[Type.key] = value
        refreshEntityEsp()
    end)
end

flags["entityesp"]:OnChanged(function(value)
    EntityMaster = value
    refreshEntityEsp()
end)

espOption(EntityEsp, "entityesp.distance", "ShowDistance")
espOption(EntityEsp, "entityesp.chams", "ShowChams")
espOption(EntityEsp, "entityesp.perf", "PerformanceMode")

--// World

tabs["world"]:addToggle({
    text = "Ambient",
    default = false,
    flag = "ambinece",
}, 1)

local ambient = core.World["ambinece"]

flags["ambinece"]:OnChanged(function(value)
    -- off: flush the value the game last tried to write, since it was blocked
    Lighting.Ambient = value and Color3.new(1, 1, 1) or ambient.value
end)

--// Ui

tabs["ui"]:addButton("Close", function()
    cleardrawcache()
end, 1)
