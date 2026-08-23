-- open source
-- SLOP ai SLOPPPPP

const Config = {
    DEBUG = true,
    Prefix = "[Debug]",
    ErrorCodes = {
        [1] = "Incorrect Environment detected. Please run inside an Actor.",
        [2] = "A major game update has been detected. Script execution aborted.",
        [3] = "Internal Script Error. Please DM #matpatz on Discord for support."
    },
}

local Logger = {}
do
    function Logger:Info(...)
        print(Config.Prefix, ...)
    end

    function Logger:Error(code,...)
        local msg = Config.ErrorCodes[code] or "Unknown error"

        if Config.DEBUG then
            Logger:Info(msg,...)
        else
            task.spawn(error, Config.Prefix .. " " .. msg)
        end
    end
end

const Services = loadstring(game:HttpGet(
    "https://website-iota-ivory-12.vercel.app/code/Modules/Services.lua"
))()

const Environment = getrenv()._G

const __index = getrawmetatable(Environment).__index

if not __index then
	Logger:Error(2)
end

const Upvalues = debug.getupvalues(__index)

if not Upvalues then
	Logger:Error(2, "no upvalues")
end

const Classes = Upvalues[10][2]

if not Classes then
	Logger:Error(2, "no classes")
end

-- Classes
local function GetClass(Key)
    return Classes[Key]
end

const Character = GetClass("Character")
const Camera = GetClass("Camera")
const RangedWeaponClient = GetClass("RangedWeaponClient")
const EntityClient = GetClass("EntityClient")
const TrollyClient = GetClass("TrollyClient")
const DrillClient = GetClass("MiningDrillClient")

const LocalCharacter = workspace.Const.Ignore.LocalCharacter

const Heartbeat = Services.RunService.Heartbeat
const RenderStepped = Services.RunService.RenderStepped

local cheat = {
    connections = {
        heartbeats = {},
        renderstepped = {},
        runtime = {},
        misc = {},
    },
    drawings = {
        crosshair = {
            Drawing
        },
        esp = {},
    },
    hooks = {},
    metahooks = {},
    Utils = {},
    Core = {},
}; local connections, drawings, hooks, metahooks, Utils, Core =
    cheat.connections, cheat.drawings, cheat.hooks, cheat.metahooks, cheat.Utils, cheat.Core

do
	Utils.AddConnection = function(Category, Name, Connection)
		if Category[Name] then
			pcall(function()
				if typeof(Category[Name]) == "RBXScriptConnection" then
					Category[Name]:Disconnect()
				else
					task.cancel(Category[Name])
				end
			end)
		end

		Category[Name] = Connection
		connections.runtime[Name] = true
	end

	Utils.RemoveConnection = function(Category, Name)
		if not Category[Name] then return end

		pcall(function()
			if typeof(Category[Name]) == "RBXScriptConnection" then
				Category[Name]:Disconnect()
			else
				task.cancel(Category[Name])
			end
		end)

		Category[Name] = nil
		connections.runtime[Name] = false
	end

	Utils.AddHook = function(Name, Target, Hook, Type)
		if hooks[Name] then
			restorefunction(hooks[Name].Target)
			hooks[Name] = nil
		end

		local WrappedHook = Hook

		if Type == "Lua" then
			WrappedHook = newlclosure(Hook) -- We dont even need to wrap it, its already Lua
		elseif Type == "C" then
			WrappedHook = newcclosure(Hook)
		end

		local OldFunction = hookfunction(Target, WrappedHook)

		hooks[Name] = {
			Target = Target,
			Replacement = WrappedHook,
			Original = OldFunction
		}

		return OldFunction
	end

	Utils.RemoveHook = function(Name)
		local Entry = hooks[Name]
		if not Entry then return end

        if isfunctionhooked(Entry.Target) then
		    restorefunction(Entry.Target)
        end
		hooks[Name] = nil
	end
end;

local States = {
    Values = {
        LocalPlayer = {
			IsGrounded = false,
            EquippedItem = nil,

			LocalCharacter = LocalCharacter,
			FPSArms = LocalCharacter.Parent.FPSArms,
        },

        Game = {
			Metamethods = {
				Index = getrawmetatable(game).__index,
			},
            Lighting = {
                CurrentAmbient = Services["Lighting"].Ambient,
				OldShadows = Services["Lighting"].GlobalShadows
            },

            Workspace = {
                Terrain = {
                    WaterWaveSize = Services["Workspace"].Terrain.WaterWaveSize,
					Decoration = gethiddenproperty(workspace.Terrain, "Decoration") or false
                },
				Camera = {
					CameraCFrame = workspace.CurrentCamera.CFrame,
				},

                EntityList = {}
            }
        }
    }
}

local _localplayer = States.Values.LocalPlayer
local Game = States.Values.Game

local Proxy = {}

setmetatable(Proxy, {
	__index = States.Values,

	__newindex = function(self, key, value)
		rawset(States.Values, key, value)

		if key == "LocalPlayer" then
			_localplayer = value
		elseif key == "Game" then
			Game = value
		end
	end
})

States.Values = Proxy

const WILDCARD = newproxy(false)
local function RegisterHook(Id, Object, Property, HookFunction)
    local Key = Object == nil and WILDCARD or Object
    if not metahooks[Key] then
        metahooks[Key] = {}
    end

    metahooks[Key][Property] = {
        Id = Id,
        Hook = HookFunction
    }
end

local Old
Old = hookmetamethod(game, "__index", function(Object, Property)
    local ObjHooks = metahooks[Object]
    if ObjHooks then
        local Entry = ObjHooks[Property]
        if Entry then
            if type(Entry.Hook) == "function" then
                return Entry.Hook(Object, Property, Old)
            end
            return Entry.Hook
        end
    end

    local Wildcard = metahooks[WILDCARD]
    if Wildcard then
        local Entry = Wildcard[Property]
        if Entry then
            if type(Entry.Hook) == "function" then
                return Entry.Hook(Object, Property, Old)
            end
            return Entry.Hook
        end
    end

    return Old(Object, Property)
end)

const CreateEntity = EntityClient.Create
local u8 = debug.getupvalues(CreateEntity)[2]
	-- don't rely on #u8 (it reports 0 even though it has items).

local Library, ThemeManager, SaveManager =
	loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/libraries/Obsidian/main.lua"))(),
	loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/libraries/Obsidian/addons/ThemeManager.lua"))(),
	loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/libraries/Obsidian/addons/SaveManager.lua"))()

local Options, Toggles = Library.Options, Library.Toggles

Utils.IsToggled = function(Name)
    const Toggle = Toggles[Name]
    return Toggle and Toggle.Value or false
end

Library.ForceCheckbox, Library.ShowToggleFrameInKeybinds = false, true

local Window = Library:CreateWindow({
    Title = "mspaint",
    Footer = "version: v1",
    Icon = 95816097006870,
    NotifySide = "Right",
    ShowCustomCursor = false,
})

local Tabs = {
    Combat = Window:AddTab("Combat", "swords"),
    Visuals = Window:AddTab("Visuals", "eye"),
	World = Window:AddTab("World", "globe"),
    Config = Window:AddTab("Ui Settings", "settings"),
}

local Tabboxes = {
    Combat = Tabs.Combat:AddLeftTabbox(),
    World = Tabs.World:AddLeftTabbox(),
}

-- Entity "types" that map to a single Filter() Class.
local NPC_TYPES = { "LabWorker", "Ghoul", "Officer" }
local VEHICLE_TYPES = { "ATV", "Trolly", "Helicopter", "Boat" }
local CRATE_TYPES = { "MetalCrate", "GreenCrate" }

local function Filter(Entity)
	local Type = Entity.type

	local Default = {
		Type = Type,
		Model = Entity.model,
		Position = Entity.pos,
		Name = Entity.Name
	}

	local HandModel = Entity.handModel

	if HandModel == "HandModel" then
		HandModel = "None"
	end

	if Type == "Player" then
		-- Skip sleepers unless "Include Sleepers" is on.
		if Entity.sleeping and not Utils.IsToggled("sleepercheck") then
			return nil
		end

		local Actions = {
			Entity.sliding,
			Entity.crouching,
			Entity.jetpackEnabled
		}

		return {
			Class = "Player",
			Basic = Default,
			EquippedItem = HandModel,
			Armor = Entity.armor,
			IsSleeping = Entity.sleeping,
			Actions
		}

	elseif Type:find("Soldier") or table.find(NPC_TYPES, Type) then

		return {
			Class = "NPC",
			Basic = Default,
			EquippedItem = HandModel,
			Armor = Entity.armor
		}

	elseif Type == "Backpack" then
		return {
			Class = "Backpack",
			Basic = Default
		}
	elseif Type == "ClaimTotem" then
		return {
			Class = "Totem",
			Basic = Default
		}
	elseif Type == "RespawnTotem" then
		return {
			Class = "RespawnTotem",
			Basic = Default
		}

	elseif table.find(VEHICLE_TYPES, Type) then

		return {
			Class = "Vehicle",
			Basic = Default
		}
	elseif Type:find("Wall") then
		return {
			Class = "Wall",
			Basic = Default
		}

	elseif Type == "NitrateOre" then
		return {
			Class = "Nitrate",
			Basic = Default
		}

	elseif Type == "IronOre" then
		return {
			Class = "Iron",
			Basic = Default
		}

	elseif Type == "StoneOre" then
		return {
			Class = "Stone",
			Basic = Default
		}

	elseif table.find(CRATE_TYPES, Type) then
		return {
			Class = Type,
			Basic = Default
		}
	end

	-- SmallBox, MediumBox, Cabniet = types

	return nil
end

local EntityList = {}
Game.Workspace.EntityList = EntityList

Utils.UpdateEntities = function()
    table.clear(EntityList)

    for _, Item in next, u8 do
        local Basic = Filter(Item)
        if Basic then
            table.insert(EntityList, Basic)
        end
    end
end; Utils.UpdateEntities()

Utils.GetClosest = function()
    local Closest, ClosestDistance = nil, math.huge

    local FOVEnabled = Utils.IsToggled("EnableCrosshair")
    local FOVSize = Options.FovSize and Options.FovSize.Value
    local MousePos = Services["UserInputService"]:GetMouseLocation()
    local Camera = workspace.CurrentCamera

    for _, Entity in next, EntityList do
        if Entity.Class ~= "Player" then
            continue
        end

        local Torso = Entity.Basic.Model and Entity.Basic.Model:FindFirstChild("tosro")
        if not Torso then
            continue
        end

        if FOVEnabled then
            local ScreenPos, OnScreen = Camera:WorldToViewportPoint(Torso.Position)
            if not OnScreen then
                continue
            end

            local Delta = Vector2.new(ScreenPos.X - MousePos.X, ScreenPos.Y - MousePos.Y)
            if Delta.Magnitude > FOVSize then
                continue
            end
        end

        local Distance = (Camera.CFrame.Position - Torso.Position).Magnitude
        if Distance < ClosestDistance then
            ClosestDistance = Distance
            Closest = Torso
        end
    end

    return Closest
end

local SilentTab = Tabboxes.Combat:AddTab("Silent Aim")

SilentTab:AddToggle("silentaim", {
    Text = "Silent Aim",
    Default = false,
    Callback = function(Value) end
})

SilentTab:AddSlider("silentaimdistance", {
    Text = "Distance",
    Default = 1,
    Min = 1,
    Max = 2000,
    Rounding = 1,
    Callback = function(Value) end
})

local AimbotTab = Tabboxes.Combat:AddTab("Aimbot")

AimbotTab:AddToggle("aimbot", {
    Text = "Aimbot",
    Default = false,
    Callback = function(Value) end
})

AimbotTab:AddSlider("aimbotsmoothing", {
    Text = "Smoothing Amount",
    Default = 1,
    Min = 0,
    Max = 10,
    Rounding = 1,
    Callback = function(Value) end
})

AimbotTab:AddSlider("aimbotdistance", {
    Text = "Aimbot Distance",
    Default = 100,
    Min = 0,
    Max = 1000,
    Rounding = 0,
    Callback = function(Value) end
})


local Crosshair = Tabs.Combat:AddLeftGroupbox("FOV")

-- Toggle on/off and NumSides changes all funnel through here (recreates the circle).
Core.RefreshCrosshair = function()
    Utils.RemoveConnection(connections.renderstepped, "Crosshair")

    if drawings.crosshair.Drawing then
        pcall(function()
            drawings.crosshair.Drawing:Remove()
        end)

        drawings.crosshair.Drawing = nil
    end

    if not Utils.IsToggled("EnableCrosshair") then
        return
    end

    local Circle = Drawing.new("Circle")
    Circle.Visible = true
    Circle.Filled = false
    Circle.Thickness = 1
    Circle.Transparency = 1
    Circle.Color = Color3.new(1,1,1)

    drawings.crosshair.Drawing = Circle

    Utils.AddConnection(connections.renderstepped, "Crosshair", RenderStepped:Connect(function()
        local MousePos = Services["UserInputService"]:GetMouseLocation()

        Circle.Position = MousePos
        Circle.Radius = Options.FovSize.Value
        Circle.NumSides = Options.NumSides.Value
    end))
end

Crosshair:AddToggle("EnableCrosshair", {
    Text = "Enable Crosshair",
    Default = false,
    Callback = Core.RefreshCrosshair
})

Crosshair:AddSlider("NumSides",{
    Text = "Num Sides",

    Default = 14,
    Min = 4,
    Max = 28,
    Rounding = 0,

    Callback = function()
        if Utils.IsToggled("EnableCrosshair") then
            Core.RefreshCrosshair()
        end
    end
})

Crosshair:AddSlider("FovSize",{
    Text = "Fov Size",

    Default = 100,
    Min = 50,
    Max = 500,
    Rounding = 0,

    Callback = function()
    end
})


local Hitbox = Tabs.Combat:AddRightGroupbox("Hitbox")

Hitbox:AddToggle("hitboxexpander", {
    Text = "Hitbox Expander",
    Default = false,
    Callback = function(Value) end
})

Hitbox:AddSlider("hitboxsize", {
    Text = "Size",
    Min = 2,
    Max = 10,
    Default = 4,
    Callback = function(Value) end
})

local WeaponMods = Tabs.Combat:AddRightGroupbox("Weapon Mods")

const Recoil = Camera.Recoil
const Proto = debug.getproto(Recoil, 1)
local NoRecoil = {
    Enable = function()
        debug.setconstant(Proto, 2, "Mobile")
    end,
    Disable = function()
        debug.setconstant(Proto, 2, "PC")
    end
} --[[
if Device == "Mobile" then
    return -- avoids Recoil
end
--]]

WeaponMods:AddToggle("norecoil", {
    Text = "No Recoil",
    Default = false,
    Callback = function(Value)
        if Value then
            NoRecoil.Enable()
        else
            NoRecoil.Disable()
        end
    end
})

--[[
WeaponMods:AddToggle("nospread", {
    Text = "No Spread",
    Default = false,
    Callback = function(Value) end
})

WeaponMods:AddToggle("instahit", {
    Text = "Insta Hit",
    Default = false,
    Callback = function(Value) end
})
--]]

const SetSwaySpeed = Camera.SetSwaySpeed

WeaponMods:AddToggle("nosway", {
    Text = "No Sway",
    Default = false,
    Callback = function(Value)
        if Value then
            Utils.AddHook("NoSway", SetSwaySpeed, function(accumlator)
                debug.setupvalue(sway, 2, false)
            end, "Lua")
        else
            Utils.RemoveHook("NoSway")
        end
    end
})

local FastCooldown = Tabs.Combat:AddRightGroupbox("Fast Cooldown")

local OldDrill

const DrillUpdate = DrillClient.Update

FastCooldown:AddToggle("fastdrill", {
    Text = "Fast Drill",
    Default = false,
    Callback = function(Value)
        if Value then
            OldDrill = Utils.AddHook("FastDrill", DrillUpdate, function(p1)
                if not Utils.IsToggled("fastdrill") then
                    return OldDrill(p1)
                end
                p1.AttackCooldown *= 0
                return p1
            end, "Lua")
        else
            Utils.RemoveHook("FastDrill")
            OldDrill = nil
        end
    end
})

--[[
	-- server side limits
FastCooldown:AddToggle("fastbow", {
    Text = "Fast Bow",
    Default = false,
    Callback = function(Value)
        if Value then
        else
        end
    end
})
]]

-- TODO: Easy work, but highly detected

const EspLib = loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/Libraries/Esp/main.lua"))()

local function SettingsFrom(Values, Color)
    Values = Values or {}
    Color = Color or Color3.new(1, 1, 1)

    return {
        -- Base color for the whole container (corners/quad inherit it too).
        Color = Color,
        ShowBox = Values["Box"] == true,
        ShowName = Values["Name"] == true,
        ShowTracer = Values["Tracer"] == true,
        ShowDistance = Values["Distance"] == true,
        ShowChams = Values["Chams"] == true,

        BoxColor = Color,
        NameColor = Color,
        TracerColor = Color,
        DistanceColor = Color,
        ChamsColor = Color,
    }
end

-- The Entity container only ever renders classes that have a sub-toggle in EntityKeys.
const EntityKeys = {
    Nitrate = "NitrateEsp",
    Iron = "IronEsp",
    Stone = "StoneEsp",
    Totem = "TotemEsp",
    RespawnTotem = "TotemEsp",
    Backpack = "Backpacks",
    MetalCrate = "MetalCrate",
    GreenCrate = "GreenCrate",
}

-- Player/Entity/Vehicle all do the same thing, so it's one function.
local function GetModels(Container)
    const Models = {}

    for _, Entity in next, EntityList do
        const Model = Entity.Basic.Model
        const Class = Entity.Class

        local Show
        if Container == "Player" then
            Show = (Class == "Player" and Utils.IsToggled("playeresp"))
                or (Class == "NPC" and Utils.IsToggled("npccheck"))
        elseif Container == "Entity" then
            -- Entity Esp is a pure master toggle: it only gates the per-category
            -- sub-toggles (EntityKeys). NPCs/Walls/buildings are never part of it.
            const Key = EntityKeys[Class]
            Show = Utils.IsToggled("entityesp")
                and Key ~= nil
                and Utils.IsToggled(Key)
        elseif Container == "Vehicle" then
            Show = Class == "Vehicle" and Utils.IsToggled("vehicleesp")
        end

        if Model and Show then
            -- Label each source: prefer the entity's .Name (players), else its type.
            local Label = Entity.Basic.Name
            if typeof(Label) ~= "string" or Label == "" then
                Label = Entity.Basic.Type
            end
            Models[#Models + 1] = {
                Model = Model,
                Name = Label,
            }
        end
    end

    return Models
end

-- Any of these being enabled keeps the ESP library running.
const ESP_TOGGLES = {
    "playeresp",
    "npccheck",
    "entityesp",
    "NitrateEsp",
    "IronEsp",
    "StoneEsp",
    "TotemEsp",
    "Backpacks",
    "MetalCrate",
    "GreenCrate",
    "vehicleesp",
}

-- Each entry: { ContainerName, settings-dropdown option, color-picker option }.
const CONTAINERS = {
    { Name = "Player",  SettingsOption = "playerespsettings",  ColorOption = "espcolor" },
    { Name = "Entity",  SettingsOption = "entityespsettings",  ColorOption = "entitycolor" },
    { Name = "Vehicle", SettingsOption = "vehicleespsettings", ColorOption = "espcolor" },
}

Core.RebuildContainers = function()
    Utils.UpdateEntities()

    const Containers = {}

    for _, Container in next, CONTAINERS do
        const Name = Container.Name
        const Settings = Options[Container.SettingsOption]
        const Color = Options[Container.ColorOption]

        Containers[Name] = {
            -- Explicit container name; the lib uses it when available, else the key/type.
            Name = Name,
            Location = function() return GetModels(Name) end,
            Settings = SettingsFrom(
                Settings and Settings.Value,
                Color and Color.Value
            ),
        }
    end

    EspLib:SetContainer(Containers)
end

setrawmetatable(u8, {
    __newindex = function(self, key, value)
        rawset(self, key, value)

        Utils.UpdateEntities()
    end
})

Core.ESP = {
    UpdateEspActive = function()
        -- Re-apply containers (dynamic Locations are re-read every frame).
        Core.RebuildContainers()

        for _, Name in next, ESP_TOGGLES do
            if Utils.IsToggled(Name) then
                EspLib:Enable()
                return
            end
        end

        EspLib:Disable()
    end,
}

local PlayerEsp = Tabs.Visuals:AddLeftGroupbox("Esp")

PlayerEsp:AddToggle("playeresp",{
    Text = "Enable",
    Default = false,

    Callback = function(Value)
        Core.ESP.UpdateEspActive()
    end
})

PlayerEsp:AddDropdown("playerespsettings",{
    Multi = true,

    Values = {
        "Box",
        "Name",
        "Tracer",
        "Distance",
        "Chams"
    },

    Default = {"Distance"},

    Callback = function()
        Core.RebuildContainers()
    end
})

PlayerEsp:AddToggle("sleepercheck",{
    Text = "Include Sleepers",
    Default = false,

    Callback = function(Value)
        Utils.UpdateEntities() -- Filter excludes sleepers while the toggle is off
        Core.ESP.UpdateEspActive()
    end
})

PlayerEsp:AddToggle("npccheck",{
    Text = "Include NPCs",
    Default = false,

    Callback = function(Value)
        Core.ESP.UpdateEspActive()
    end
})

PlayerEsp:AddDivider()

PlayerEsp:AddLabel("Esp Color"):AddColorPicker("espcolor", {
    Default = Color3.new(1,1,1),

    Callback = function(Color)
        Core.RebuildContainers()
    end
})

local EntityEsp = Tabs.Visuals:AddRightGroupbox("Entity Esp")

EntityEsp:AddToggle("entityesp",{
    Text = "Entity Esp",
    Default = false,

    Callback = function(Value)
        Core.ESP.UpdateEspActive()
    end
})

EntityEsp:AddDropdown("entityespsettings",{
    Multi = true,

    Values = {
        "Box",
        "Name",
        "Tracer",
        "Distance",
        "Chams"
    },

    Default = {"Distance"},

    Callback = function()
        Core.RebuildContainers()
    end
})

EntityEsp:AddDivider()

EntityEsp:AddToggle("NitrateEsp",{
    Text = "Nitrate Esp",
    Default = false,

    Callback = function(Value)
        Core.ESP.UpdateEspActive()
    end
})

EntityEsp:AddToggle("IronEsp",{
    Text = "Iron Esp",
    Default = false,

    Callback = function(Value)
        Core.ESP.UpdateEspActive()
    end
})

EntityEsp:AddToggle("StoneEsp",{
    Text = "Stone Esp",
    Default = false,

    Callback = function(Value)
        Core.ESP.UpdateEspActive()
    end
})

EntityEsp:AddToggle("TotemEsp",{
    Text = "Totem Esp",
    Default = false,

    Callback = function(Value)
        Core.ESP.UpdateEspActive()
    end
})

EntityEsp:AddToggle("Backpacks",{
    Text = "Backpack Esp",
    Default = false,

    Callback = function(Value)
        Core.ESP.UpdateEspActive()
    end
})

--[[
EntityEsp:AddToggle("DroppedItems",{
    Text = "Dropped Items Esp",
    Default = false,

    Callback = function(Value)
    end
}) --]]

EntityEsp:AddToggle("MetalCrate",{
    Text = "Metal Crate Esp",
    Default = false,

    Callback = function(Value)
        Core.ESP.UpdateEspActive()
    end
})

EntityEsp:AddToggle("GreenCrate",{
    Text = "Green Crate Esp",
    Default = false,

    Callback = function(Value)
        Core.ESP.UpdateEspActive()
    end
})

EntityEsp:AddDivider()

EntityEsp:AddLabel("Esp Color"):AddColorPicker("entitycolor", {
    Default = Color3.new(1,1,1),

    Callback = function(Color)
        Core.RebuildContainers()
    end
})


local VehicleEsp = Tabs.Visuals:AddLeftGroupbox("Vehicle")

VehicleEsp:AddToggle("vehicleesp",{
    Text = "Enable",
    Default = false,

    Callback = function(Value)
        Core.ESP.UpdateEspActive()
    end
})

VehicleEsp:AddDropdown("vehicleespsettings",{
    Multi = true,

    Values = {
        "Box",
        "Name",
        "Tracer",
        "Distance"
    },

    Default = {"Name","Distance"},

    Callback = function()
        Core.RebuildContainers()
    end
})

local Chameleon = Tabs.Visuals:AddLeftGroupbox("Chams")

local ArmMeshes = {}

local Items = {
    "RightHand", "RightLowerArm", "RightUpperArm",
    "LeftHand", "LeftLowerArm", "LeftUpperArm",
    "c_RightLowerArm", "c_LeftLowerArm"
}

Chameleon:AddToggle("armchams", {
    Text = "Arm Chams",
    Default = false,
    Callback = function(Value)
        if Value then
            table.clear(ArmMeshes)

            for _, Item in next, Items do
                local Mesh
                if Item:sub(1,1) == "c" then
                    Mesh = _localplayer.FPSArms.Fake:FindFirstChild(Item)
                else
                    Mesh = _localplayer.FPSArms:FindFirstChild(Item)
                end

                if Mesh then
                    table.insert(ArmMeshes, {
                        Mesh = Mesh,
                        Material = Mesh.Material
                    })

                    Mesh.Material = Enum.Material.ForceField
                end
            end
        else
            for _, Data in next, ArmMeshes do
                if Data.Mesh then
                    Data.Mesh.Material = Data.Material
                end
            end

            table.clear(ArmMeshes)
        end
    end
})

local WeaponMeshes = {}

local Ignore = {
    Mover = true,
    ADS = true
}

Chameleon:AddToggle("weaponchams", {
    Text = "Weapon Chams",
    Default = false,
    Callback = function(Value)
        if Value then
            local HandModel = _localplayer.FPSArms:FindFirstChild("HandModel")
            if HandModel then
                for _, Object in next, HandModel:GetDescendants() do
                    if Object:IsA("BasePart")
                    and not Ignore[Object.Name]
                    and not WeaponMeshes[Object] then

                        WeaponMeshes[Object] = Object.Material
                        Object.Material = Enum.Material.ForceField
                    end
                end
            end

            Utils.AddConnection(connections.misc, "weaponchams", _localplayer.FPSArms.DescendantAdded:Connect(function(Object)
                if not Utils.IsToggled("weaponchams") then
                    return
                end

                local HandModel = _localplayer.FPSArms:FindFirstChild("HandModel")
                if not HandModel then
                    return
                end

                if Object:IsDescendantOf(HandModel)
                and Object:IsA("BasePart")
                and not Ignore[Object.Name]
                and not WeaponMeshes[Object] then

                    WeaponMeshes[Object] = Object.Material
                    Object.Material = Enum.Material.ForceField
                end
            end))
        else
            Utils.RemoveConnection(connections.misc, "weaponchams")

            for Object, Material in next, WeaponMeshes do
                if Object.Parent then
                    Object.Material = Material
                end
            end

            table.clear(WeaponMeshes)
        end
    end
})

RegisterHook("chams", nil, "Material", function(Object, Property, Old)
    if Utils.IsToggled("armchams") then
        for _, Data in next, ArmMeshes do
            if Object == Data.Mesh then
                return Data.Material
            end
        end
    end

    if Utils.IsToggled("weaponchams") then
        for _, Data in next, WeaponMeshes do
            if Object == Data.Mesh then
                return Data.Material
            end
        end
    end

    return Old(Object, Property)
end)

local Bullet = Tabs.World:AddLeftGroupbox("Bullet")

Bullet:AddToggle("bullettracer", {
    Text = "Bullet Tracer (for every player)",
    Default = false,
    Callback = function(Value) end
})

local OldCreateProjectile
local CreateProjectile = RangedWeaponClient.CreateProjectile
OldCreateProjectile = hookfunction(CreateProjectile, function(originCF, weapon, ...)
	if not Utils.IsToggled("bullettracer") then
		return OldCreateProjectile(originCF, weapon, ...)
	end
	
	task.spawn(function()
		local startPos = originCF.Position
			+ originCF.LookVector * 5
			+ originCF.UpVector * 0.3
		local endPos = startPos + originCF.LookVector * 250

		local p0 = Instance.new("Part")
		p0.Size = Vector3.new(.1,.1,.1)
		p0.Transparency = 1
		p0.Anchored = true
		p0.CanCollide = false
		p0.Position = startPos
		p0.Parent = workspace

		local p1 = p0:Clone()
		p1.Position = endPos
		p1.Parent = workspace

		local a0 = Instance.new("Attachment",p0)
		local a1 = Instance.new("Attachment",p1)

		local beam = Instance.new("Beam")
		beam.Attachment0 = a0
		beam.Attachment1 = a1
		beam.FaceCamera = true
		beam.LightEmission = 1
		beam.Width0 = .12
		beam.Width1 = .05
		beam.TextureSpeed = 2
		beam.Parent = p0

		task.spawn(function()
			for i = 0,1,.1 do
				beam.Transparency = NumberSequence.new(i)
				task.wait(.05)
			end

			p0:Destroy()
			p1:Destroy()
		end)
	end)

	return OldCreateProjectile(originCF, weapon, ...)
end)

local Ambient = Tabs.World:AddRightGroupbox("Ambient")

local Lighting = game:GetService("Lighting")
	-- Services is NOT the original.

Ambient:AddToggle("ambient", {
    Text = "Enable",
    Default = false,
    Callback = function(Value)
        if Value then
            Utils.AddConnection(connections.heartbeats, "SpoofAmbient", Heartbeat:Connect(function()
                Lighting.Ambient = Options.ambientcolor.Value
            end))
        else
            Utils.RemoveConnection(connections.heartbeats, "SpoofAmbient")
            Lighting.Ambient = Game.Lighting.CurrentAmbient
        end
    end
})

Ambient:AddLabel("Ambient Color"):AddColorPicker("ambientcolor", {
    Default = Color3.fromRGB(255,255,255),
    Title = "Ambient Color",
    Callback = function(Color)
        if Utils.IsToggled("ambient") then
            Lighting.Ambient = Color
        end
    end,
})

RegisterHook("ambient", Lighting, "Ambient", function(Object, Property, Old)
    if Utils.IsToggled("ambient") and Object == Lighting and Property == "Ambient" then
        return Game.Lighting.CurrentAmbient
    end

    return Old(Object, Property)
end)

Lighting:GetPropertyChangedSignal("Ambient"):Connect(function()
	local Ambience = Old(Lighting, "Ambient")

    if Library ~= nil or Ambience == Options.ambientcolor.Value then
		return
	end -- This is us, so dont log it.
    Game.Lighting.CurrentAmbient = Ambience
end)

local Terrain = Tabs.World:AddRightGroupbox("Terrain")

Terrain:AddToggle("nowaves", {
    Text = "No Waves",
    Default = false,
    Callback = function(Value)
        workspace.Terrain.WaterWaveSize = Value and 0 or Game.Workspace.Terrain.WaterWaveSize
    end,
})

RegisterHook("nowaves", workspace.Terrain, "WaterWaveSize", function(Object, Property, Old)
    if Utils.IsToggled("nowaves") and Object == workspace.Terrain then
        return Game.Workspace.Terrain.WaterWaveSize
    end

    return Old(Object, Property)
end)

const Min = getfflag("FRMMinGrassDistance")
const Max = getfflag("FRMMaxGrassDistance")

Terrain:AddToggle("nograss", {
    Text = "No Grass",
    Default = false,
    Callback = function(Value)
        setfflag("FRMMinGrassDistance", Value and -1 or Min)
        setfflag("FRMMaxGrassDistance", Value and -1 or Max)
    end,
})

--[[ -- This was a hidden propety anyway, so idk why I hooked it
RegisterHook("nograss", "Decoration", function(Object, Property, Old)

    if Toggles.nograss.Value and Object == workspace.Terrain then
        return Game.Workspace.Terrain.Decoration
    end

    return Old(Object, Property)
end)
]]

Terrain:AddToggle("noshadows", {
    Text = "No Shadows",
    Default = false,
    Callback = function(Value)
        Lighting.GlobalShadows = not Value
    end,
})

RegisterHook("noshadows", Lighting, "GlobalShadows", function(Object, Property, Old)
    if Utils.IsToggled("noshadows") and Object == Lighting then
        return Game.Lighting.OldShadows
    end

    return Old(Object, Property)
end)

local MovementTab = Tabboxes.World:AddTab("Movement")

local KeyList = loadstring(game:HttpGet("https://website-iota-ivory-12.vercel.app/code/loader/u/keys.lua"))()

Utils.InputKeys = function(Keys, Delay)
    Delay = Delay or 0
    for _, v in next, Keys do
        if keytap then
            keytap(KeyList[v])
        else
            Services["VirtualInputManager"]:SendKeyEvent(true, Enum.KeyCode[v], false, game)
            task.wait(0.05)
            Services["VirtualInputManager"]:SendKeyEvent(false, Enum.KeyCode[v], false, game)
        end
        if Delay and Delay > 0 then
            task.wait(Delay)
        end
    end
end

const IsGrounded = Character.IsGrounded
const GetY = Camera.GetY

local function SlideJump()
    if IsGrounded() then
        local cameraY = GetY() + math.pi
        local slideDir = Vector3.new(
            math.sin(cameraY),
            0,
            math.cos(cameraY)
        )

        local Bottom = _localplayer.LocalCharacter.Bottom
        Bottom.AssemblyLinearVelocity =
            Bottom.AssemblyLinearVelocity + (slideDir * 70)
    else
        Logger:Info("Not Grounded")
    end
end

MovementTab:AddToggle("autoslidejump", {
    Text = "Auto Slide Jump",
    Default = false,
    Callback = function(Value)
        if Value then
            Utils.AddConnection(connections.heartbeats, "AutoSlideJump", Heartbeat:Connect(function()
                task.wait(1)
                SlideJump()
            end))
        else
            Utils.RemoveConnection(connections.heartbeats, "AutoSlideJump")
        end
    end
})

MovementTab:AddButton("Slide Jump", SlideJump)

MovementTab:AddDivider()

MovementTab:AddToggle("walkspeed", {
    Text = "Walkspeed",
    Default = false,
    Callback = function(Value) end
})

MovementTab:AddSlider("movementspeed", {
    Text = "Movement Speed",
    Default = 20,
    Min = 11,
    Max = 23,
    Rounding = 0,
    Callback = function(Value) end
})

local function SetupWalkspeed()
	task.spawn(function()
		local LinearVelocity = _localplayer.LocalCharacter.Middle.LinearVelocity
		LinearVelocity:GetPropertyChangedSignal("VectorVelocity"):Connect(function()
			if not Library or not LinearVelocity or not Utils.IsToggled("walkspeed") then
				return
			end

			local Speed = Options.movementspeed.Value
			local CurrentVelocity = LinearVelocity.VectorVelocity

			-- Read player input
			local InputX = 0
			local InputZ = 0

			if Services["UserInputService"]:IsKeyDown(Enum.KeyCode.W) then
				InputZ = InputZ - 1
			end
			if Services["UserInputService"]:IsKeyDown(Enum.KeyCode.S) then
				InputZ = InputZ + 1
			end
			if Services["UserInputService"]:IsKeyDown(Enum.KeyCode.A) then
				InputX = InputX - 1
			end
			if Services["UserInputService"]:IsKeyDown(Enum.KeyCode.D) then
				InputX = InputX + 1
			end

			local InputDir = Vector3.new(InputX, 0, InputZ)
			if InputDir.Magnitude > 0 then
				InputDir = InputDir.Unit
			end

			LinearVelocity.VectorVelocity = Vector3.new(
				InputDir.X * Speed,
				CurrentVelocity.Y, -- Unchanged
				InputDir.Z * Speed
			)
		end)
	end)
end

SetupWalkspeed()

MovementTab:AddDivider()

MovementTab:AddToggle("alwaysgrounded", {
    Text = "Always Grounded",
    Default = false,
    Callback = function(Value) end
})

local OldNamecall
OldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(Self, ...)
    local Method = getnamecallmethod()
    local Args = {...}
 
    if Utils.IsToggled("alwaysgrounded") and Self == workspace and Method == "Raycast" then
        local origin = Args[1]
        local direction = Args[2]
        local params = Args[3]
 
        -- Downward ray = likely an IsGrounded check
        if direction and direction.Y < 0 then
            local rayDist = direction.Magnitude

            -- Short downward ray => report ground just below origin
            if rayDist <= 6 then
                return {
                    Instance = workspace.Terrain,
                    Position = origin + Vector3.new(0, -math.min(rayDist * 0.5, 2), 0),
                    Material = Enum.Material.Grass,
                    Normal = Vector3.new(0, 1, 0),
                    Distance = math.min(rayDist * 0.5, 2)
                }
            else
                -- For longer rays, call the original
                return OldNamecall(Self, ...)
            end
        end
    end
 
    return OldNamecall(Self, ...)
end))
 
MovementTab:AddToggle("antisprintblock", {
    Text = "No Slowdown",
    Default = false,
    Callback = function(Value) end
})

-- Could hook Character's sprintBlocked (see updateCharacter, ~line 617).

local ExploitsTab = Tabboxes.World:AddTab("Camera")

const Prism1 = _localplayer.LocalCharacter.Top.Prism1
const OriginalPrism1 = Prism1.CFrame

ExploitsTab:AddToggle("longneck", {
    Text = "Long Neck",
    Default = false,
    Callback = function(Value)
        Prism1.CFrame = Value and (OriginalPrism1 - Vector3.yAxis * 5) or OriginalPrism1
    end,
})

RegisterHook("longneck", Prism1, "CFrame", function(Object, Property, Old)
    if Utils.IsToggled("longneck") and Object == Prism1 then
        return OriginalPrism1
    end

    return Old(Object, Property)
end)

ExploitsTab:AddDivider()

ExploitsTab:AddToggle("freecam", {
    Text = "Freecam",
    Default = false,
    Callback = function()
        Game.Workspace.Camera.CameraCFrame = workspace.CurrentCamera.CFrame
    end,
})

ExploitsTab:AddSlider("freecamspeed", {
    Text = "Freecam Speed",
    Default = 50,
    Min = 10,
    Max = 300,
    Rounding = 0,
    Callback = function(Value) end
})

RegisterHook("CameraHook", workspace.CurrentCamera, "CFrame", function(Object, Property, Old)
    if Utils.IsToggled("freecam") and Object == workspace.CurrentCamera and Property == "CFrame" then
        return Game.Workspace.Camera.CameraCFrame
    end

    return Old(Object, Property)
end)

ExploitsTab:AddDivider()

const SetBaseFOV = Camera.SetBaseFOV

ExploitsTab:AddToggle("camerafov", {
    Text = "Higher FOV",
    Default = false,
    Callback = function(Value)
        SetBaseFOV(Value and 90 or 70)
    end,
})

local VehicleMisc = Tabs.World:AddRightGroupbox("Vehicle")

VehicleMisc:AddToggle("vehiclefly", {
    Text = "Fly",
    Default = false,
    Callback = function(Value) end
})

VehicleMisc:AddSlider("vehicleflyspeed", {
    Text = "Speed Amount",
    Default = 50,
    Min = 10,
    Max = 300,
    Rounding = 0,
    Callback = function(Value) end
})

VehicleMisc:AddDivider()

local OldCar

const GainControl = TrollyClient.GainControl

VehicleMisc:AddToggle("fastcar", {
    Text = "Vehicle Speed",
    Default = false,
    Callback = function(Value)
        if Value then
            OldCar = Utils.AddHook("FastCar", GainControl, function(p1)
                if not Utils.IsToggled("fastcar") then
                    return OldCar(p1)
                end
                p1.TopSpeed = Options.vehiclespeed.Value
                return p1
            end, "Lua")
        else
            Utils.RemoveHook("FastCar")
            OldCar = nil
        end
    end
})

-- Hook TrollyClient.GainControl's TopSpeed param.

VehicleMisc:AddSlider("vehiclespeed", {
    Default = 50,
    Min = 10,
    Max = 300,
    Rounding = 0,
    Callback = function(Value) end
})

-- Ui Settings

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:BuildConfigSection(Tabs.Config)
ThemeManager:ApplyToTab(Tabs.Config)

local Gui = Tabs.Config:AddRightGroupbox("Gui")

Gui:AddButton("Unload Gui", function()
    Library:Unload()
end)

Gui:AddLabel("Menu bind")
	:AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })

Library.ToggleKeybind = Options.MenuKeybind

SaveManager:LoadAutoloadConfig()
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

ThemeManager:SetFolder("trident")
SaveManager:SetFolder("trident/Configs")

-- Apply saved ESP settings; enable the library if any toggle was restored.
Core.RebuildContainers()
Core.ESP.UpdateEspActive()