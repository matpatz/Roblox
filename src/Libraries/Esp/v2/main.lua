--// Knit
local Knit = shared.Knit
if not Knit then
    shared.Knit = loadstring(game:HttpGet("https://raw.githubusercontent.com/matpatz/Roblox/refs/heads/main/src/Modules/Knit/v1/main.lua"))()
    Knit = shared.Knit
end
repeat task.wait() until Knit and Knit.services

local services = Knit.services

-- // Services
local Players = services.Players
local RunService = services.RunService
local CoreGui = services.CoreGui
local Workspace = services.Workspace
local CollectionService = services.CollectionService

-- A container source can be a raw Instance, or a table that overrides the ESP
-- label: { Model = Instance, Name = string? } (Name may also be a function).
export type ContainerSource = Instance | { Model: Instance, Name: (string | ((Model: Instance) -> string))? }

export type ContainerDefinition = {
    Name: string?, -- Explicit container name; defaults to the map key.
    Color: Color3?, -- Base color for this container's targets.
    Location: (Instance | { ContainerSource } | (() -> (Instance | { ContainerSource })))?,
    Tag: string?, -- CollectionService tag; takes precedence over Location.
    Filter: ((Model: Instance) -> boolean)?, -- drops sources that do not match.
    Target: string?, -- Selector, e.g. "BasePart:Torso" or "Humanoid".
    Health: ((Model: Instance) -> (number?, number?))?,
    HealthAttribute: string?, -- attribute fallbacks when there is no Humanoid.
    MaxHealthAttribute: string?,
    Settings: { [string]: any }?, -- per-container setting overrides.
    [string]: any,
}

export type ContainerMap = { [string]: ContainerDefinition | Instance }

export type EspConfig = {
    Active: boolean?,
    Name: string?, -- container folder name.
    Parent: Instance?, -- Highlight container; one is created when absent.
    Containers: ContainerMap?, -- defaults to { Players = { Location = Players } }.
    [string]: any, -- any assignable setting (see Esp.Defaults).
}

export type ESP = {
    Active: boolean,
    Settings: any,
    Targets: { [Instance]: any },
    Containers: ContainerMap,
    Container: Instance?,
    Parent: Instance?,

    Enable: (self: ESP) -> (),
    Disable: (self: ESP) -> (),
    Clear: (self: ESP) -> (),
    Destroy: (self: ESP) -> (),
    SetContainer: (self: ESP, Containers: ContainerMap) -> (),
    RemoveContainer: (self: ESP, Name: string) -> (),
    GetContainer: (self: ESP, Name: string) -> ContainerDefinition?,
    GetContainers: (self: ESP) -> ContainerMap,
    SetBoxSize: (self: ESP, WidthScale: number?, HeightScale: number?) -> (),
    SetProperty: (self: ESP, Name: string, Value: any) -> (),
    GetProperty: (self: ESP, Name: string) -> any,
}

-- // Constants

local White = Color3.fromRGB(255, 255, 255)
local Red = Color3.fromRGB(255, 0, 0)
local Green = Color3.fromRGB(0, 255, 0)
local Yellow = Color3.fromRGB(255, 255, 0)
local Gray = Color3.fromRGB(128, 128, 128)

local FrameSkip = 5

local CornerSigns = {
    Vector3.new(1, 1, 1),
    Vector3.new(1, 1, -1),
    Vector3.new(1, -1, 1),
    Vector3.new(1, -1, -1),
    Vector3.new(-1, 1, 1),
    Vector3.new(-1, 1, -1),
    Vector3.new(-1, -1, 1),
    Vector3.new(-1, -1, -1),
}

local BoxCornerSigns = {
    Vector3.new(-1, 1, -1),
    Vector3.new(1, 1, -1),
    Vector3.new(1, 1, 1),
    Vector3.new(-1, 1, 1),
    Vector3.new(-1, -1, -1),
    Vector3.new(1, -1, -1),
    Vector3.new(1, -1, 1),
    Vector3.new(-1, -1, 1),
}

local BoxEdges = {
    { 1, 2 }, { 2, 3 }, { 3, 4 }, { 4, 1 },
    { 5, 6 }, { 6, 7 }, { 7, 8 }, { 8, 5 },
    { 1, 5 }, { 2, 6 }, { 3, 7 }, { 4, 8 },
}

-- R6 names first, R15 fallbacks second.
local SkeletonJoints = {
    { "Head" },
    { "Torso", "UpperTorso" },
    { "Left Arm", "LeftUpperArm" },
    { "Right Arm", "RightUpperArm" },
    { "Left Leg", "LeftUpperLeg" },
    { "Right Leg", "RightUpperLeg" },
}

local SkeletonPairs = {
    { 1, 2 }, { 2, 3 }, { 2, 4 }, { 2, 5 }, { 2, 6 },
}

-- // Helpers

local function CreateDrawing(ClassName, Properties)
    local Object = Drawing.new(ClassName)
    for Key, Value in next, Properties do
        Object[Key] = Value
    end
    return Object
end

local function HealthColor(Health, MaxHealth)
    if MaxHealth <= 0 then
        return Red
    end

    local Ratio = Health / MaxHealth
    if Ratio > 0.7 then
        return Green
    elseif Ratio > 0.3 then
        return Yellow
    end
    return Red
end

local function ResolveTarget(Source, Selector)
    if type(Selector) ~= "string" then
        return Source
    end

    local ClassName, ChildName = Selector:match("^([^:]+):(.+)$")
    if not ClassName then
        ClassName = Selector
    end

    local Root = if Source:IsA("Player") then Source.Character else Source
    if not Root then
        return Source
    end

    if ChildName then
        local Named = Root:FindFirstChild(ChildName, true)
        if Named then
            return Named
        end

        -- The child name may also be a class name (e.g. "BasePart:Humanoid").
        local Typed = Root:FindFirstChildWhichIsA(ChildName, true)
        if Typed then
            return Typed
        end
    end

    local Typed = Root:FindFirstChildWhichIsA(ClassName, true)
    return if Typed then Typed else Root
end

local function FindPrimaryPart(Model)
    if not Model then
        return nil
    end

    return (Model:IsA("Model") and Model.PrimaryPart)
        or Model:FindFirstChildWhichIsA("BasePart", true)
end

local function NormalizeSource(Source)
    if typeof(Source) == "Instance" then
        return Source, nil
    end
    if type(Source) == "table" then
        local Model = Source.Model
        if typeof(Model) == "Instance" then
            return Model, Source.Name
        end
    end
    return nil, nil
end

-- Screen-space bounds of the target, plus the anchors the 2D elements hang off.
local function GetBounds(ViewCamera, Model, Root, Head)
    local RootPos, RootVisible = ViewCamera:WorldToViewportPoint(Root.Position)
    local HeadPos, HeadVisible = ViewCamera:WorldToViewportPoint(Head.Position)

    local CF, Size
    if Model:IsA("BasePart") then
        CF, Size = Model.CFrame, Model.Size
    else
        CF, Size = Model:GetBoundingBox()
    end

    -- Points behind the camera project mirrored, so only keep the ones in front.
    local Half = Size / 2
    local MinX, MinY, MaxX, MaxY = math.huge, math.huge, -math.huge, -math.huge
    for _, Sign in next, CornerSigns do
        local Point = ViewCamera:WorldToViewportPoint(CF:PointToWorldSpace(Half * Sign))
        if Point.Z > 0 then
            MinX = math.min(MinX, Point.X)
            MinY = math.min(MinY, Point.Y)
            MaxX = math.max(MaxX, Point.X)
            MaxY = math.max(MaxY, Point.Y)
        end
    end

    local OnScreen = MinX ~= math.huge
    if not OnScreen then
        MinX = math.min(RootPos.X, HeadPos.X)
        MinY = math.min(RootPos.Y, HeadPos.Y)
        MaxX = math.max(RootPos.X, HeadPos.X)
        MaxY = math.max(RootPos.Y, HeadPos.Y)
    end

    return OnScreen, MinX, MinY, MaxX, MaxY, RootPos, RootVisible, HeadPos, HeadVisible, CF, Size
end

local function GetHealth(Model, Humanoid, Definition)
    if Definition.Health then
        local Success, Health, MaxHealth = pcall(Definition.Health, Model)
        if Success then
            return Health, MaxHealth
        end
        return nil, nil
    end

    if Humanoid then
        return Humanoid.Health, Humanoid.MaxHealth
    end

    local Health = Model:GetAttribute(Definition.HealthAttribute or "Health")
    if type(Health) ~= "number" then
        return nil, nil
    end

    local MaxHealth = Model:GetAttribute(Definition.MaxHealthAttribute or "MaxHealth")
    return Health, if type(MaxHealth) == "number" and MaxHealth > 0 then MaxHealth else nil
end

local function NewProjected(Count)
    local Projected = table.create(Count)
    for Index = 1, Count do
        Projected[Index] = { X = 0, Y = 0, Visible = false, Found = false }
    end
    return Projected
end

-- Reused every frame so updates never allocate.
local BoxProjected = NewProjected(#BoxCornerSigns)
local JointProjected = NewProjected(#SkeletonJoints)

-- // Settings

local Defaults = {
    MaxDist = 2000,

    -- 2D
    ShowBox = true,
    ShowName = true,
    ShowHeld = true,
    ShowTracer = true,
    ShowQuad = false,
    ShowHealth = false,
    ShowHealthBar = false,
    ShowDistance = false,
    ShowChams = false,
    TeamColor = false,
    PerformanceMode = false,

    -- 3D
    Show3DBox = false,
    ShowSkeleton = false,

    -- Colors stay nil so the container/instance Color (then white) shows through.
    BoxColor = nil,
    NameColor = nil,
    TracerColor = nil,
    QuadColor = nil,
    HealthTextColor = nil,
    DistanceColor = nil,
    ChamsColor = nil,
    Box3DColor = nil,
    SkeletonColor = nil,
    HealthBarColorOverride = nil,
    Color = nil,

    TracerThickness = 1,
    BoxWidthScale = 0.6,
    BoxHeightScale = 1,
}

local SettingKeys = {}
local Assignable = {}
for Key in next, Defaults do
    table.insert(SettingKeys, Key)
    Assignable[Key] = true
end

local Settings = {}
Settings.__index = Settings

function Settings.new(Overrides)
    local self = setmetatable({ Values = {}, Revision = 0 }, Settings)

    for Key, Value in next, Defaults do
        self.Values[Key] = Value
    end
    if Overrides then
        self:Apply(Overrides)
    end

    return self
end

function Settings:Apply(Overrides)
    for Key, Value in next, Overrides do
        if Assignable[Key] then
            self.Values[Key] = Value
            self.Revision += 1
        else
            warn(`[ESP] Settings: '{Key}' is not an assignable setting`)
        end
    end
end

function Settings:Set(Key, Value)
    if not Assignable[Key] then
        warn(`[ESP] Settings: '{Key}' is not an assignable setting`)
        return
    end

    self.Values[Key] = Value
    self.Revision += 1
end

-- // Target
-- One object per tracked Instance, owning its drawings and its resolved config.

local Target = {}
Target.__index = Target

local function CreateText(Size)
    return CreateDrawing("Text", {
        Size = Size,
        Center = true,
        Outline = true,
        Font = 2,
        Color = White,
        Visible = false,
    })
end

function Target.new(Owner, Model, Definition, Name)
    local self = setmetatable({}, Target)

    self.Owner = Owner
    self.Model = Model
    self.Definition = Definition
    self.Name = Name
    self.Owners = {}
    self.Connections = {}
    self.Anchor = ResolveTarget(Model, Definition.Target)
    self.SettingsRevision = -1

    self:CreateDrawings()
    self:ResolveConfig()

    return self
end

function Target:CreateDrawings()
    self.Box = CreateDrawing("Square", {
        Thickness = 2,
        Filled = false,
        Color = White,
        Visible = false,
    })
    self.NameText = CreateText(16)
    self.DistanceText = CreateText(14)
    self.HealthText = CreateText(14)
    self.Tracer = CreateDrawing("Line", { Thickness = 1, Color = White, Visible = false })
    self.Quad = CreateDrawing("Quad", { Thickness = 1, Color = White, Visible = false })
    self.HealthBar = CreateDrawing("Line", { Thickness = 3, Color = Green, Visible = false })
end

-- Definition keys win over instance settings, which win over the defaults.
function Target:ResolveConfig()
    local Values = self.Owner.Settings.Values
    local Definition = self.Definition
    local Overrides = Definition.Settings

    local Config = {}
    for _, Key in next, SettingKeys do
        local Value = Definition[Key]
        if Value == nil and Overrides then
            Value = Overrides[Key]
        end
        if Value == nil then
            Value = Values[Key]
        end
        Config[Key] = Value
    end

    self.Config = Config
    self.SettingsRevision = self.Owner.Settings.Revision
end

function Target:Connect(Signal, Callback)
    table.insert(self.Connections, Signal:Connect(Callback))
end

function Target:GetName()
    local Name = self.Name

    if type(Name) == "function" then
        local Success, Result = pcall(Name, self.Model)
        if Success and type(Result) == "string" and Result ~= "" then
            return Result
        end
    elseif type(Name) == "string" and Name ~= "" then
        return Name
    end

    return self.Model.Name
end

function Target:GetRig()
    local Model = self.Model

    local Character
    if Model:IsA("Player") then
        Character = Model.Character
    elseif Model:IsA("Model") or Model:IsA("BasePart") then
        Character = Model
    end
    if not Character or not Character.Parent then
        return nil
    end

    local Anchor = self.Anchor
    if self.Definition.Target and (Anchor == Model or not Anchor or not Anchor.Parent) then
        Anchor = ResolveTarget(Model, self.Definition.Target)
        self.Anchor = Anchor
    end

    local Root
    if Anchor and Anchor:IsA("BasePart") then
        Root = Anchor
    elseif Anchor and Anchor:IsA("Model") then
        Root = FindPrimaryPart(Anchor)
    elseif Character:IsA("BasePart") then
        Root = Character
    else
        Root = Character:FindFirstChild("HumanoidRootPart") or FindPrimaryPart(Character)
    end
    if not Root then
        return nil
    end

    local Head
    if Character:IsA("Model") then
        Head = Character:FindFirstChild("Head")
            or Character:FindFirstChild("UpperTorso")
            or Character:FindFirstChild("Torso")
            or Root
    else
        Head = Root
    end

    local Humanoid = if Character:IsA("Model") then Character:FindFirstChildOfClass("Humanoid") else nil
    return Character, Root, Head, Humanoid
end

function Target:GetLines(Pool, Count)
    local Lines = self[Pool]
    if Lines then
        return Lines
    end

    Lines = table.create(Count)
    for Index = 1, Count do
        Lines[Index] = CreateDrawing("Line", { Thickness = 1, Color = White, Visible = false })
    end
    self[Pool] = Lines

    return Lines
end

function Target:GetChams()
    if self.Chams then
        return self.Chams
    end

    local Chams = Instance.new("Highlight")
    Chams.FillTransparency = 0.7
    Chams.OutlineTransparency = 1
    Chams.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    Chams.Enabled = false
    Chams.Parent = self.Owner.Parent
    self.Chams = Chams

    return Chams
end

function Target:Hide()
    self.Box.Visible = false
    self.NameText.Visible = false
    self.DistanceText.Visible = false
    self.HealthText.Visible = false
    self.Tracer.Visible = false
    self.Quad.Visible = false
    self.HealthBar.Visible = false

    if self.Box3D then
        for _, Line in next, self.Box3D do
            Line.Visible = false
        end
    end
    if self.Skeleton then
        for _, Line in next, self.Skeleton do
            Line.Visible = false
        end
    end
    if self.Chams then
        self.Chams.Enabled = false
    end
end

function Target:Destroy()
    for _, Connection in next, self.Connections do
        Connection:Disconnect()
    end
    table.clear(self.Connections)

    self.Box:Remove()
    self.NameText:Remove()
    self.DistanceText:Remove()
    self.HealthText:Remove()
    self.Tracer:Remove()
    self.Quad:Remove()
    self.HealthBar:Remove()

    if self.Box3D then
        for _, Line in next, self.Box3D do
            Line:Remove()
        end
        self.Box3D = nil
    end
    if self.Skeleton then
        for _, Line in next, self.Skeleton do
            Line:Remove()
        end
        self.Skeleton = nil
    end
    if self.Chams then
        self.Chams:Destroy()
        self.Chams = nil
    end
end

function Target:Update(Context)
    if self.SettingsRevision ~= self.Owner.Settings.Revision then
        self:ResolveConfig()
    end
    local Config = self.Config

    local Character, Root, Head, Humanoid = self:GetRig()
    if not Character or not Root or not Head then
        return self:Hide()
    end

    local Camera = Context.Camera
    local Distance = (Context.CameraPosition - Root.Position).Magnitude
    if Distance > Config.MaxDist then
        return self:Hide()
    end

    local OnScreen, MinX, MinY, MaxX, MaxY, RootPos, RootVisible, HeadPos, HeadVisible, BoxCF, BoxSize =
        GetBounds(Camera, Character, Root, Head)
    if not OnScreen and not HeadVisible then
        return self:Hide()
    end

    local BaseColor = Config.Color or White
    if Config.TeamColor and self.Model:IsA("Player") then
        BaseColor = if self.Model.Team == Context.LocalPlayer.Team
            then self.Model.TeamColor.Color else Red
    end
    if Humanoid and (Humanoid.Health <= 0 or Humanoid:GetState() == Enum.HumanoidStateType.Dead) then
        BaseColor = Gray
    end

    -- One rect drives the box, the quad and the health bar.
    local RectX, RectY, RectWidth, RectHeight
    local BoxDrawn = Config.ShowBox and OnScreen
    if BoxDrawn then
        RectWidth = math.abs(MaxX - MinX) * (Config.BoxWidthScale / 0.6)
        RectHeight = math.abs(MaxY - MinY) * Config.BoxHeightScale
        RectX = (MinX + MaxX) / 2 - RectWidth / 2
        RectY = MinY
    elseif HeadVisible and RootVisible then
        RectHeight = math.abs(RootPos.Y - HeadPos.Y)
        RectWidth = RectHeight * 0.6
        RectX = RootPos.X - RectWidth / 2
        RectY = HeadPos.Y
    end

    local Box = self.Box
    if BoxDrawn then
        Box.Size = Vector2.new(RectWidth, RectHeight)
        Box.Position = Vector2.new(RectX, RectY)
        Box.Color = Config.BoxColor or BaseColor
        Box.Visible = true
    else
        Box.Visible = false
    end

    local AnchorY = if BoxDrawn then RectY else HeadPos.Y

    local NameText = self.NameText
    if Config.ShowName and HeadVisible then
        local Text = self:GetName()
        if Config.ShowHeld and self.Model:IsA("Player") then
            local Tool = Character:FindFirstChildOfClass("Tool")
            if Tool then
                Text = `{Text} [{Tool.Name}]`
            end
        end

        NameText.Text = Text
        NameText.Position = Vector2.new(HeadPos.X, AnchorY - 18)
        NameText.Color = Config.NameColor or BaseColor
        NameText.Visible = true
    else
        NameText.Visible = false
    end

    local DistanceText = self.DistanceText
    if Config.ShowDistance and HeadVisible then
        DistanceText.Text = `{math.floor(Distance)} studs`
        DistanceText.Position = Vector2.new(HeadPos.X, AnchorY - 34)
        DistanceText.Color = Config.DistanceColor or BaseColor
        DistanceText.Visible = true
    else
        DistanceText.Visible = false
    end

    local Health, MaxHealth = GetHealth(self.Model, Humanoid, self.Definition)

    local HealthText = self.HealthText
    if Config.ShowHealth and Health and HeadVisible then
        HealthText.Text = `{math.floor(Health)}/{math.floor(MaxHealth or Health)}`
        HealthText.Position = Vector2.new(HeadPos.X, HeadPos.Y + 4)
        HealthText.Color = Config.HealthTextColor or HealthColor(Health, MaxHealth or Health)
        HealthText.Visible = true
    else
        HealthText.Visible = false
    end

    local HealthBar = self.HealthBar
    if Config.ShowHealthBar and Health and RectX and MaxHealth and MaxHealth > 0 then
        local Ratio = math.clamp(Health / MaxHealth, 0, 1)
        local BarX = RectX - 6

        HealthBar.From = Vector2.new(BarX, RectY + RectHeight * (1 - Ratio))
        HealthBar.To = Vector2.new(BarX, RectY + RectHeight)
        HealthBar.Color = Config.HealthBarColorOverride or HealthColor(Health, MaxHealth)
        HealthBar.Visible = true
    else
        HealthBar.Visible = false
    end

    local Tracer = self.Tracer
    if Config.ShowTracer and RootVisible then
        Tracer.From = Vector2.new(Context.Viewport.X / 2, Context.Viewport.Y)
        Tracer.To = Vector2.new(RootPos.X, RootPos.Y)
        Tracer.Color = Config.TracerColor or BaseColor
        Tracer.Thickness = Config.TracerThickness
        Tracer.Visible = true
    else
        Tracer.Visible = false
    end

    local Quad = self.Quad
    if Config.ShowQuad and RectX then
        Quad.PointA = Vector2.new(RectX, RectY)
        Quad.PointB = Vector2.new(RectX + RectWidth, RectY)
        Quad.PointC = Vector2.new(RectX + RectWidth, RectY + RectHeight)
        Quad.PointD = Vector2.new(RectX, RectY + RectHeight)
        Quad.Color = Config.QuadColor or BaseColor
        Quad.Visible = true
    else
        Quad.Visible = false
    end

    if Config.ShowChams then
        local Chams = self:GetChams()
        Chams.Adornee = Character
        Chams.FillColor = Config.ChamsColor or BaseColor
        Chams.Enabled = true
    elseif self.Chams then
        self.Chams.Enabled = false
    end

    if Config.Show3DBox then
        local Lines = self:GetLines("Box3D", #BoxEdges)
        local Color = Config.Box3DColor or BaseColor

        local Half = BoxSize / 2
        for Index, Sign in next, BoxCornerSigns do
            local Point, Visible = Camera:WorldToViewportPoint(BoxCF:PointToWorldSpace(Half * Sign))
            local Projected = BoxProjected[Index]
            Projected.X, Projected.Y, Projected.Visible = Point.X, Point.Y, Visible
        end

        for Index, Edge in next, BoxEdges do
            local Line = Lines[Index]
            local First, Second = BoxProjected[Edge[1]], BoxProjected[Edge[2]]

            if First.Visible or Second.Visible then
                Line.From = Vector2.new(First.X, First.Y)
                Line.To = Vector2.new(Second.X, Second.Y)
                Line.Color = Color
                Line.Visible = true
            else
                Line.Visible = false
            end
        end
    elseif self.Box3D then
        for _, Line in next, self.Box3D do
            Line.Visible = false
        end
    end

    if Config.ShowSkeleton and Character:IsA("Model") then
        local Lines = self:GetLines("Skeleton", #SkeletonPairs)
        local Color = Config.SkeletonColor or BaseColor

        for Index, Names in next, SkeletonJoints do
            local Part
            for _, PartName in next, Names do
                Part = Character:FindFirstChild(PartName)
                if Part then
                    break
                end
            end

            local Projected = JointProjected[Index]
            if Part then
                local Point, Visible = Camera:WorldToViewportPoint(Part.Position)
                Projected.X, Projected.Y, Projected.Visible, Projected.Found = Point.X, Point.Y, Visible, true
            else
                Projected.Found = false
            end
        end

        for Index, Pair in next, SkeletonPairs do
            local Line = Lines[Index]
            local First, Second = JointProjected[Pair[1]], JointProjected[Pair[2]]

            if First.Found and Second.Found and (First.Visible or Second.Visible) then
                Line.From = Vector2.new(First.X, First.Y)
                Line.To = Vector2.new(Second.X, Second.Y)
                Line.Color = Color
                Line.Visible = true
            else
                Line.Visible = false
            end
        end
    elseif self.Skeleton then
        for _, Line in next, self.Skeleton do
            Line.Visible = false
        end
    end
end

-- // Container
-- Owns one entry of the container map: resolution, tracked sources, listeners.

local Container = {}
Container.__index = Container

function Container.new(Owner, Name, Definition)
    local self = setmetatable({}, Container)

    self.Owner = Owner
    self.Name = Name
    self.Definition = Definition
    self.Sources = {}
    self.Dynamic = Definition.Tag ~= nil or type(Definition.Location) == "function"

    return self
end

function Container:Resolve()
    local Definition = self.Definition

    if Definition.Tag then
        return CollectionService:GetTagged(Definition.Tag)
    end

    local Location = Definition.Location
    if Location == nil and self.Name == "Players" then
        Location = Players
    end

    if type(Location) == "function" then
        local Success, Result = pcall(Location)
        return if Success then Result else nil
    end

    return Location
end

function Container:GetSources()
    local Location = self:Resolve()

    if Location == Players then
        return Players:GetPlayers()
    elseif typeof(Location) == "Instance" then
        return Location:GetChildren()
    elseif type(Location) == "table" then
        return Location
    end

    return {}
end

function Container:Add(Source)
    local Model = NormalizeSource(Source)
    if not Model then
        return
    end

    local Filter = self.Definition.Filter
    if Filter and not Filter(Model) then
        return
    end

    self.Owner:Track(Source, self)
end

function Container:Sync()
    local Current = {}

    for _, Source in next, self:GetSources() do
        local Model = NormalizeSource(Source)
        if Model then
            Current[Model] = true
            self:Add(Source)
        end
    end

    for Model in next, self.Sources do
        if not Current[Model] then
            self.Owner:Untrack(Model, self.Name)
        end
    end

    self.Sources = Current
end

function Container:Attach()
    self:Detach()

    local Owner = self.Owner
    local Location = self:Resolve()

    if Location == Players then
        self.Added = Players.PlayerAdded:Connect(function(Player)
            self:Add(Player)
        end)
        self.Removed = Players.PlayerRemoving:Connect(function(Player)
            Owner:Untrack(Player, self.Name)
        end)
    elseif self.Definition.Tag then
        self.Added = CollectionService:GetInstanceAddedSignal(self.Definition.Tag):Connect(function(Model)
            self:Add(Model)
        end)
        self.Removed = CollectionService:GetInstanceRemovedSignal(self.Definition.Tag):Connect(function(Model)
            Owner:Untrack(Model, self.Name)
        end)
    elseif typeof(Location) == "Instance" then
        self.Added = Location.ChildAdded:Connect(function(Model)
            self:Add(Model)
        end)
        self.Removed = Location.ChildRemoved:Connect(function(Model)
            Owner:Untrack(Model, self.Name)
        end)
    end
end

function Container:Detach()
    if self.Added then
        self.Added:Disconnect()
        self.Added = nil
    end
    if self.Removed then
        self.Removed:Disconnect()
        self.Removed = nil
    end
end

-- // Esp

local EspMethods = {}

-- Fields that live on the instance; every other write is a setting.
local InstanceFields = {
    Active = true,
    Settings = true,
    Targets = true,
    Containers = true,
    ContainerObjects = true,
    Container = true,
    Parent = true,
    OwnsParent = true,
    Connection = true,
    Name = true,
}

EspMethods.__index = function(self, Key)
    local Value = EspMethods[Key]
    if Value ~= nil then
        return Value
    end

    local Settings = rawget(self, "Settings")
    return if Settings then Settings.Values[Key] else nil
end

EspMethods.__newindex = function(self, Key, Value)
    if InstanceFields[Key] then
        rawset(self, Key, Value)
    else
        rawget(self, "Settings"):Set(Key, Value)
    end
end

function EspMethods:Enable()
    self.Active = true
end

function EspMethods:Disable()
    self.Active = false
    for _, Entry in next, self.Targets do
        Entry:Hide()
    end
end

function EspMethods:ClearTargets()
    for _, Entry in next, self.Targets do
        Entry:Destroy()
    end
    table.clear(self.Targets)
end

function EspMethods:HasPlayersContainer()
    for Name, Definition in next, self.Containers do
        if Name == "Players" or Definition.Location == Players then
            return true
        end
    end
    return false
end

function EspMethods:Track(Source, Container)
    local Model, CustomName = NormalizeSource(Source)
    if not Model then
        return
    end
    if not (Model:IsA("Player") or Model:IsA("Model") or Model:IsA("BasePart")) then
        return
    end
    if Model == Players.LocalPlayer and self:HasPlayersContainer() then
        return
    end

    local Entry = self.Targets[Model]
    if Entry then
        Entry.Owners[Container.Name] = true
        if CustomName ~= nil then
            Entry.Name = CustomName
        end
        return
    end

    Entry = Target.new(self, Model, Container.Definition, CustomName)
    Entry.Owners[Container.Name] = true
    self.Targets[Model] = Entry

    if Model:IsA("Player") then
        Entry:Connect(Model.CharacterRemoving, function()
            Entry:Hide()
        end)
    end
end

function EspMethods:Untrack(Model, ContainerName)
    local Entry = self.Targets[Model]
    if not Entry then
        return
    end

    Entry.Owners[ContainerName] = nil
    if next(Entry.Owners) then
        return
    end

    Entry:Destroy()
    self.Targets[Model] = nil
end

function EspMethods:SetContainer(Containers)
    for _, Object in next, self.ContainerObjects do
        Object:Detach()
    end
    self:ClearTargets()

    local Normalized = {}
    for Key, Definition in next, Containers do
        if typeof(Definition) == "Instance" then
            Normalized[Key] = { Location = Definition }
        elseif type(Definition) == "table" then
            local Name = if type(Definition.Name) == "string" and Definition.Name ~= ""
                then Definition.Name else Key
            Normalized[Name] = Definition
        end
    end

    local Objects = {}
    for Name, Definition in next, Normalized do
        Objects[Name] = Container.new(self, Name, Definition)
    end

    self.Containers = Normalized
    self.ContainerObjects = Objects

    local FirstName, FirstDefinition = next(Normalized)
    self.Container = if FirstDefinition then Objects[FirstName]:Resolve() else nil

    for _, Object in next, Objects do
        Object:Sync()
    end
    for _, Object in next, Objects do
        Object:Attach()
    end
end

function EspMethods:RemoveContainer(Name)
    if self.Containers[Name] == nil then
        return
    end

    local Containers = {}
    for Key, Definition in next, self.Containers do
        if Key ~= Name then
            Containers[Key] = Definition
        end
    end
    self:SetContainer(Containers)
end

function EspMethods:GetContainer(Name)
    return self.Containers[Name]
end

function EspMethods:GetContainers()
    return self.Containers
end

function EspMethods:SetBoxSize(WidthScale, HeightScale)
    if WidthScale then
        self:SetProperty("BoxWidthScale", WidthScale)
    end
    if HeightScale then
        self:SetProperty("BoxHeightScale", HeightScale)
    end
end

function EspMethods:SetProperty(Key, Value)
    self.Settings:Set(Key, Value)
end

function EspMethods:GetProperty(Key)
    return self.Settings.Values[Key]
end

-- Detaches containers, drops targets and stops updating, but keeps the loop and
-- the folder around so the instance can be reused.
function EspMethods:Clear()
    for _, Object in next, self.ContainerObjects do
        Object:Detach()
    end
    self:ClearTargets()
    self.Active = false
end

function EspMethods:Destroy()
    self:Clear()

    if self.Connection then
        self.Connection:Disconnect()
        self.Connection = nil
    end
    if self.OwnsParent and self.Parent then
        self.Parent:Destroy()
        self.Parent = nil
    end
end

function EspMethods.new(Config)
    Config = Config or {}
    local self = setmetatable({}, EspMethods)

    local Overrides = {}
    for Key, Value in next, Config do
        if not InstanceFields[Key] then
            Overrides[Key] = Value
        end
    end

    rawset(self, "Active", Config.Active == true)
    rawset(self, "Name", Config.Name)
    rawset(self, "Settings", Settings.new(Overrides))
    rawset(self, "Targets", {})
    rawset(self, "Containers", {})
    rawset(self, "ContainerObjects", {})

    local Parent = Config.Parent
    local OwnsParent = false
    if not Parent then
        Parent = Instance.new("Folder")
        Parent.Name = Config.Name or tostring(math.random(1e9, 2e9))
        Parent.Parent = CoreGui
        OwnsParent = true
    end
    rawset(self, "Parent", Parent)
    rawset(self, "OwnsParent", OwnsParent)

    local Context = {
        LocalPlayer = Players.LocalPlayer,
        Camera = Workspace.CurrentCamera,
        Settings = self.Settings,
    }

    local Frame = 0

    self.Connection = RunService.RenderStepped:Connect(function()
        if not rawget(self, "Active") then
            return
        end

        -- Resolved per frame so instances survive respawns and camera swaps.
        local Camera = Workspace.CurrentCamera
        if not Camera then
            return
        end
        Context.Camera = Camera

        for _, Object in next, self.ContainerObjects do
            if Object.Dynamic then
                Object:Sync()
            end
        end

        Frame += 1
        if self.Settings.Values.PerformanceMode and Frame % FrameSkip ~= 0 then
            return
        end

        Context.Viewport = Camera.ViewportSize
        Context.CameraPosition = Camera.CFrame.Position

        for Model, Entry in next, self.Targets do
            if Model.Parent then
                Entry:Update(Context)
            else
                Entry:Destroy()
                self.Targets[Model] = nil
            end
        end
    end)

    self:SetContainer((Config.Containers or { Players = { Location = Players } }))

    return self
end

-- Defaults are exposed so a UI can build toggles/sliders from the same table.
EspMethods.Defaults = Defaults

return EspMethods
