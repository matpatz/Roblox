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

local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- A container source can be a raw Instance, or a table that overrides the ESP
-- label: { Model = Instance, Name = string? } (Name may also be a function).
export type ContainerSource = Instance | { Model: Instance, Name: (string | ((Target: Instance) -> string))? }
export type ContainerLocation = Instance | { ContainerSource } | (() -> (Instance | { ContainerSource }))

export type ContainerDefinition = {
    Name: string?, -- Explicit container name; defaults to the map key (the type, e.g. an EntityList Class) when absent.
    Color: Color3?, -- Base color for the container; falls back to per-element colors, then White.
    Location: ContainerLocation?,
    Target: string?,
    Settings: { [string]: any }?,
    [string]: any,
}

export type ContainerMap = { [string]: ContainerDefinition }

export type ESP = {
    Active: boolean,
    MaxDist: number,
    Container: Instance?,
    Containers: ContainerMap,

    ShowBox: boolean,
    ShowName: boolean,
    ShowHeld: boolean,
    ShowTracer: boolean,
    ShowQuad: boolean,
    TeamColor: boolean,
    ShowHealth: boolean,
    ShowDistance: boolean,
    ShowChams: boolean,
    ShowHealthBar: boolean,
    PerformanceMode: boolean,

    ShowSkeleton: boolean,
    Show3DBox: boolean,

    BoxColor: Color3,
    NameColor: Color3,
    TracerColor: Color3,
    QuadColor: Color3,
    HealthTextColor: Color3,
    DistanceColor: Color3,
    ChamsColor: Color3,
    Box3DColor: Color3,
    SkeletonColor: Color3,
    Color: Color3?, -- Base color; falls back to per-element colors, then White.
    HealthBarColorOverride: Color3?,

    TracerThickness: number,
    BoxWidthScale: number,
    BoxHeightScale: number,

    Enable: (self: ESP) -> (),
    Disable: (self: ESP) -> (),
    Clear: (self: ESP) -> (),
    SetContainer: (self: ESP, Containers: ContainerMap) -> (),
    RemoveContainer: (self: ESP, Name: string) -> (),
    GetContainer: (self: ESP, Name: string) -> ContainerDefinition?,
    GetContainers: (self: ESP) -> ContainerMap,
    SetBoxSize: (self: ESP, WidthScale: number?, HeightScale: number?) -> (),
    SetProperty: (self: ESP, Name: string, Value: any) -> (),
}

-- // Constants

local White = Color3.fromRGB(255, 255, 255)
local Red = Color3.fromRGB(255, 0, 0)
local Green = Color3.fromRGB(0, 255, 0)
local Yellow = Color3.fromRGB(255, 255, 0)
local Gray = Color3.fromRGB(128, 128, 128)

local ModelCornerSigns = {
    Vector3.new(1, 1, 1),
    Vector3.new(1, 1, -1),
    Vector3.new(1, -1, 1),
    Vector3.new(1, -1, -1),
    Vector3.new(-1, 1, 1),
    Vector3.new(-1, 1, -1),
    Vector3.new(-1, -1, 1),
    Vector3.new(-1, -1, -1),
}

local Box3DCornerSigns = {
    Vector3.new(-1, 1, -1),
    Vector3.new(1, 1, -1),
    Vector3.new(1, 1, 1),
    Vector3.new(-1, 1, 1),
    Vector3.new(-1, -1, -1),
    Vector3.new(1, -1, -1),
    Vector3.new(1, -1, 1),
    Vector3.new(-1, -1, 1),
}

local SkeletonPairs = {
    { "Head", "Torso" },
    { "Torso", "LeftArm" },
    { "Torso", "RightArm" },
    { "Torso", "LeftLeg" },
    { "Torso", "RightLeg" },
}

-- // Helpers

local function CreateDrawing(ClassName, Properties)
    local Obj = Drawing.new(ClassName)
    for K, V in next, Properties do
        Obj[K] = V
    end
    return Obj
end

local function GetColor(Health, MaxHealth)
    if MaxHealth <= 0 then
        return Red
    end
    local Percentage = Health / MaxHealth
    if Percentage > 0.7 then
        return Green
    elseif Percentage > 0.3 then
        return Yellow
    else
        return Red
    end
end

local function ResolveTarget(Source, Selector)
    if type(Selector) ~= "string" then
        return Source
    end

    local ClassName, ChildName = Selector:match("^([^:]+):(.+)$")
    if not ClassName then
        ClassName = Selector
    end

    local SearchRoot = Source
    if Source:IsA("Player") then
        SearchRoot = Source.Character
    end
    if not SearchRoot then
        return Source
    end

    if ChildName then
        local NamedTarget = SearchRoot:FindFirstChild(ChildName, true)
        if NamedTarget then
            return NamedTarget
        end

        -- The child name may also be a class name (e.g. "BasePart:Humanoid").
        local TypedNameTarget = SearchRoot:FindFirstChildWhichIsA(ChildName, true)
        if TypedNameTarget then
            return TypedNameTarget
        end
    end

    local TypedTarget = SearchRoot:FindFirstChildWhichIsA(ClassName, true)
    return if TypedTarget then TypedTarget else SearchRoot
end

local function FindPrimaryPart(Model)
    if not Model then
        return nil
    end

    return (Model:IsA("Model") and Model.PrimaryPart)
        or Model:FindFirstChildWhichIsA("BasePart", true)
end

-- Container sources may be raw Instances, or tables that describe a model
-- with a custom display name: { Model = Instance, Name = string }.
local function NormalizeSource(Source)
    if type(Source) == "table" then
        local Model = Source.Model
        if typeof(Model) == "Instance" then
            return Model, Source.Name
        end
        return nil, nil
    end
    return Source, nil
end

local function ResolveLocation(Name, Definition)
    local Location = Definition.Location
    if Location == nil and Name == "Players" then
        Location = Players
    end

    if type(Location) == "function" then
        local Success, Result = pcall(Location)
        return if Success then Result else nil
    end

    return Location
end

-- Screen-space bounds of the target's bounding box, plus the projected anchor
-- points the tracer / name / quad / health use.
local function GetModelCorners(ViewCamera, Model, RootPart, TopPart)
    local RootPosition, RootOnScreen = ViewCamera:WorldToViewportPoint(RootPart.Position)
    local TopPosition, TopOnScreen = ViewCamera:WorldToViewportPoint(TopPart.Position)

    local ModelCFrame, ModelSize
    if Model:IsA("BasePart") then
        ModelCFrame = Model.CFrame
        ModelSize = Model.Size
    else
        ModelCFrame, ModelSize = Model:GetBoundingBox()
    end

    -- Points behind the camera project mirrored, so only keep the ones in front.
    local HalfSize = ModelSize / 2
    local MinX, MinY = math.huge, math.huge
    local MaxX, MaxY = -math.huge, -math.huge
    for _, Sign in next, ModelCornerSigns do
        local Corner = ModelCFrame:PointToWorldSpace(Vector3.new(
            HalfSize.X * Sign.X,
            HalfSize.Y * Sign.Y,
            HalfSize.Z * Sign.Z
        ))
        local Position = ViewCamera:WorldToViewportPoint(Corner)
        if Position.Z > 0 then
            MinX = math.min(MinX, Position.X)
            MinY = math.min(MinY, Position.Y)
            MaxX = math.max(MaxX, Position.X)
            MaxY = math.max(MaxY, Position.Y)
        end
    end

    local OnScreen = MinX ~= math.huge
    if not OnScreen then
        -- Camera is inside the bounds; fall back to the anchor points.
        MinX = math.min(RootPosition.X, TopPosition.X)
        MinY = math.min(RootPosition.Y, TopPosition.Y)
        MaxX = math.max(RootPosition.X, TopPosition.X)
        MaxY = math.max(RootPosition.Y, TopPosition.Y)
        OnScreen = RootOnScreen or TopOnScreen
    end

    return OnScreen, MinX, MinY, MaxX, MaxY, RootPosition, RootOnScreen, TopPosition, TopOnScreen
end

local function GetJointPositions(Character)
    local Parts = {
        Head = Character:FindFirstChild("Head"),
        Torso = Character:FindFirstChild("Torso") or Character:FindFirstChild("UpperTorso"),
        LeftArm = Character:FindFirstChild("Left Arm") or Character:FindFirstChild("LeftUpperArm"),
        RightArm = Character:FindFirstChild("Right Arm") or Character:FindFirstChild("RightUpperArm"),
        LeftLeg = Character:FindFirstChild("Left Leg") or Character:FindFirstChild("LeftUpperLeg"),
        RightLeg = Character:FindFirstChild("Right Leg") or Character:FindFirstChild("RightUpperLeg"),
    }

    local Positions = {}
    for Name, Part in next, Parts do
        if Part then
            Positions[Name] = Part.Position
        end
    end
    return Positions
end

-- // Settings

local DefaultSettings = {
    Active = false,
    MaxDist = 2000,

    -- 2D options
    ShowBox = true,
    ShowName = true,
    ShowHeld = true,
    ShowTracer = true,
    ShowQuad = false,
    TeamColor = false,
    ShowHealth = false,
    ShowDistance = false,
    ShowChams = false,
    ShowHealthBar = false,
    PerformanceMode = false,

    -- 3D options
    ShowSkeleton = false,
    Show3DBox = false,

    -- Colors
    BoxColor = White,
    NameColor = White,
    TracerColor = White,
    QuadColor = White,
    HealthTextColor = Green,
    DistanceColor = White,
    ChamsColor = White,
    Box3DColor = White,
    SkeletonColor = White,
    HealthBarColorOverride = nil,
    Color = nil, -- per-container base color (see ContainerDefinition.Color)

    TracerThickness = 1,
    BoxWidthScale = 0.6,
    BoxHeightScale = 1,
}

-- Whitelist of assignable properties (anything in this list can be set via SetProperty).
local Assignable = {
    ShowBox = true,
    ShowName = true,
    ShowHeld = true,
    ShowTracer = true,
    ShowQuad = true,
    TeamColor = true,
    ShowHealth = true,
    ShowDistance = true,
    ShowChams = true,
    ShowHealthBar = true,
    PerformanceMode = true,
    ShowSkeleton = true,
    Show3DBox = true,
    MaxDist = true,
    BoxColor = true,
    NameColor = true,
    TracerColor = true,
    QuadColor = true,
    HealthTextColor = true,
    DistanceColor = true,
    ChamsColor = true,
    Box3DColor = true,
    SkeletonColor = true,
    Color = true,
    HealthBarColorOverride = true,
    TracerThickness = true,
    BoxWidthScale = true,
    BoxHeightScale = true,
}

local Settings = {}
Settings.__index = Settings

function Settings.new()
    local self = setmetatable({}, Settings)
    for Key, Value in next, DefaultSettings do
        self[Key] = Value
    end
    return self
end

function Settings:Set(Name, Value)
    if not Assignable[Name] then
        warn(`[ESP] SetProperty: '{Name}' is not an assignable property`)
        return
    end
    self[Name] = Value
end

-- // Target
-- One object per tracked Instance, owning all of its drawings and its
-- container/definition/override state.

local Target = {}
Target.__index = Target

function Target.new(Parent, Source, CustomName, Definition)
    local self = setmetatable({}, Target)
    self.Parent = Parent
    self.Source = Source
    self.Name = CustomName
    self.Definition = Definition
    self.Anchor = ResolveTarget(Source, Definition.Target)
    self.Owners = {}
    self.Connections = {}
    self:CreateDrawings()
    return self
end

function Target:CreateDrawings()
    -- Transparency is opaque-visibility in some executors (1 = fully visible) and
    -- Roblox-style in others (0 = fully visible), so leave it at the executor default.
    self.Box = CreateDrawing("Square", {
        Thickness = 2,
        Filled = false,
        Color = White,
        Visible = false,
    })

    self.NameText = CreateDrawing("Text", {
        Size = 16,
        Center = true,
        Outline = true,
        Font = 2,
        Color = White,
        Visible = false,
    })

    self.Tracer = CreateDrawing("Line", {
        Thickness = 1,
        Color = White,
        Visible = false,
    })

    self.Quad = CreateDrawing("Quad", {
        Color = White,
        Visible = false,
        Thickness = 1,
    })

    self.Health = CreateDrawing("Text", {
        Size = 14,
        Center = true,
        Outline = true,
        Font = 2,
        Color = White,
        Visible = false,
    })

    self.Distance = CreateDrawing("Text", {
        Size = 14,
        Center = true,
        Outline = true,
        Font = 2,
        Color = White,
        Visible = false,
    })

    local Highlight = Instance.new("Highlight")
    Highlight.FillTransparency = 0.7
    Highlight.OutlineTransparency = 1
    Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    Highlight.Enabled = false
    Highlight.Parent = self.Parent
    self.Chams = Highlight

    self.HealthBar = CreateDrawing("Line", {
        Thickness = 3,
        Color = Green,
        Visible = false,
    })

    self.Box3D = table.create(12)
    for Index = 1, 12 do
        self.Box3D[Index] = CreateDrawing("Line", {
            Thickness = 1,
            Color = White,
            Visible = false,
        })
    end

    self.Skeleton = table.create(15)
    for Index = 1, 15 do
        self.Skeleton[Index] = CreateDrawing("Line", {
            Thickness = 1,
            Color = White,
            Visible = false,
        })
    end
end

function Target:GetSetting(Name, Settings)
    local Definition = self.Definition
    if Definition then
        if Definition[Name] ~= nil then
            return Definition[Name]
        end
        local Overrides = Definition.Settings or Definition.Properties
        if Overrides and Overrides[Name] ~= nil then
            return Overrides[Name]
        end
    end
    return Settings[Name]
end

-- Custom display name: either a plain string, or a function called
-- with the target every frame (useful for dynamic labels).
function Target:GetName()
    local Custom = self.Name

    if type(Custom) == "function" then
        local Success, Result = pcall(Custom, self.Source)
        if Success and type(Result) == "string" and Result ~= "" then
            return Result
        end
    elseif type(Custom) == "string" and Custom ~= "" then
        return Custom
    end

    return self.Source.Name
end

function Target:GetParts()
    local Source = self.Source
    if Source == Players then
        return nil
    end

    local Character
    if Source:IsA("Player") then
        Character = Source.Character
    elseif Source:IsA("Model") or Source:IsA("BasePart") then
        Character = Source
    end
    if not Character then
        return nil
    end

    local Anchor = self.Anchor
    if self.Definition.Target and (Anchor == Source or not Anchor or not Anchor.Parent) then
        Anchor = ResolveTarget(Source, self.Definition.Target)
        self.Anchor = Anchor
    end

    local HRP
    if Anchor and Anchor:IsA("BasePart") then
        HRP = Anchor
    elseif Anchor and Anchor:IsA("Model") then
        HRP = FindPrimaryPart(Anchor)
    elseif Character:IsA("BasePart") then
        HRP = Character
    else
        HRP = Character:FindFirstChild("HumanoidRootPart") or FindPrimaryPart(Character)
    end

    local Head = if Character:IsA("Model") then Character:FindFirstChild("Head")
        or Character:FindFirstChild("UpperTorso")
        or Character:FindFirstChild("Torso")
        or Character:FindFirstChild("head")
        or Character:FindFirstChild("torso")
        or HRP else HRP
    local Humanoid = if Character:IsA("Model") then Character:FindFirstChildOfClass("Humanoid") else nil

    if HRP and Head then
        return Character, HRP, Head, Humanoid
    end
    return nil, nil, nil, nil
end

function Target:Hide()
    self.Box.Visible = false
    self.NameText.Visible = false
    self.Tracer.Visible = false
    self.Quad.Visible = false
    self.Health.Visible = false
    self.Distance.Visible = false
    self.HealthBar.Visible = false
    for _, Line in next, self.Box3D do
        Line.Visible = false
    end
    for _, Line in next, self.Skeleton do
        Line.Visible = false
    end
    self.Chams.Enabled = false
end

function Target:Destroy()
    for _, Connection in next, self.Connections do
        if Connection and Connection.Disconnect then
            Connection:Disconnect()
        end
    end
    table.clear(self.Connections)

    self.Box:Remove()
    self.NameText:Remove()
    self.Tracer:Remove()
    self.Quad:Remove()
    self.Health:Remove()
    self.Distance:Remove()
    self.HealthBar:Remove()
    for _, Line in next, self.Box3D do
        Line:Remove()
    end
    for _, Line in next, self.Skeleton do
        Line:Remove()
    end
    self.Chams:Destroy()
end

function Target:Update(Context)
    local Settings = Context.Settings
    local ViewCamera = Context.Camera
    local Viewport = Context.Viewport
    local ViewLocalPlayer = Context.LocalPlayer

    local Character, HRP, Head, Humanoid = self:GetParts()
    if not Character or not HRP or not Head then
        return self:Hide()
    end

    local MaxDist = self:GetSetting("MaxDist", Settings)
    local TeamColor = self:GetSetting("TeamColor", Settings)
    local ShowBox = self:GetSetting("ShowBox", Settings)
    local ShowName = self:GetSetting("ShowName", Settings)
    local ShowHeld = self:GetSetting("ShowHeld", Settings)
    local ShowTracer = self:GetSetting("ShowTracer", Settings)
    local ShowQuad = self:GetSetting("ShowQuad", Settings)
    local ShowHealth = self:GetSetting("ShowHealth", Settings)
    local ShowDistance = self:GetSetting("ShowDistance", Settings)
    local ShowChams = self:GetSetting("ShowChams", Settings)
    local ShowHealthBar = self:GetSetting("ShowHealthBar", Settings)
    local Show3DBox = self:GetSetting("Show3DBox", Settings)
    local ShowSkeleton = self:GetSetting("ShowSkeleton", Settings)
    local BoxColor = self:GetSetting("BoxColor", Settings)
    local NameColor = self:GetSetting("NameColor", Settings)
    local TracerColor = self:GetSetting("TracerColor", Settings)
    local QuadColor = self:GetSetting("QuadColor", Settings)
    local HealthTextColor = self:GetSetting("HealthTextColor", Settings)
    local ChamsColor = self:GetSetting("ChamsColor", Settings)
    local Box3DColor = self:GetSetting("Box3DColor", Settings)
    local SkeletonColor = self:GetSetting("SkeletonColor", Settings)
    local HealthBarColorOverride = self:GetSetting("HealthBarColorOverride", Settings)
    local TracerThickness = self:GetSetting("TracerThickness", Settings)
    local BoxWidthScale = self:GetSetting("BoxWidthScale", Settings)
    local BoxHeightScale = self:GetSetting("BoxHeightScale", Settings)

    local Dist = (Context.CameraPos - HRP.Position).Magnitude
    if Dist > MaxDist then
        return self:Hide()
    end

    local ModelOnScreen, MinX, MinY, MaxX, MaxY, HRPPos, HRPOnScreen, HeadPos, HeadOnScreen =
        GetModelCorners(ViewCamera, Character, HRP, Head)

    local BaseCol = self:GetSetting("Color", Settings) or White
    if self.Source:IsA("Player") and TeamColor then
        if self.Source.Team == ViewLocalPlayer.Team then
            BaseCol = self.Source.TeamColor.Color
        else
            BaseCol = Red
        end
    end
    if Humanoid and (Humanoid.Health <= 0 or Humanoid:GetState() == Enum.HumanoidStateType.Dead) then
        BaseCol = Gray
    end

    -- Box
    if ShowBox and ModelOnScreen then
        local Height = math.abs(MaxY - MinY) * (BoxHeightScale or 1)
        local Width = math.abs(MaxX - MinX) * ((BoxWidthScale or 0.6) / 0.6)

        self.Box.Size = Vector2.new(Width, Height)
        self.Box.Position = Vector2.new((MinX + MaxX) / 2 - Width / 2, MinY)
        self.Box.Color = BoxColor or BaseCol
        self.Box.Visible = true
    else
        self.Box.Visible = false
    end

    -- Name + Distance
    if (ShowName or ShowDistance) and HeadOnScreen then
        local NameText = ""
        local DistanceText = ""

        if ShowName then
            NameText = self:GetName()
            if ShowHeld and self.Source:IsA("Player") then
                local Tool = Character:FindFirstChildOfClass("Tool")
                if Tool then
                    NameText = `{NameText} [{Tool.Name}]`
                end
            end
        end

        if ShowDistance then
            DistanceText = `{math.floor(Dist)} studs`
        end

        local Combined = NameText
        if NameText ~= "" and DistanceText ~= "" then
            Combined = `{NameText} | {DistanceText}`
        elseif DistanceText ~= "" then
            Combined = DistanceText
        end

        local Label = self.NameText
        Label.Position = Vector2.new(HeadPos.X, HeadPos.Y - 15)
        Label.Text = Combined
        Label.Color = NameColor or BaseCol
        Label.Visible = true
    else
        self.NameText.Visible = false
    end

    -- Tracer
    if ShowTracer and HRPOnScreen then
        local Tracer = self.Tracer
        Tracer.From = Vector2.new(Viewport.X / 2, Viewport.Y)
        Tracer.To = Vector2.new(HRPPos.X, HRPPos.Y)
        Tracer.Color = TracerColor or BaseCol
        Tracer.Thickness = TracerThickness or 1
        Tracer.Visible = true
    else
        self.Tracer.Visible = false
    end

    -- Quad
    if ShowQuad and HRPOnScreen and HeadOnScreen then
        local Quad = self.Quad
        local HeightQ = math.abs(HRPPos.Y - HeadPos.Y)
        local WidthQ = HeightQ * 0.6
        local HalfWidth = WidthQ / 2

        Quad.PointA = Vector2.new(HRPPos.X - HalfWidth, HeadPos.Y)
        Quad.PointB = Vector2.new(HRPPos.X + HalfWidth, HeadPos.Y)
        Quad.PointC = Vector2.new(HRPPos.X + HalfWidth, HRPPos.Y)
        Quad.PointD = Vector2.new(HRPPos.X - HalfWidth, HRPPos.Y)
        Quad.Color = QuadColor or BaseCol
        Quad.Visible = true
    else
        self.Quad.Visible = false
    end

    -- Health text
    if ShowHealth and Humanoid and HeadOnScreen then
        local Health = self.Health
        local HealthCol = HealthTextColor or GetColor(Humanoid.Health, Humanoid.MaxHealth)

        Health.Position = Vector2.new(HeadPos.X, HeadPos.Y + 5)
        Health.Text = `{math.floor(Humanoid.Health)}/{math.floor(Humanoid.MaxHealth)}`
        Health.Color = HealthCol
        Health.Visible = true
    else
        self.Health.Visible = false
    end

    -- Health bar
    if ShowHealthBar and Humanoid and HRPOnScreen and HeadOnScreen then
        local Bar = self.HealthBar
        local HeightHB = math.abs(HRPPos.Y - HeadPos.Y)
        local WidthHB = HeightHB * 0.6
        local BoxLeftHB = HRPPos.X - WidthHB / 2
        local BoxTopHB = HeadPos.Y

        local MaxH = Humanoid.MaxHealth
        local HP = Humanoid.Health
        local HealthPct = if MaxH > 0 then HP / MaxH else 0
        local BarHeight = HeightHB * math.clamp(HealthPct, 0, 1)

        Bar.From = Vector2.new(BoxLeftHB - 6, BoxTopHB + HeightHB - BarHeight)
        Bar.To = Vector2.new(BoxLeftHB - 6, BoxTopHB + HeightHB)
        Bar.Color = HealthBarColorOverride or GetColor(HP, MaxH)
        Bar.Visible = true
    else
        self.HealthBar.Visible = false
    end

    -- Chams
    if ShowChams then
        self.Chams.Adornee = Character
        self.Chams.Enabled = true
        self.Chams.FillColor = ChamsColor or BaseCol
    else
        self.Chams.Enabled = false
    end

    -- 3D box
    if Show3DBox then
        local Lines = self.Box3D
        local Size = HRP.Size * 1.5
        local CF = HRP.CFrame

        local Points2D = table.create(8)
        local OnScreenAny = false

        for Index = 1, 8 do
            local Sign = Box3DCornerSigns[Index]
            local WorldPos = (CF * CFrame.new(
                Sign.X * Size.X / 2,
                Sign.Y * Size.Y / 2,
                Sign.Z * Size.Z / 2
            )).Position
            local V2, OnScreen = ViewCamera:WorldToViewportPoint(WorldPos)
            Points2D[Index] = { Vector2.new(V2.X, V2.Y), OnScreen }
            if OnScreen then
                OnScreenAny = true
            end
        end

        if OnScreenAny then
            local Col = Box3DColor or BaseCol

            local function SetLine(Index, FirstIndex, SecondIndex)
                local First, Second = Points2D[FirstIndex], Points2D[SecondIndex]
                local Line = Lines[Index]
                if First[2] or Second[2] then
                    Line.From = First[1]
                    Line.To = Second[1]
                    Line.Color = Col
                    Line.Visible = true
                else
                    Line.Visible = false
                end
            end

            SetLine(1, 1, 2)
            SetLine(2, 2, 3)
            SetLine(3, 3, 4)
            SetLine(4, 4, 1)
            SetLine(5, 5, 6)
            SetLine(6, 6, 7)
            SetLine(7, 7, 8)
            SetLine(8, 8, 5)
            SetLine(9, 1, 5)
            SetLine(10, 2, 6)
            SetLine(11, 3, 7)
            SetLine(12, 4, 8)
        else
            for _, Line in next, Lines do
                Line.Visible = false
            end
        end
    else
        for _, Line in next, self.Box3D do
            Line.Visible = false
        end
    end

    -- Skeleton
    if ShowSkeleton then
        local Lines = self.Skeleton
        local Joints = GetJointPositions(Character)

        local function Project(Joint)
            local Position = Joints[Joint]
            if not Position then
                return nil, false
            end
            local V, OnScreen = ViewCamera:WorldToViewportPoint(Position)
            return Vector2.new(V.X, V.Y), OnScreen
        end

        local Index = 1
        local Col = SkeletonColor or BaseCol

        for _, Pair in next, SkeletonPairs do
            local First, FirstOnScreen = Project(Pair[1])
            local Second, SecondOnScreen = Project(Pair[2])
            local Line = Lines[Index]
            Index += 1

            if First and Second and (FirstOnScreen or SecondOnScreen) then
                Line.From = First
                Line.To = Second
                Line.Color = Col
                Line.Visible = true
            else
                Line.Visible = false
            end
        end

        for Remaining = Index, #Lines do
            Lines[Remaining].Visible = false
        end
    else
        for _, Line in next, self.Skeleton do
            Line.Visible = false
        end
    end
end

-- // Container
-- Owns the resolved location, the tracked source set and the add/remove
-- listeners for a single entry of the container map.

local Container = {}
Container.__index = Container

function Container.new(Name, Definition)
    local self = setmetatable({}, Container)
    self.Name = Name
    self.Definition = Definition
    self.Sources = {}
    return self
end

function Container:ResolveLocation()
    return ResolveLocation(self.Name, self.Definition)
end

function Container:GetSources()
    local Location = self:ResolveLocation()
    if Location == Players then
        return Players:GetPlayers()
    elseif typeof(Location) == "Instance" then
        return Location:GetChildren()
    elseif type(Location) == "table" then
        return Location
    end
    return {}
end

function Container:IsDynamic()
    return type(self.Definition.Location) == "function"
end

function Container:Sync(Esp)
    local CurrentSources = {}
    for _, Source in next, self:GetSources() do
        local Model = NormalizeSource(Source)
        if typeof(Model) == "Instance" then
            CurrentSources[Model] = true
            Esp:Track(Source, self)
        end
    end

    for Source in next, self.Sources do
        if not CurrentSources[Source] then
            Esp:Untrack(Source, self.Name)
        end
    end
    self.Sources = CurrentSources
end

function Container:Attach(Esp)
    self:Detach()

    local Location = self:ResolveLocation()
    if Location == Players then
        self.Added = Players.PlayerAdded:Connect(function(Source)
            Esp:Track(Source, self)
        end)
        self.Removed = Players.PlayerRemoving:Connect(function(Source)
            Esp:Untrack(Source, self.Name)
        end)
    elseif type(self.Definition.Location) ~= "function" and typeof(Location) == "Instance" then
        self.Added = Location.ChildAdded:Connect(function(Source)
            Esp:Track(Source, self)
        end)
        self.Removed = Location.ChildRemoved:Connect(function(Source)
            Esp:Untrack(Source, self.Name)
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

-- // ESP

local ESP = {}

-- Fields that live on the instance itself; every other write is a setting.
local InstanceFields = {
    Settings = true,
    Targets = true,
    Containers = true,
    ContainerObjects = true,
    Container = true,
    Parent = true,
}

ESP.__index = function(self, Key)
    local Method = ESP[Key]
    if Method ~= nil then
        return Method
    end
    return rawget(self, "Settings")[Key]
end

ESP.__newindex = function(self, Key, Value)
    if InstanceFields[Key] then
        rawset(self, Key, Value)
    else
        rawget(self, "Settings")[Key] = Value
    end
end

function ESP:Enable()
    self.Active = true
end

function ESP:Disable()
    self.Active = false
    for _, Entry in next, self.Targets do
        Entry:Hide()
    end
end

function ESP:ClearTargets()
    while true do
        local Model = next(self.Targets)
        if not Model then
            break
        end
        self.Targets[Model]:Destroy()
        self.Targets[Model] = nil
    end
end

function ESP:HasPlayersContainer()
    for Name, Definition in next, self.Containers do
        if Name == "Players" or Definition.Location == Players then
            return true
        end
    end
    return false
end

function ESP:Track(Source, Container)
    local Model, CustomName = NormalizeSource(Source)

    if typeof(Model) ~= "Instance" then
        return
    end
    if not (Model:IsA("Player") or Model:IsA("Model") or Model:IsA("BasePart")) then
        return
    end
    if Model == LocalPlayer and self:HasPlayersContainer() then
        return
    end

    local Entry = self.Targets[Model]
    if Entry then
        Entry.Owners[Container.Name] = true
        Entry.Definition = Container.Definition
        if CustomName then
            Entry.Name = CustomName
        end
        Entry.Anchor = ResolveTarget(Model, Container.Definition.Target)
        return
    end

    Entry = Target.new(self.Parent, Model, CustomName, Container.Definition)
    Entry.Owners[Container.Name] = true
    self.Targets[Model] = Entry

    if Model:IsA("Player") and Model.CharacterRemoving then
        table.insert(Entry.Connections, Model.CharacterRemoving:Connect(function()
            Entry:Hide()
        end))
    end
end

function ESP:Untrack(Model, ContainerName)
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

-- Public API
-- Container definitions support Location (Instance, Instance list, or function),
-- Target selectors such as "BasePart:Torso", and direct or nested setting overrides.
-- A definition may set an explicit .Name; SetContainer registers it under that name,
-- falling back to the map key (the type, e.g. an EntityList Class) when .Name is absent.

function ESP:SetContainer(Containers)
    for _, Object in next, self.ContainerObjects do
        Object:Detach()
    end
    self:ClearTargets()

    local Normalized = {}
    for Name, Definition in next, Containers do
        if typeof(Definition) == "Instance" then
            Normalized[Name] = { Location = Definition }
        elseif type(Definition) == "table" then
            -- Prefer an explicit .Name on the definition (e.g. an entity's Class/type),
            -- otherwise register under the map key (the type from EntityList).
            local ContainerName = if type(Definition.Name) == "string"
                and Definition.Name ~= "" then Definition.Name else Name
            Normalized[ContainerName] = Definition
        end
    end

    local Objects = {}
    for Name, Definition in next, Normalized do
        Objects[Name] = Container.new(Name, Definition)
    end

    self.Containers = Normalized
    self.ContainerObjects = Objects

    local FirstName, FirstDefinition = next(Normalized)
    self.Container = FirstDefinition and ResolveLocation(FirstName, FirstDefinition) or nil

    for _, Object in next, Objects do
        Object:Sync(self)
    end
    for _, Object in next, Objects do
        Object:Attach(self)
    end
end

function ESP:RemoveContainer(Name)
    if self.Containers[Name] == nil then
        return
    end

    local Containers = {}
    for ContainerName, Definition in next, self.Containers do
        if ContainerName ~= Name then
            Containers[ContainerName] = Definition
        end
    end
    self:SetContainer(Containers)
end

function ESP:GetContainer(Name)
    return self.Containers[Name]
end

function ESP:GetContainers()
    return self.Containers
end

function ESP:SetBoxSize(WidthScale, HeightScale)
    if WidthScale then
        self.BoxWidthScale = WidthScale
    end
    if HeightScale then
        self.BoxHeightScale = HeightScale
    end
end

function ESP:SetProperty(Name, Value)
    self.Settings:Set(Name, Value)
end

function ESP:Clear()
    for _, Object in next, self.ContainerObjects do
        Object:Detach()
    end
    self:ClearTargets()
    self.Active = false
end

-- // Instance

local function NewESP()
    local self = setmetatable({}, ESP)

    rawset(self, "Settings", Settings.new())
    rawset(self, "Targets", {})
    rawset(self, "Containers", {})
    rawset(self, "ContainerObjects", {})

    local Parent = Instance.new("Folder")
    Parent.Parent = CoreGui
    Parent.Name = tostring(math.random(1e9, 2e9))
    self.Parent = Parent

    local Context = {
        Camera = Camera,
        LocalPlayer = LocalPlayer,
        Settings = self.Settings,
    }

    local FrameCount = 0
    local UpdateInterval = 5

    RunService.RenderStepped:Connect(function()
        if not self.Active then
            return
        end

        for _, Object in next, self.ContainerObjects do
            if Object:IsDynamic() then
                Object:Sync(self)
            end
        end

        FrameCount += 1
        if self.PerformanceMode and FrameCount % UpdateInterval ~= 0 then
            return
        end

        Context.Viewport = Camera.ViewportSize
        Context.CameraPos = Camera.CFrame.Position

        for Model, Entry in next, self.Targets do
            if not Model.Parent then
                Entry:Destroy()
                self.Targets[Model] = nil
            else
                Entry:Update(Context)
            end
        end
    end)

    self:SetContainer({ Players = { Location = Players } })

    return self
end

return NewESP()
