-- open source
-- SLOP ai SLOPPPPP

local Config = {
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

local Services = loadstring(game:HttpGet(
    "https://website-iota-ivory-12.vercel.app/code/Modules/Services.lua"
))()

local Environment =
    rawget(getrenv(), "_G")

local __index = getrawmetatable(Environment).__index

if not __index then
	Logger:Error(2)
end

local Success, Upvalues = pcall(debug.getupvalues, __index)

if not Success or not Upvalues then
	Logger:Error(2, "no upvalues")
end

local Bundled =
    Upvalues[10]
    and Upvalues[10][2]

if not Bundled then
	Logger:Error(2, "no classes")
end

-- Classes
local function IndexClass(Key)
    return Bundled[Key]
end

local Character = IndexClass("Character")
local FPS = IndexClass("FPS")
local Camera = IndexClass("Camera")
local RangedWeaponClient = IndexClass("RangedWeaponClient")
local NetClient = IndexClass("NetClient")
local EntityClient = IndexClass("EntityClient")
local TrollyClient = IndexClass("TrollyClient")
local DrillClient = IndexClass("MiningDrillClient")

local LocalCharacter = workspace.Const.Ignore.LocalCharacter

local function IndexFunction(Class, Key)
	if Class == nil or Key == nil then
		Logger:Error(2, "class or key missing")
	end

    return Class[Key]
end

local Heartbeat = Services.RunService.Heartbeat
local RenderStepped = Services.RunService.RenderStepped

local Channel, Id = create_comm_channel()
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

setmetatable(cheat, {
	__index = function(self, key)
		return rawget(self, key)
	end,

	__newindex = function(self, key, value)
		rawset(self, key, value)

		if key == "connections" then connections = value
		elseif key == "drawings" then drawings = value
		elseif key == "hooks" then hooks = value
		elseif key == "metahooks" then metahooks = value
		elseif key == "Utils" then Utils = value
		elseif key == "Core" then Core = value
		end
	end
})

do
	Utils.SetValue = function(Obj, Key, Value, Notify)
		Obj[Key] = Value
	end

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

	Utils.RandomString = function(Length)
		local str = {}
		for i = 1, Length do
			table.insert(str, string.char(math.random(97, 121))) -- uncap: 97 121 - capitlized: 65 90
		end
		return table.concat(str)
	end

	Utils.RandomNumber = function(Digits)
		return math.random(Digits)
	end

    Utils.IsHooked = function(Name)
		return hooks[Name] ~= nil
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
		Functions = {
			IsGrounded = IndexFunction(Character, "IsGrounded"),
			ForceSlide = IndexFunction(Character, "ForceSlide"),
			SetSprintBlocked = IndexFunction(Character, "SetSprintBlocked"),
			CanShoot = IndexFunction(FPS, "IsItemUsable"),
			GetEquippedItem = IndexFunction(FPS, "GetEquippedItem"),
			Recoil = IndexFunction(Camera, "Recoil"),
			SetSwaySpeed = IndexFunction(Camera, "SetSwaySpeed"),
			SetBaseFOV = IndexFunction(Camera, "SetBaseFOV"),
			GetX = IndexFunction(Camera, "GetX"),
			GetY = IndexFunction(Camera, "GetY"),
			CreateProjectile = IndexFunction(RangedWeaponClient, "CreateProjectile"),
			GainControl = IndexFunction(TrollyClient, "GainControl"),
			DrillUpdate = IndexFunction(DrillClient, "Update"),
			CreateEntity = IndexFunction(EntityClient, "Create"),

			SendTCP = IndexFunction(NetClient, "SendTCP"),
			SendUDP = IndexFunction(NetClient, "SendUDP"),
		},

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
local Functions = States.Values.Functions

local Proxy = {}

setmetatable(Proxy, {
	__index = States.Values,

	__newindex = function(self, key, value)
		rawset(States.Values, key, value)

		if key == "LocalPlayer" then
			_localplayer = value
		elseif key == "Game" then
			Game = value
		elseif key == "Functions" then
			Functions = value
		end
	end
})

States.Values = Proxy

local WILDCARD = newproxy(false)
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

local u8 = debug.getupvalues(Functions.CreateEntity)[2]
	-- RAW entity map (id -> entity). Never clear it (the game depends on it) and
	-- don't rely on #u8 (it reports 0 even though it has items).

local Library, ThemeManager, SaveManager =
	loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/libraries/Obsidian/main.lua"))(),
	loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/libraries/Obsidian/addons/ThemeManager.lua"))(),
	loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/libraries/Obsidian/addons/SaveManager.lua"))()

local Options, Toggles = Library.Options, Library.Toggles
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
		Position = Entity.pos
	}

	local HandModel = Entity.handModel

	if HandModel == "HandModel" then
		HandModel = "None"
	end

	if Type == "Player" then
		-- Skip sleepers unless "Include Sleepers" is on.
		if Entity.sleeping and not (Toggles.sleepercheck and Toggles.sleepercheck.Value) then
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
Utils.SetValue(Game.Workspace, "EntityList", EntityList)

local function UpdateEntities()
    table.clear(EntityList)

    for _, Item in next, u8 do
        local Basic = Filter(Item)
        if Basic then
            table.insert(EntityList, Basic)
        end
    end
end

-- Rebuild the filtered list (and ESP containers) when the game adds/removes an entity.
local RebuildContainers
setrawmetatable(u8, {
    __newindex = function(self, key, value)
        rawset(self, key, value)

        UpdateEntities()
        RebuildContainers()
    end
})

UpdateEntities()

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

Core.Crosshair = {
    Disable = function()
        Utils.RemoveConnection(connections.renderstepped, "Crosshair")
        local crosshair = drawings.crosshair

        if crosshair then
            pcall(function()
                crosshair.Drawing:Remove()
            end)

            crosshair.Drawing = nil
        end
    end,

    Enable = function()
        Core.Crosshair.Disable()

        if not Toggles.EnableCrosshair.Value then
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
                local MousePos =
                    Services["UserInputService"]:GetMouseLocation()

                Circle.Position = MousePos
                Circle.Radius = Options.FovSize.Value
                Circle.NumSides = Options.NumSides.Value
            end)
        )
    end,
}

Crosshair:AddToggle("EnableCrosshair",{
    Text = "Enable Crosshair",
    Default = false,

    Callback = function(Value)
        if Value then
            Core.Crosshair.Enable()
        else
            Core.Crosshair.Disable()
        end
    end
})

Crosshair:AddSlider("NumSides",{
    Text = "Num Sides",

    Default = 14,
    Min = 4,
    Max = 28,
    Rounding = 0,

    Callback = function()
        if Toggles.EnableCrosshair.Value then
            Core.Crosshair.Enable()
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

local OldRecoil

local function SetNoRecoil(Value)
    local Proto = debug.getproto(Functions.Recoil, 1)

    debug.setconstant(Proto, 2, Value and "PC" or "Mobile") -- device == "PC" => no recoil
end

WeaponMods:AddToggle("norecoil", {
    Text = "No Recoil",
    Default = false,
    Callback = SetNoRecoil
})

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

local OldSway

Core.NoSway = {
    Enable = function()
        OldSway = Utils.AddHook("NoSway", Functions.SetSwaySpeed, function(accumlator)
            if not Toggles.nosway.Value then
                return OldSway(accumlator)
            end
            accumlator = 0
            return table.pack(accumlator)
        end, "Lua")
    end,

    Disable = function()
        Utils.RemoveHook("NoSway")
        OldSway = nil
    end,
}

WeaponMods:AddToggle("nosway", {
    Text = "No Sway",
    Default = false,
    Callback = function(Value)
        if Value then
            Core.NoSway.Enable()
        else
            Core.NoSway.Disable()
        end
    end
})

local FastCooldown = Tabs.Combat:AddRightGroupbox("Fast Cooldown")

local OldDrill

Core.FastDrill = {
    Enable = function()
        OldDrill = Utils.AddHook("FastDrill", Functions.DrillUpdate, function(p1)
            if not Toggles.fastdrill.Value then
                return OldDrill(p1)
            end
            p1.AttackCooldown *= 0
            return p1
        end, "Lua")
    end,

    Disable = function()
        Utils.RemoveHook("FastDrill")
        OldDrill = nil
    end,
}

FastCooldown:AddToggle("fastdrill", {
    Text = "Fast Drill",
    Default = false,
    Callback = function(Value)
        if Value then
            Core.FastDrill.Enable()
        else
            Core.FastDrill.Disable()
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

-- ESP is handled by the shared Esp library (dynamic model sources, re-synced each frame).
local EspLib = loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/Libraries/Esp/main.lua"))()

local function Tog(Name)
    local T = Toggles[Name]
    return T and T.Value or false
end

local function SettingsFrom(Values, Color)
    Values = Values or {}
    Color = Color or Color3.new(1, 1, 1)

    return {
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

-- Everything not in here is an "entity" for the Entity container.
local NON_ENTITY_CLASSES = { "Player", "Vehicle" }

-- Return the Models currently ESP'd, based on which toggles are on.
local function PlayerModels()
    local Models = {}
    local IncludePlayers = Tog("playeresp")
    local IncludeNpcs = Tog("npccheck")

    if not (IncludePlayers or IncludeNpcs) then
        return Models
    end

    for _, Entity in next, EntityList do
        local Model = Entity.Basic.Model
        local Class = Entity.Class

        if Model
        and ((Class == "Player" and IncludePlayers)
            or (Class == "NPC" and IncludeNpcs)) then
            Models[#Models + 1] = Model
        end
    end

    return Models
end

-- Per-category overrides; untouched categories follow the master "entityesp".
local UserSet = {}

local EntityKeys = {
    Nitrate = "Nitrate",
    Iron = "Iron",
    Stone = "Stone",
    Totem = "Totem",
    RespawnTotem = "Totem",
    Backpack = "Backpack",
    MetalCrate = "MetalCrate",
    GreenCrate = "GreenCrate",
}

local function ShowEntity(Class)
    local Key = EntityKeys[Class]
    if Key then
        if UserSet[Key] ~= nil then
            return UserSet[Key]
        end
        return Tog("entityesp")
    end
    return Tog("entityesp")
end

local function EntityModels()
    local Models = {}

    for _, Entity in next, EntityList do
        local Model = Entity.Basic.Model
        local Class = Entity.Class

        if Model
        and not table.find(NON_ENTITY_CLASSES, Class)
        and ShowEntity(Class) then
            Models[#Models + 1] = Model
        end
    end

    return Models
end

local function VehicleModels()
    local Models = {}

    if not Tog("vehicleesp") then
        return Models
    end

    for _, Entity in next, EntityList do
        local Model = Entity.Basic.Model

        if Model and Entity.Class == "Vehicle" then
            Models[#Models + 1] = Model
        end
    end

    return Models
end

RebuildContainers = function()
    EspLib:SetContainer({
        Player = {
            Location = PlayerModels,
            Settings = SettingsFrom(
                Options.playerespsettings and Options.playerespsettings.Value,
                Options.espcolor and Options.espcolor.Value
            ),
        },
        Entity = {
            Location = EntityModels,
            Settings = SettingsFrom(
                Options.entityespsettings and Options.entityespsettings.Value,
                Options.entitycolor and Options.entitycolor.Value
            ),
        },
        Vehicle = {
            Location = VehicleModels,
            Settings = SettingsFrom(
                Options.vehicleespsettings and Options.vehicleespsettings.Value,
                Options.espcolor and Options.espcolor.Value
            ),
        },
    })
end

-- Any of these being enabled keeps the ESP library running.
local ESP_TOGGLES = {
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

local function UpdateEspActive()
    -- Re-apply containers (dynamic Locations are re-read every frame).
    RebuildContainers()

    local AnyOn = false
    for _, Name in next, ESP_TOGGLES do
        if Tog(Name) then
            AnyOn = true
            break
        end
    end

    if AnyOn then
        EspLib:Enable()
    else
        EspLib:Disable()
    end
end

local PlayerEsp = Tabs.Visuals:AddLeftGroupbox("Esp")

PlayerEsp:AddToggle("playeresp",{
    Text = "Enable",
    Default = false,

    Callback = function(Value)
        UpdateEspActive()
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
        RebuildContainers()
    end
})

PlayerEsp:AddToggle("sleepercheck",{
    Text = "Include Sleepers",
    Default = false,

    Callback = function(Value)
        UpdateEntities() -- Filter excludes sleepers while the toggle is off
        UpdateEspActive()
    end
})

PlayerEsp:AddToggle("npccheck",{
    Text = "Include NPCs",
    Default = false,

    Callback = function(Value)
        UpdateEspActive()
    end
})

PlayerEsp:AddDivider()

PlayerEsp:AddLabel("Esp Color"):AddColorPicker("espcolor", {
    Default = Color3.new(1,1,1),

    Callback = function(Color)
        RebuildContainers()
    end
})

local EntityEsp = Tabs.Visuals:AddRightGroupbox("Entity Esp")

EntityEsp:AddToggle("entityesp",{
    Text = "Entity Esp",
    Default = false,

    Callback = function(Value)
        if Value then
            table.clear(UserSet) -- master "show all" resets per-category overrides
        end
        UpdateEspActive()
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
        RebuildContainers()
    end
})

EntityEsp:AddDivider()

EntityEsp:AddToggle("NitrateEsp",{
    Text = "Nitrate Esp",
    Default = false,

    Callback = function(Value)
        UserSet.Nitrate = Value
        UpdateEspActive()
    end
})

EntityEsp:AddToggle("IronEsp",{
    Text = "Iron Esp",
    Default = false,

    Callback = function(Value)
        UserSet.Iron = Value
        UpdateEspActive()
    end
})

EntityEsp:AddToggle("StoneEsp",{
    Text = "Stone Esp",
    Default = false,

    Callback = function(Value)
        UserSet.Stone = Value
        UpdateEspActive()
    end
})

EntityEsp:AddToggle("TotemEsp",{
    Text = "Totem Esp",
    Default = false,

    Callback = function(Value)
        UserSet.Totem = Value
        UpdateEspActive()
    end
})

EntityEsp:AddToggle("Backpacks",{
    Text = "Backpack Esp",
    Default = false,

    Callback = function(Value)
        UserSet.Backpack = Value
        UpdateEspActive()
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
        UserSet.MetalCrate = Value
        UpdateEspActive()
    end
})

EntityEsp:AddToggle("GreenCrate",{
    Text = "Green Crate Esp",
    Default = false,

    Callback = function(Value)
        UserSet.GreenCrate = Value
        UpdateEspActive()
    end
})

EntityEsp:AddDivider()

EntityEsp:AddLabel("Esp Color"):AddColorPicker("entitycolor", {
    Default = Color3.new(1,1,1),

    Callback = function(Color)
        RebuildContainers()
    end
})


local VehicleEsp = Tabs.Visuals:AddLeftGroupbox("Vehicle")

VehicleEsp:AddToggle("vehicleesp",{
    Text = "Enable",
    Default = false,

    Callback = function(Value)
        UpdateEspActive()
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
        RebuildContainers()
    end
})

local Chameleon = Tabs.Visuals:AddLeftGroupbox("Chams")

local ArmMeshes = {}

local Items = {
    "RightHand", "RightLowerArm", "RightUpperArm",
    "LeftHand", "LeftLowerArm", "LeftUpperArm",
    "c_RightLowerArm", "c_LeftLowerArm"
}

Core.ArmChams = {
    Enable = function()
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
    end,

    Disable = function()
        for _, Data in next, ArmMeshes do
            if Data.Mesh then
                Data.Mesh.Material = Data.Material
            end
        end

        table.clear(ArmMeshes)
    end,
}

Chameleon:AddToggle("armchams", {
    Text = "Arm Chams",
    Default = false,
    Callback = function(Value)
        if Value then
            Core.ArmChams.Enable()
        else
            Core.ArmChams.Disable()
        end
    end
})

local WeaponMeshes = {}

local Ignore = {
    Mover = true,
    ADS = true
}

local function ApplyWeaponChams()
    local HandModel = _localplayer.FPSArms:FindFirstChild("HandModel")
    if not HandModel then
        return
    end

    for _, Object in next, HandModel:GetDescendants() do
        if Object:IsA("BasePart")
        and not Ignore[Object.Name]
        and not WeaponMeshes[Object] then

            WeaponMeshes[Object] = Object.Material
            Object.Material = Enum.Material.ForceField
        end
    end
end

Core.WeaponChams = {
    Enable = function()
        ApplyWeaponChams()

        Utils.AddConnection(connections.misc, "weaponchams", _localplayer.FPSArms.DescendantAdded:Connect(function(Object)
            if not Toggles.weaponchams.Value then
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
    end,

    Disable = function()
        Utils.RemoveConnection(connections.misc, "weaponchams")

        for Object, Material in next, WeaponMeshes do
            if Object.Parent then
                Object.Material = Material
            end
        end

        table.clear(WeaponMeshes)
    end,
}

Chameleon:AddToggle("weaponchams", {
    Text = "Weapon Chams",
    Default = false,
    Callback = function(Value)
        if Value then
            Core.WeaponChams.Enable()
        else
            Core.WeaponChams.Disable()
        end
    end
})

RegisterHook("chams", nil, "Material", function(Object, Property, Old)
    if Toggles.armchams.Value then
        for _, Data in next, ArmMeshes do
            if Object == Data.Mesh then
                return Data.Material
            end
        end
    end

    if Toggles.weaponchams.Value then
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
OldCreateProjectile = hookfunction(Functions.CreateProjectile, function(originCF, weapon, ...)
	if not Toggles.bullettracer.Value then
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

Core.Ambient = {
    Enable = function()
        Utils.AddConnection(connections.heartbeats, "SpoofAmbient", Heartbeat:Connect(function()
            Lighting.Ambient = Options.ambientcolor.Value
        end))
    end,

    Disable = function()
        Utils.RemoveConnection(connections.heartbeats, "SpoofAmbient")
        Lighting.Ambient = Game.Lighting.CurrentAmbient
    end,
}

local function SetAmbientColor(Color)
    if Toggles.ambient.Value then
        Lighting.Ambient = Color
    end
end

Ambient:AddToggle("ambient", {
    Text = "Enable",
    Default = false,
    Callback = function(Value)
        if Value then
            Core.Ambient.Enable()
        else
            Core.Ambient.Disable()
        end
    end
})

Ambient:AddLabel("Ambient Color"):AddColorPicker("ambientcolor", {
    Default = Color3.fromRGB(255,255,255),
    Title = "Ambient Color",

    Callback = SetAmbientColor
})

RegisterHook("ambient", Lighting, "Ambient", function(Object, Property, Old)
    if Toggles.ambient.Value and Object == Lighting and Property == "Ambient" then
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

local function SetNoWaves(Value)
    workspace.Terrain.WaterWaveSize =
        Value and 0 or Game.Workspace.Terrain.WaterWaveSize
end

Terrain:AddToggle("nowaves", {
    Text = "No Waves",
    Default = false,
    Callback = SetNoWaves
})

RegisterHook("nowaves", workspace.Terrain, "WaterWaveSize", function(Object, Property, Old)
    if Toggles.nowaves.Value and Object == workspace.Terrain then
        return Game.Workspace.Terrain.WaterWaveSize
    end

    return Old(Object, Property)
end)

local Min = getfflag("FRMMinGrassDistance")
local Max = getfflag("FRMMaxGrassDistance")

local function SetNoGrass(Value)
    setfflag("FRMMinGrassDistance", Value and -1 or Min)
    setfflag("FRMMaxGrassDistance", Value and -1 or Max)
end

Terrain:AddToggle("nograss", {
    Text = "No Grass",
    Default = false,
    Callback = SetNoGrass
})

--[[ -- This was a hidden propety anyway, so idk why I hooked it
RegisterHook("nograss", "Decoration", function(Object, Property, Old)

    if Toggles.nograss.Value and Object == workspace.Terrain then
        return Game.Workspace.Terrain.Decoration
    end

    return Old(Object, Property)
end)
]]

local function SetNoShadows(Value)
    Lighting.GlobalShadows = not Value
end

Terrain:AddToggle("noshadows", {
    Text = "No Shadows",
    Default = false,
    Callback = SetNoShadows
})

RegisterHook("noshadows", Lighting, "GlobalShadows", function(Object, Property, Old)
    if Toggles.noshadows.Value and Object == Lighting then
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

local function SlideJump()
    if Functions.IsGrounded() then
        local cameraY = Functions.GetY() + math.pi
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

Core.AutoSlideJump = {
    Enable = function()
        Utils.AddConnection(connections.heartbeats, "AutoSlideJump", Heartbeat:Connect(function()
            task.wait(1)
            SlideJump()
        end))
    end,

    Disable = function()
        Utils.RemoveConnection(connections.heartbeats, "AutoSlideJump")
    end,
}

MovementTab:AddToggle("autoslidejump", {
    Text = "Auto Slide Jump",
    Default = false,
    Callback = function(Value)
        if Value then
            Core.AutoSlideJump.Enable()
        else
            Core.AutoSlideJump.Disable()
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
			if not Library or not LinearVelocity or not Toggles.walkspeed.Value then
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
 
    if Toggles.alwaysgrounded.Value and Self == workspace and Method == "Raycast" then
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

local Prism1 = _localplayer.LocalCharacter.Top.Prism1
local OriginalPrism1 = Prism1.CFrame

local function SetLongNeck(Value)
    Prism1.CFrame = Value and (OriginalPrism1 - Vector3.yAxis * 5) or OriginalPrism1
end

ExploitsTab:AddToggle("longneck", {
    Text = "Long Neck",
    Default = false,
    Callback = SetLongNeck
})

RegisterHook("longneck", Prism1, "CFrame", function(Object, Property, Old)
    if Toggles.longneck.Value and Object == Prism1 then
        return OriginalPrism1
    end

    return Old(Object, Property)
end)

ExploitsTab:AddDivider()

local function SetFreecam()
    Game.Workspace.Camera.CameraCFrame = workspace.CurrentCamera.CFrame
end

ExploitsTab:AddToggle("freecam", {
    Text = "Freecam",
    Default = false,
    Callback = SetFreecam
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
    if Toggles.freecam.Value and Object == workspace.CurrentCamera and Property == "CFrame" then
        return Game.Workspace.Camera.CameraCFrame
    end

    return Old(Object, Property)
end)

ExploitsTab:AddDivider()

local function SetCameraFov(Value)
    Functions.SetBaseFOV(Value and 90 or 70)
end

ExploitsTab:AddToggle("camerafov", {
    Text = "Higher FOV",
    Default = false,
    Callback = SetCameraFov
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

Core.FastCar = {
    Enable = function()
        OldCar = Utils.AddHook("FastCar", Functions.GainControl, function(p1)
            if not Toggles.fastcar.Value then
                return OldCar(p1)
            end
            p1.TopSpeed = Options.vehiclespeed.Value
            return p1
        end, "Lua")
    end,

    Disable = function()
        Utils.RemoveHook("FastCar")
        OldCar = nil
    end,
}

VehicleMisc:AddToggle("fastcar", {
    Text = "Vehicle Speed",
    Default = false,
    Callback = function(Value)
        if Value then
            Core.FastCar.Enable()
        else
            Core.FastCar.Disable()
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
RebuildContainers()
UpdateEspActive()