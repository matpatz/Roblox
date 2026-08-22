local Services = loadstring(game:HttpGet(
    "https://www.voltex.website/src/Modules/Variables.lua"
))()

-- A container source can be a raw Instance, or a table that overrides the ESP
-- label: { Model = Instance, Name = string? } (Name may also be a function).
export type ContainerSource = Instance | { Model: Instance, Name: (string | ((Target: Instance) -> string))? }
export type ContainerLocation = Instance | { ContainerSource } | (() -> (Instance | { ContainerSource }))

export type ContainerDefinition = {
    Name: string?, -- Explicit container name; defaults to the map key (the type, e.g. an EntityList Class) when absent.
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
    ShowCorners: boolean,
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
    CornerColor: Color3,
    NameColor: Color3,
    TracerColor: Color3,
    QuadColor: Color3,
    HealthTextColor: Color3,
    DistanceColor: Color3,
    ChamsColor: Color3,
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

local ESP = {}
ESP.__index = ESP

local self = setmetatable({}, ESP)

    -- Services
    local Players = Services["Players"]
    local RunService = Services["RunService"]
    local CoreGui = Services["CoreGui"]
    local Workspace = Services["Workspace"]
    local Camera = Workspace.CurrentCamera
    local LocalPlayer = Players.LocalPlayer

    local Parent = Instance.new("Folder")
    Parent.Parent = CoreGui
    Parent.Name = tostring(math.random(1e9, 2e9))

    -- State
    self.Active = false
    self.MaxDist = 2000
    self.Container = Players
    self.Containers = {
        Players = {
            Location = Players,
        },
    }

    -- 2D options
    self.ShowBox = true
    self.ShowCorners = true
    self.ShowName = true
    self.ShowHeld = true
    self.ShowTracer = true
    self.ShowQuad = false
    self.TeamColor = false
    self.ShowHealth = false
    self.ShowDistance = false
    self.ShowChams = false
    self.ShowHealthBar = false
    self.PerformanceMode = false

    -- 3D options
    self.ShowSkeleton = false
    self.Show3DBox = false

    -- Colors
    self.BoxColor = Color3.fromRGB(255, 255, 255)
    self.CornerColor = Color3.fromRGB(255, 255, 255)
    self.NameColor = Color3.fromRGB(255, 255, 255)
    self.TracerColor = Color3.fromRGB(255, 255, 255)
    self.QuadColor = Color3.fromRGB(255, 255, 255)
    self.HealthTextColor = Color3.fromRGB(0, 255, 0)
    self.DistanceColor = Color3.fromRGB(255, 255, 255)
    self.ChamsColor = Color3.fromRGB(255, 255, 255)
    self.HealthBarColorOverride = nil

    self.TracerThickness = 1
    self.BoxWidthScale = 0.6
    self.BoxHeightScale = 1

    -- Per-target drawing storage
    local Boxes = {}
    local Names = {}
    local Tracers = {}
    local Quads = {}
    local Healths = {}
    local Distances = {}
    local Chams = {}
    local HealthBars = {}
    local Corners = {}
    local Box3DLines = {}
    local SkeletonLines = {}

    local Tracked = {}
    local Connections = {}
    local TargetData = {}
    local ContainerSources = {}

    local FrameCount = 0
    local UpdateInterval = 5
    local ViewportSize = Camera.ViewportSize

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

    local ContainerAddedConnections = {}
    local ContainerRemovedConnections = {}

    -- Helpers

    local function IsPlayerContainer()
        for Name, Definition in self.Containers do
            if Name == "Players" or Definition.Location == Players then
                return true
            end
        end
        return false
    end

    local function CreateDrawing(Type, Properties)
        local Obj = Drawing.new(Type)
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

    local function GetTargetSetting(Target, Name)
        local Data = TargetData[Target]
        local Definition = Data and Data.Definition
        if Definition then
            if Definition[Name] ~= nil then
                return Definition[Name]
            end
            local Overrides = Definition.Settings or Definition.Properties
            if Overrides and Overrides[Name] ~= nil then
                return Overrides[Name]
            end
        end
        return self[Name]
    end

    -- Custom display name: either a plain string, or a function called
    -- with the target every frame (useful for dynamic labels).
    local function GetTargetName(Target)
        local Data = TargetData[Target]
        local Custom = Data and Data.Name

        if typeof(Custom) == "function" then
            local Success, Result = pcall(Custom, Target)
            if Success and type(Result) == "string" and Result ~= "" then
                return Result
            end
        elseif type(Custom) == "string" and Custom ~= "" then
            return Custom
        end

        return if typeof(Target) == "Instance" then Target.Name else "Target"
    end

    local function ResolveLocation(Name, Definition)
        local Location = Definition.Location
        if Location == nil and Name == "Players" then
            Location = Players
        end

        if typeof(Location) == "function" then
            local Success, Result = pcall(Location)
            return if Success then Result else nil
        end

        return Location
    end

    local function GetSources(Name, Definition)
        local Location = ResolveLocation(Name, Definition)
        if Location == Players then
            return Players:GetPlayers()
        elseif typeof(Location) == "Instance" then
            return Location:GetChildren()
        elseif typeof(Location) == "table" then
            return Location
        end
        return {}
    end

    -- Container sources may be raw Instances, or tables that describe a model
    -- with a custom display name: { Model = Instance, Name = string }.
    local function NormalizeSource(Source)
        if typeof(Source) == "table" then
            local Model = Source.Model
            if typeof(Model) == "Instance" then
                return Model, Source.Name
            end
            return nil, nil
        end
        return Source, nil
    end

    local function ResolveTarget(Source, Selector)
        if typeof(Selector) ~= "string" then
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
        end

        if ChildName then
            local Success, TypedNameTarget = pcall(function()
                return SearchRoot:FindFirstChildWhichIsA(ChildName, true)
            end)
            if Success and TypedNameTarget then
                return TypedNameTarget
            end
        end

        local Success, TypedTarget = pcall(function()
            return SearchRoot:FindFirstChildWhichIsA(ClassName, true)
        end)
        return if Success and TypedTarget then TypedTarget else SearchRoot
    end

    local function GetCharacterFromTarget(Target)
        local Data = TargetData[Target]
        local Source = Data and Data.Source or Target

        if Source == Players then
            return nil
        end
        if Source:IsA("Player") then
            return Source.Character
        end
        if Source:IsA("Model") or Source:IsA("BasePart") then
            return Source
        end
        return nil
    end

    local function FindPrimaryPart(Model)
        if not Model then
            return nil
        end

        return (Model:IsA("Model") and Model.PrimaryPart)
            or Model:FindFirstChildWhichIsA("BasePart", true)
    end

    local function GetParts(Target)
        local Character = GetCharacterFromTarget(Target)
        if not Character then
            return nil, nil, nil, nil
        end

        local Data = TargetData[Target]
        local Anchor = Data and Data.Anchor
        if Data and Data.Definition.Target and (Anchor == Data.Source or not Anchor or not Anchor.Parent) then
            Anchor = ResolveTarget(Data.Source, Data.Definition.Target)
            Data.Anchor = Anchor
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

    -- Project model bounds so non-character containers can use the 2D ESP too.
    local function GetModelCorners(Model, RootPart, TopPart, IsCharacter)
        local RootPosition, RootOnScreen = Camera:WorldToViewportPoint(RootPart.Position)
        local TopPosition, TopOnScreen = Camera:WorldToViewportPoint(TopPart.Position)
        local MinX, MinY = math.huge, math.huge
        local MaxX, MaxY = -math.huge, -math.huge
        local OnScreen = false

        if IsCharacter then
            if RootOnScreen then
                OnScreen = true
                MinX = RootPosition.X
                MinY = RootPosition.Y
                MaxX = RootPosition.X
                MaxY = RootPosition.Y
            end
            if TopOnScreen then
                OnScreen = true
                MinX = math.min(MinX, TopPosition.X)
                MinY = math.min(MinY, TopPosition.Y)
                MaxX = math.max(MaxX, TopPosition.X)
                MaxY = math.max(MaxY, TopPosition.Y)
            end
            return OnScreen, MinX, MinY, MaxX, MaxY, RootPosition, RootOnScreen, TopPosition, TopOnScreen
        end

        local ModelCFrame, ModelSize
        if Model:IsA("BasePart") then
            ModelCFrame = Model.CFrame
            ModelSize = Model.Size
        else
            ModelCFrame, ModelSize = Model:GetBoundingBox()
        end
        local HalfSize = ModelSize / 2
        for _, Sign in ModelCornerSigns do
            local Corner = ModelCFrame:PointToWorldSpace(Vector3.new(
                HalfSize.X * Sign.X,
                HalfSize.Y * Sign.Y,
                HalfSize.Z * Sign.Z
            ))
            local Position, IsOnScreen = Camera:WorldToViewportPoint(Corner)
            if IsOnScreen then
                OnScreen = true
                MinX = math.min(MinX, Position.X)
                MinY = math.min(MinY, Position.Y)
                MaxX = math.max(MaxX, Position.X)
                MaxY = math.max(MaxY, Position.Y)
            end
        end

        return OnScreen, MinX, MinY, MaxX, MaxY, RootPosition, RootOnScreen, TopPosition, TopOnScreen
    end

    local function HideTarget(Target)
        if Boxes[Target] then
            Boxes[Target].Visible = false
        end
        if Corners[Target] then
            for _, Line in next, Corners[Target] do
                Line.Visible = false
            end
        end
        if Names[Target] then
            Names[Target].Visible = false
        end
        if Tracers[Target] then
            Tracers[Target].Visible = false
        end
        if Quads[Target] then
            Quads[Target].Visible = false
        end
        if Healths[Target] then
            Healths[Target].Visible = false
        end
        if Distances[Target] then
            Distances[Target].Visible = false
        end
        if HealthBars[Target] then
            HealthBars[Target].Visible = false
        end
        if Box3DLines[Target] then
            for _, Line in next, Box3DLines[Target] do
                Line.Visible = false
            end
        end
        if SkeletonLines[Target] then
            for _, Line in next, SkeletonLines[Target] do
                Line.Visible = false
            end
        end
        if Chams[Target] then
            Chams[Target].Enabled = false
        end
    end

    local function CleanupTarget(Target)
        local Conns = Connections[Target]
        if Conns then
            for _, Conn in next, Conns do
                if Conn and Conn.Disconnect then
                    Conn:Disconnect()
                end
            end
        end
        Connections[Target] = nil

        local Storages = {
            Boxes, Names, Tracers, Quads, Healths, Distances,
            HealthBars, Corners, Box3DLines, SkeletonLines,
        }
        for _, Storage in next, Storages do
            local Obj = Storage[Target]
            if Obj then
                if typeof(Obj) == "table" then
                    for _, Item in next, Obj do
                        if Item and Item.Remove then
                            Item:Remove()
                        end
                    end
                else
                    if Obj and Obj.Remove then
                        Obj:Remove()
                    end
                end
            end
            Storage[Target] = nil
        end

        if Chams[Target] then
            Chams[Target]:Destroy()
            Chams[Target] = nil
        end

        TargetData[Target] = nil
        Tracked[Target] = nil
    end

    local function NewBox(Target)
        Boxes[Target] = CreateDrawing("Square", {
            Thickness = 2,
            Filled = false,
            Transparency = 0,
            Color = self.BoxColor,
            Visible = false,
        })
    end

    local function NewCorners(Target)
        local Lines = table.create(8)
        for i = 1, 8 do
            Lines[i] = CreateDrawing("Line", {
                Thickness = 2,
                Transparency = 0,
                Color = self.CornerColor,
                Visible = false,
            })
        end
        Corners[Target] = Lines
    end

    local function NewName(Target)
        Names[Target] = CreateDrawing("Text", {
            Size = 16,
            Center = true,
            Outline = true,
            Font = 2,
            Color = self.NameColor,
            Visible = false,
        })
    end

    local function NewTracer(Target)
        Tracers[Target] = CreateDrawing("Line", {
            Thickness = self.TracerThickness,
            Color = self.TracerColor,
            Visible = false,
        })
    end

    local function NewQuad(Target)
        Quads[Target] = CreateDrawing("Quad", {
            Color = self.QuadColor,
            Visible = false,
            Thickness = 1,
        })
    end

    local function NewHealth(Target)
        Healths[Target] = CreateDrawing("Text", {
            Size = 14,
            Center = true,
            Outline = true,
            Font = 2,
            Color = self.HealthTextColor,
            Visible = false,
        })
    end

    local function NewDistance(Target)
        Distances[Target] = CreateDrawing("Text", {
            Size = 14,
            Center = true,
            Outline = true,
            Font = 2,
            Color = self.DistanceColor,
            Visible = false,
        })
    end

    local function NewChams(Target)
        local Highlight = Instance.new("Highlight")
        Highlight.FillTransparency = 0.7
        Highlight.OutlineTransparency = 1
        Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        Highlight.Enabled = false
        Highlight.Parent = Parent
        Chams[Target] = Highlight
    end

    local function NewHealthBar(Target)
        HealthBars[Target] = CreateDrawing("Line", {
            Thickness = 3,
            Color = self.HealthBarColorOverride or Green,
            Visible = false,
        })
    end

    local function New3DBox(Target)
        local Lines = table.create(12)
        for i = 1, 12 do
            Lines[i] = CreateDrawing("Line", {
                Thickness = 1,
                Color = self.BoxColor,
                Visible = false,
            })
        end
        Box3DLines[Target] = Lines
    end

    local function NewSkeleton(Target)
        local Lines = table.create(15)
        for i = 1, 15 do
            Lines[i] = CreateDrawing("Line", {
                Thickness = 1,
                Color = self.BoxColor,
                Visible = false,
            })
        end
        SkeletonLines[Target] = Lines
    end

    local function TrackSource(Source, ContainerName, Definition)
        local Model, CustomName = NormalizeSource(Source)

        if typeof(Model) ~= "Instance" then
            return
        end
        if not (Model:IsA("Player") or Model:IsA("Model") or Model:IsA("BasePart")) then
            return
        end
        if Model == LocalPlayer and IsPlayerContainer() then
            return
        end

        local Data = TargetData[Model]
        if Data then
            Data.Owners[ContainerName] = true
            Data.Definition = Definition
            if CustomName then
                Data.Name = CustomName
            end
            Data.Anchor = ResolveTarget(Model, Definition.Target)
            return
        end

        Data = {
            Source = Model,
            Name = CustomName,
            Anchor = ResolveTarget(Model, Definition.Target),
            Definition = Definition,
            Owners = { [ContainerName] = true },
        }
        TargetData[Model] = Data
        Tracked[Model] = true

        NewBox(Model)
        NewCorners(Model)
        NewName(Model)
        NewTracer(Model)
        NewQuad(Model)
        NewHealth(Model)
        NewDistance(Model)
        NewChams(Model)
        NewHealthBar(Model)
        New3DBox(Model)
        NewSkeleton(Model)

        Connections[Model] = Connections[Model] or {}

        if Model:IsA("Player") and Model.CharacterRemoving then
            table.insert(Connections[Model], Model.CharacterRemoving:Connect(function()
                HideTarget(Model)
            end))
        end
    end

    local function UntrackSource(Source, ContainerName)
        local Data = TargetData[Source]
        if not Data then
            return
        end

        Data.Owners[ContainerName] = nil
        if next(Data.Owners) then
            return
        end
        CleanupTarget(Source)
    end

    local function SyncContainerSources(Name, Definition)
        local CurrentSources = {}
        for _, Source in next, GetSources(Name, Definition) do
            local Model = NormalizeSource(Source)
            if typeof(Model) == "Instance" then
                CurrentSources[Model] = true
                TrackSource(Source, Name, Definition)
            end
        end

        local PreviousSources = ContainerSources[Name]
        if PreviousSources then
            for Source in next, PreviousSources do
                if not CurrentSources[Source] then
                    UntrackSource(Source, Name)
                end
            end
        end
        ContainerSources[Name] = CurrentSources
    end

    local function DetachContainerListeners()
        for _, Conn in next, ContainerAddedConnections do
            Conn:Disconnect()
        end
        for _, Conn in next, ContainerRemovedConnections do
            Conn:Disconnect()
        end
        table.clear(ContainerAddedConnections)
        table.clear(ContainerRemovedConnections)
    end

    local function AttachContainerListeners()
        DetachContainerListeners()

        for Name, Definition in self.Containers do
            local Location = ResolveLocation(Name, Definition)
            if Location == Players then
                table.insert(ContainerAddedConnections, Players.PlayerAdded:Connect(function(Source)
                    TrackSource(Source, Name, Definition)
                end))
                table.insert(ContainerRemovedConnections, Players.PlayerRemoving:Connect(function(Target)
                    UntrackSource(Target, Name)
                end))
            elseif typeof(Definition.Location) ~= "function" and typeof(Location) == "Instance" then
                table.insert(ContainerAddedConnections, Location.ChildAdded:Connect(function(Source)
                    TrackSource(Source, Name, Definition)
                end))
                table.insert(ContainerRemovedConnections, Location.ChildRemoved:Connect(function(Source)
                    UntrackSource(Source, Name)
                end))
            end
        end
    end

    local function SeedFromContainers()
        for Name, Definition in self.Containers do
            SyncContainerSources(Name, Definition)
        end
    end

    local function RefreshDynamicContainers()
        for Name, Definition in self.Containers do
            if typeof(Definition.Location) == "function" then
                SyncContainerSources(Name, Definition)
            end
        end
    end

    local function CleanupTrackedTargets()
        while true do
            local Target = next(Tracked)
            if not Target then
                break
            end
            CleanupTarget(Target)
        end
    end

    local function ApplyContainers(Containers)
        CleanupTrackedTargets()

        local Normalized = {}
        for Name, Definition in next, Containers do
            if typeof(Definition) == "Instance" then
                Normalized[Name] = { Location = Definition }
            elseif typeof(Definition) == "table" then
                -- Prefer an explicit .Name on the definition (e.g. an entity's Class/type),
                -- otherwise register under the map key (the type from EntityList).
                local ContainerName = if typeof(Definition.Name) == "string"
                    and Definition.Name ~= "" then Definition.Name else Name
                Normalized[ContainerName] = Definition
            end
        end

        self.Containers = Normalized
        ContainerSources = {}
        local FirstName, FirstDefinition = next(Normalized)
        self.Container = FirstDefinition and ResolveLocation(FirstName, FirstDefinition) or nil

        SeedFromContainers()
        AttachContainerListeners()
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

    -- Public API
    -- Container definitions support Location (Instance, Instance list, or function),
    -- Target selectors such as "BasePart:Torso", and direct or nested setting overrides.
    -- A definition may set an explicit .Name; SetContainer registers it under that name,
    -- falling back to the map key (the type, e.g. an EntityList Class) when .Name is absent.

    function self:Enable()
        self.Active = true
    end

    function self:Disable()
        self.Active = false
        for Target in next, Tracked do
            HideTarget(Target)
        end
    end

    function self:SetContainer(Containers)
        ApplyContainers(Containers)
    end

    function self:RemoveContainer(Name)
        if self.Containers[Name] == nil then
            return
        end

        local Containers = {}
        for ContainerName, Container in self.Containers do
            if ContainerName ~= Name then
                Containers[ContainerName] = Container
            end
        end
        ApplyContainers(Containers)
    end

    function self:GetContainer(Name)
        return self.Containers[Name]
    end

    function self:GetContainers()
        return self.Containers
    end

    function self:SetBoxSize(WidthScale, HeightScale)
        if WidthScale then
            self.BoxWidthScale = WidthScale
        end
        if HeightScale then
            self.BoxHeightScale = HeightScale
        end
    end

    -- Whitelist of assignable properties (anything in this list can be set via SetProperty).
    local Assignable = {
        ShowBox = true,
        ShowCorners = true,
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
        CornerColor = true,
        NameColor = true,
        TracerColor = true,
        QuadColor = true,
        HealthTextColor = true,
        DistanceColor = true,
        ChamsColor = true,
        HealthBarColorOverride = true,
        TracerThickness = true,
        BoxWidthScale = true,
        BoxHeightScale = true,
    }

    function self:SetProperty(Name, Value)
        if Assignable[Name] then
            self[Name] = Value
        else
            warn(`[ESP] SetProperty: '{Name}' is not an assignable property`)
        end
    end

    function self:Clear()
        CleanupTrackedTargets()
        table.clear(Boxes)
        table.clear(Names)
        table.clear(Tracers)
        table.clear(Quads)
        table.clear(Healths)
        table.clear(Distances)
        table.clear(Chams)
        table.clear(HealthBars)
        table.clear(Corners)
        table.clear(Box3DLines)
        table.clear(SkeletonLines)
        table.clear(Tracked)
        table.clear(Connections)
        DetachContainerListeners()
        self.Active = false
    end

    -- Render loop
    RunService.RenderStepped:Connect(function()
        if not self.Active then
            return
        end

        RefreshDynamicContainers()

        FrameCount += 1
        if self.PerformanceMode and FrameCount % UpdateInterval ~= 0 then
            return
        end

        ViewportSize = Camera.ViewportSize
        local CameraPos = Camera.CFrame.Position

        for Target, Box in next, Boxes do
            if not Target or not Target.Parent then
                CleanupTarget(Target)
                continue
            end

            local Character, HRP, Head, Humanoid = GetParts(Target)
            if not Character or not HRP or not Head then
                HideTarget(Target)
                continue
            end

            local MaxDist = GetTargetSetting(Target, "MaxDist")
            local TeamColor = GetTargetSetting(Target, "TeamColor")
            local ShowBox = GetTargetSetting(Target, "ShowBox")
            local ShowCorners = GetTargetSetting(Target, "ShowCorners")
            local ShowName = GetTargetSetting(Target, "ShowName")
            local ShowHeld = GetTargetSetting(Target, "ShowHeld")
            local ShowTracer = GetTargetSetting(Target, "ShowTracer")
            local ShowQuad = GetTargetSetting(Target, "ShowQuad")
            local ShowHealth = GetTargetSetting(Target, "ShowHealth")
            local ShowDistance = GetTargetSetting(Target, "ShowDistance")
            local ShowChams = GetTargetSetting(Target, "ShowChams")
            local ShowHealthBar = GetTargetSetting(Target, "ShowHealthBar")
            local Show3DBox = GetTargetSetting(Target, "Show3DBox")
            local ShowSkeleton = GetTargetSetting(Target, "ShowSkeleton")
            local BoxColor = GetTargetSetting(Target, "BoxColor")
            local CornerColor = GetTargetSetting(Target, "CornerColor")
            local NameColor = GetTargetSetting(Target, "NameColor")
            local TracerColor = GetTargetSetting(Target, "TracerColor")
            local QuadColor = GetTargetSetting(Target, "QuadColor")
            local HealthTextColor = GetTargetSetting(Target, "HealthTextColor")
            local ChamsColor = GetTargetSetting(Target, "ChamsColor")
            local HealthBarColorOverride = GetTargetSetting(Target, "HealthBarColorOverride")
            local TracerThickness = GetTargetSetting(Target, "TracerThickness")
            local BoxWidthScale = GetTargetSetting(Target, "BoxWidthScale")
            local BoxHeightScale = GetTargetSetting(Target, "BoxHeightScale")

            local Dist = (CameraPos - HRP.Position).Magnitude

            if Dist > MaxDist then
                HideTarget(Target)
                continue
            end

            local ModelOnScreen, MinX, MinY, MaxX, MaxY, HRPPos, HRPOnScreen, HeadPos, HeadOnScreen = GetModelCorners(Character, HRP, Head, Humanoid ~= nil)

            local BaseCol = White
            if Target:IsA("Player") and TeamColor then
                if Target.Team == LocalPlayer.Team then
                    BaseCol = Target.TeamColor.Color
                else
                    BaseCol = Red
                end
            end
            if Humanoid and (Humanoid.Health <= 0 or Humanoid:GetState() == Enum.HumanoidStateType.Dead) then
                BaseCol = Gray
            end

            -- Box
            local Height, Width, BoxLeft, BoxTop
            if (ShowBox or ShowCorners) and ModelOnScreen then
                Height = math.abs(MaxY - MinY) * (BoxHeightScale or 1)
                Width = math.abs(MaxX - MinX) * ((BoxWidthScale or 0.6) / 0.6)
                BoxLeft = (MinX + MaxX) / 2 - Width / 2
                BoxTop = MinY

                if ShowBox then
                    Box.Size = Vector2.new(Width, Height)
                    Box.Position = Vector2.new(BoxLeft, BoxTop)
                    Box.Color = BoxColor or BaseCol
                    Box.Visible = true
                else
                    Box.Visible = false
                end
            else
                Box.Visible = false
            end

            -- Corners
            if ShowCorners and ModelOnScreen and Height and Width and BoxLeft and BoxTop then
                local C = Corners[Target]
                if C then
                    local X1, Y1 = BoxLeft, BoxTop
                    local X2, Y2 = BoxLeft + Width, BoxTop
                    local X3, Y3 = BoxLeft, BoxTop + Height
                    local X4, Y4 = BoxLeft + Width, BoxTop + Height

                    local CornerLen = math.max(3, Height * 0.2)
                    local Col = CornerColor or BaseCol

                    C[1].From = Vector2.new(X1, Y1 + CornerLen)
                    C[1].To = Vector2.new(X1, Y1)
                    C[1].Color = Col
                    C[1].Visible = true

                    C[2].From = Vector2.new(X1, Y1)
                    C[2].To = Vector2.new(X1 + CornerLen, Y1)
                    C[2].Color = Col
                    C[2].Visible = true

                    C[3].From = Vector2.new(X2, Y2 + CornerLen)
                    C[3].To = Vector2.new(X2, Y2)
                    C[3].Color = Col
                    C[3].Visible = true

                    C[4].From = Vector2.new(X2 - CornerLen, Y2)
                    C[4].To = Vector2.new(X2, Y2)
                    C[4].Color = Col
                    C[4].Visible = true

                    C[5].From = Vector2.new(X3, Y3 - CornerLen)
                    C[5].To = Vector2.new(X3, Y3)
                    C[5].Color = Col
                    C[5].Visible = true

                    C[6].From = Vector2.new(X3, Y3)
                    C[6].To = Vector2.new(X3 + CornerLen, Y3)
                    C[6].Color = Col
                    C[6].Visible = true

                    C[7].From = Vector2.new(X4, Y4 - CornerLen)
                    C[7].To = Vector2.new(X4, Y4)
                    C[7].Color = Col
                    C[7].Visible = true

                    C[8].From = Vector2.new(X4 - CornerLen, Y4)
                    C[8].To = Vector2.new(X4, Y4)
                    C[8].Color = Col
                    C[8].Visible = true
                end
            elseif Corners[Target] then
                for _, Line in next, Corners[Target] do
                    Line.Visible = false
                end
            end

            -- Name + Distance
            if (ShowName or ShowDistance) and HeadOnScreen then
                local NameText = ""
                local DistanceText = ""

                if ShowName then
                    NameText = GetTargetName(Target)
                    if ShowHeld and Target:IsA("Player") then
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

                local N = Names[Target]
                N.Position = Vector2.new(HeadPos.X, HeadPos.Y - 15)
                N.Text = Combined
                N.Color = NameColor or BaseCol
                N.Visible = true
            elseif Names[Target] then
                Names[Target].Visible = false
            end

            -- Tracer
            if ShowTracer and HRPOnScreen then
                local Tr = Tracers[Target]
                Tr.From = Vector2.new(ViewportSize.X / 2, ViewportSize.Y)
                Tr.To = Vector2.new(HRPPos.X, HRPPos.Y)
                Tr.Color = TracerColor or BaseCol
                Tr.Thickness = TracerThickness or 1
                Tr.Visible = true
            elseif Tracers[Target] then
                Tracers[Target].Visible = false
            end

            -- Quad
            if ShowQuad and HRPOnScreen and HeadOnScreen then
                local Q = Quads[Target]
                local HeightQ = math.abs(HRPPos.Y - HeadPos.Y)
                local WidthQ = HeightQ * 0.6
                local HalfWidth = WidthQ / 2

                Q.PointA = Vector2.new(HRPPos.X - HalfWidth, HeadPos.Y)
                Q.PointB = Vector2.new(HRPPos.X + HalfWidth, HeadPos.Y)
                Q.PointC = Vector2.new(HRPPos.X + HalfWidth, HRPPos.Y)
                Q.PointD = Vector2.new(HRPPos.X - HalfWidth, HRPPos.Y)
                Q.Color = QuadColor or BaseCol
                Q.Visible = true
            elseif Quads[Target] then
                Quads[Target].Visible = false
            end

            -- Health text
            if ShowHealth and Humanoid and HeadOnScreen then
                local HealthTxt = Healths[Target]
                local HealthText = `{math.floor(Humanoid.Health)}/{math.floor(Humanoid.MaxHealth)}`
                local HealthCol = HealthTextColor or GetColor(Humanoid.Health, Humanoid.MaxHealth)
                HealthTxt.Position = Vector2.new(HeadPos.X, HeadPos.Y + 5)
                HealthTxt.Text = HealthText
                HealthTxt.Color = HealthCol
                HealthTxt.Visible = true
            elseif Healths[Target] then
                Healths[Target].Visible = false
            end

            -- Health bar
            if ShowHealthBar and Humanoid and HRPOnScreen and HeadOnScreen then
                local Bar = HealthBars[Target]
                local HeightHB = math.abs(HRPPos.Y - HeadPos.Y)
                local WidthHB = HeightHB * 0.6
                local BoxLeftHB = HRPPos.X - WidthHB / 2
                local BoxTopHB = HeadPos.Y

                local MaxH = Humanoid.MaxHealth
                local HP = Humanoid.Health
                local HealthPct = if MaxH > 0 then HP / MaxH else 0
                local BarHeight = HeightHB * math.clamp(HealthPct, 0, 1)
                local BarColor = HealthBarColorOverride or GetColor(HP, MaxH)

                Bar.From = Vector2.new(BoxLeftHB - 6, BoxTopHB + HeightHB - BarHeight)
                Bar.To = Vector2.new(BoxLeftHB - 6, BoxTopHB + HeightHB)
                Bar.Color = BarColor
                Bar.Visible = true
            elseif HealthBars[Target] then
                HealthBars[Target].Visible = false
            end

            -- Chams
            if ShowChams then
                local Cham = Chams[Target]
                if Cham then
                    Cham.Adornee = Character
                    Cham.Enabled = true
                    Cham.FillColor = ChamsColor or BaseCol
                end
            elseif Chams[Target] then
                Chams[Target].Enabled = false
            end

            -- 3D box
            if Show3DBox and Box3DLines[Target] then
                local Lines = Box3DLines[Target]
                local Size = HRP.Size * 1.5
                local CF = HRP.CFrame

                local Points2D = table.create(8)
                local OnScreenAny = false

                for i = 1, 8 do
                    local Sign = Box3DCornerSigns[i]
                    local WorldPos = (CF * CFrame.new(
                        Sign.X * Size.X / 2,
                        Sign.Y * Size.Y / 2,
                        Sign.Z * Size.Z / 2
                    )).Position
                    local V2, OnScreen = Camera:WorldToViewportPoint(WorldPos)
                    Points2D[i] = { Vector2.new(V2.X, V2.Y), OnScreen }
                    if OnScreen then
                        OnScreenAny = true
                    end
                end

                if OnScreenAny then
                    local Col = BoxColor or BaseCol

                    local function SetLine(Idx, I1, I2)
                        local E1 = Points2D[I1]
                        local E2 = Points2D[I2]
                        local P1, O1 = E1[1], E1[2]
                        local P2, O2 = E2[1], E2[2]
                        local Line = Lines[Idx]
                        if O1 or O2 then
                            Line.From = P1
                            Line.To = P2
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
            elseif Box3DLines[Target] then
                for _, Line in next, Box3DLines[Target] do
                    Line.Visible = false
                end
            end

            -- Skeleton
            if ShowSkeleton and SkeletonLines[Target] then
                local Lines = SkeletonLines[Target]
                local Joints = GetJointPositions(Character)

                local function Proj(Name)
                    local Pos = Joints[Name]
                    if not Pos then
                        return nil, false
                    end
                    local V, OnScreen = Camera:WorldToViewportPoint(Pos)
                    return Vector2.new(V.X, V.Y), OnScreen
                end

                local Idx = 1
                local Col = BoxColor or BaseCol

                for _, Pair in next, SkeletonPairs do
                    local P1, O1 = Proj(Pair[1])
                    local P2, O2 = Proj(Pair[2])
                    local Line = Lines[Idx]
                    Idx += 1

                    if P1 and P2 and (O1 or O2) then
                        Line.From = P1
                        Line.To = P2
                        Line.Color = Col
                        Line.Visible = true
                    else
                        Line.Visible = false
                    end
                end

                for i = Idx, #Lines do
                    Lines[i].Visible = false
                end
            elseif SkeletonLines[Target] then
                for _, Line in next, SkeletonLines[Target] do
                    Line.Visible = false
                end
            end
        end
    end)

    -- Initial setup
    ApplyContainers({ Players = Players })

return self
