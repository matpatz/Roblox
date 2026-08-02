local cloneref = cloneref or function(X)
    return X
end

export type ContainerSelector = ("Players" | "Workspace") | Instance | { Instance }

export type ESP = {
    Active: boolean,
    MaxDist: number,
    Container: Instance?,
    Containers: { Instance },

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
    SetContainer: (self: ESP, Container: Instance?) -> (),
    SetContainers: (self: ESP, Containers: { Instance }) -> (),
    SelectContainer: (self: ESP, Selector: ContainerSelector) -> (),
    SetBoxSize: (self: ESP, WidthScale: number?, HeightScale: number?) -> (),
    SetProperty: (self: ESP, Name: string, Value: any) -> (),
}

local ESP = {}
ESP.__index = ESP

function ESP.new()
    local self = setmetatable({}, ESP)

    -- Services
    local Players = cloneref(game:GetService("Players"))
    local RunService = cloneref(game:GetService("RunService"))
    local CoreGui = cloneref(game:GetService("CoreGui"))
    local Workspace = cloneref(game:GetService("Workspace"))
    local Camera = Workspace.CurrentCamera
    local LocalPlayer = Players.LocalPlayer

    local Parent = Instance.new("Folder")
    Parent.Parent = CoreGui
    Parent.Name = tostring(math.random(1e9, 2e9))

    -- State
    self.Active = false
    self.MaxDist = 2000
    self.Container = Players
    self.Containers = { Players }

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

    local FrameCount = 0
    local UpdateInterval = 2
    local ViewportSize = Camera.ViewportSize

    local White = Color3.fromRGB(255, 255, 255)
    local Red = Color3.fromRGB(255, 0, 0)
    local Green = Color3.fromRGB(0, 255, 0)
    local Yellow = Color3.fromRGB(255, 255, 0)
    local Gray = Color3.fromRGB(128, 128, 128)

    local ContainerAddedConnections = {}
    local ContainerRemovedConnections = {}

    -- Helpers

    local function IsPlayerContainer()
        for _, C in self.Containers do
            if C == Players then
                return true
            end
        end
        return false
    end

    local function IsLocalTarget(Target)
        return IsPlayerContainer() and Target == LocalPlayer
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

    local function GetCharacterFromTarget(Target)
        if Target == Players then
            return nil
        end
        if Target:IsA("Player") then
            return Target.Character
        end
        if Target:IsA("Model") then
            return Target
        end
        return nil
    end

    local function GetParts(Target)
        local Character = GetCharacterFromTarget(Target)
        if not Character then
            return nil, nil, nil, nil
        end

        local HRP = Character:FindFirstChild("HumanoidRootPart")
        local Head = Character:FindFirstChild("Head")
            or Character:FindFirstChild("UpperTorso")
            or Character:FindFirstChild("Torso")
        local Humanoid = Character:FindFirstChildOfClass("Humanoid")

        if HRP and Head then
            return Character, HRP, Head, Humanoid
        end
        return nil, nil, nil, nil
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

        Tracked[Target] = nil
    end

    local function NewBox(Target)
        Boxes[Target] = CreateDrawing("Square", {
            Thickness = 2,
            Filled = false,
            Transparency = 1,
            Color = self.BoxColor,
            Visible = false,
        })
    end

    local function NewCorners(Target)
        local Lines = table.create(8)
        for i = 1, 8 do
            Lines[i] = CreateDrawing("Line", {
                Thickness = 2,
                Transparency = 1,
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

    local function TrackTarget(Target)
        if Tracked[Target] then
            return
        end
        if IsLocalTarget(Target) then
            return
        end

        Tracked[Target] = true

        NewBox(Target)
        NewCorners(Target)
        NewName(Target)
        NewTracer(Target)
        NewQuad(Target)
        NewHealth(Target)
        NewDistance(Target)
        NewChams(Target)
        NewHealthBar(Target)
        New3DBox(Target)
        NewSkeleton(Target)

        Connections[Target] = Connections[Target] or {}

        if Target:IsA("Player") and Target.CharacterRemoving then
            table.insert(Connections[Target], Target.CharacterRemoving:Connect(function()
                HideTarget(Target)
            end))
        end
    end

    local function UntrackTarget(Target)
        CleanupTarget(Target)
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

        for _, Container in self.Containers do
            if Container == Players then
                table.insert(ContainerAddedConnections, Players.PlayerAdded:Connect(TrackTarget))
                table.insert(ContainerRemovedConnections, Players.PlayerRemoving:Connect(UntrackTarget))
            elseif Container:IsA("Instance") then
                table.insert(ContainerAddedConnections, Container.ChildAdded:Connect(TrackTarget))
                table.insert(ContainerRemovedConnections, Container.ChildRemoved:Connect(UntrackTarget))
            end
        end
    end

    local function SeedFromContainers()
        for _, Container in self.Containers do
            if Container == Players then
                for _, Player in next, Players:GetPlayers() do
                    TrackTarget(Player)
                end
            elseif Container:IsA("Instance") then
                for _, Child in next, Container:GetChildren() do
                    TrackTarget(Child)
                end
            end
        end
    end

    local function ApplyContainers(Containers)
        for Target in next, Tracked do
            CleanupTarget(Target)
        end

        self.Containers = Containers
        self.Container = if #Containers > 0 then Containers[1] else nil

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

    function self:Enable()
        self.Active = true
    end

    function self:Disable()
        self.Active = false
        for Target in next, Tracked do
            HideTarget(Target)
        end
    end

    function self:SelectContainer(Selector)
        -- Normalize mixed input (strings + Instances) into Instance list
        local Mixed = if typeof(Selector) == "table" then Selector else { Selector }
        local Normalized = {}
        for _, Item in next, Mixed do
            if typeof(Item) == "string" then
                if Item == "Players" then
                    table.insert(Normalized, Players)
                elseif Item == "Workspace" then
                    table.insert(Normalized, workspace)
                end
            elseif typeof(Item) == "Instance" then
                table.insert(Normalized, Item)
            end
        end
        ApplyContainers(Normalized)
    end

    function self:SetContainer(Container)
        if Container == nil then
            Container = Players
        end
        ApplyContainers({ Container })
    end

    function self:SetContainers(Containers)
        ApplyContainers(Containers)
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
        for Target in next, Tracked do
            CleanupTarget(Target)
        end
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
        self.Active = false
    end

    -- Render loop
    RunService.RenderStepped:Connect(function()
        if not self.Active then
            return
        end

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

            local HRPPos, HRPOnScreen = Camera:WorldToViewportPoint(HRP.Position)
            local HeadPos, HeadOnScreen = Camera:WorldToViewportPoint(Head.Position)
            local Dist = (CameraPos - HRP.Position).Magnitude

            if Dist > self.MaxDist then
                HideTarget(Target)
                continue
            end

            local BaseCol = White
            if Target:IsA("Player") and self.TeamColor and Target.Team ~= LocalPlayer.Team then
                BaseCol = Red
            end
            if Humanoid and Humanoid.Health <= 0 then
                BaseCol = Gray
            end

            -- Box
            local Height, Width, BoxLeft, BoxTop
            if (self.ShowBox or self.ShowCorners) and HRPOnScreen and HeadOnScreen then
                Height = math.abs(HRPPos.Y - HeadPos.Y) * (self.BoxHeightScale or 1)
                Width = Height * (self.BoxWidthScale or 0.6)
                BoxLeft = HRPPos.X - Width / 2
                BoxTop = HeadPos.Y

                if self.ShowBox then
                    Box.Size = Vector2.new(Width, Height)
                    Box.Position = Vector2.new(BoxLeft, BoxTop)
                    Box.Color = self.BoxColor or BaseCol
                    Box.Visible = true
                else
                    Box.Visible = false
                end
            else
                Box.Visible = false
            end

            -- Corners
            if self.ShowCorners and HRPOnScreen and HeadOnScreen and Height and Width and BoxLeft and BoxTop then
                local C = Corners[Target]
                if C then
                    local X1, Y1 = BoxLeft, BoxTop
                    local X2, Y2 = BoxLeft + Width, BoxTop
                    local X3, Y3 = BoxLeft, BoxTop + Height
                    local X4, Y4 = BoxLeft + Width, BoxTop + Height

                    local CornerLen = math.max(3, Height * 0.2)
                    local Col = self.CornerColor or BaseCol

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
            if (self.ShowName or self.ShowDistance) and HeadOnScreen then
                local NameText = ""
                local DistanceText = ""

                if self.ShowName then
                    NameText = if typeof(Target) == "Instance" then Target.Name else "Target"
                    if self.ShowHeld and Target:IsA("Player") then
                        local Tool = Character:FindFirstChildOfClass("Tool")
                        if Tool then
                            NameText = `{NameText} [{Tool.Name}]`
                        end
                    end
                end

                if self.ShowDistance then
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
                N.Color = self.NameColor or BaseCol
                N.Visible = true
            elseif Names[Target] then
                Names[Target].Visible = false
            end

            -- Tracer
            if self.ShowTracer and HRPOnScreen then
                local Tr = Tracers[Target]
                Tr.From = Vector2.new(ViewportSize.X / 2, ViewportSize.Y)
                Tr.To = Vector2.new(HRPPos.X, HRPPos.Y)
                Tr.Color = self.TracerColor or BaseCol
                Tr.Thickness = self.TracerThickness or 1
                Tr.Visible = true
            elseif Tracers[Target] then
                Tracers[Target].Visible = false
            end

            -- Quad
            if self.ShowQuad and HRPOnScreen and HeadOnScreen then
                local Q = Quads[Target]
                local HeightQ = math.abs(HRPPos.Y - HeadPos.Y)
                local WidthQ = HeightQ * 0.6
                local HalfWidth = WidthQ / 2

                Q.PointA = Vector2.new(HRPPos.X - HalfWidth, HeadPos.Y)
                Q.PointB = Vector2.new(HRPPos.X + HalfWidth, HeadPos.Y)
                Q.PointC = Vector2.new(HRPPos.X + HalfWidth, HRPPos.Y)
                Q.PointD = Vector2.new(HRPPos.X - HalfWidth, HRPPos.Y)
                Q.Color = self.QuadColor or BaseCol
                Q.Visible = true
            elseif Quads[Target] then
                Quads[Target].Visible = false
            end

            -- Health text
            if self.ShowHealth and Humanoid and HeadOnScreen then
                local HealthTxt = Healths[Target]
                local HealthText = `{math.floor(Humanoid.Health)}/{math.floor(Humanoid.MaxHealth)}`
                local HealthCol = self.HealthTextColor or GetColor(Humanoid.Health, Humanoid.MaxHealth)
                HealthTxt.Position = Vector2.new(HeadPos.X, HeadPos.Y + 5)
                HealthTxt.Text = HealthText
                HealthTxt.Color = HealthCol
                HealthTxt.Visible = true
            elseif Healths[Target] then
                Healths[Target].Visible = false
            end

            -- Health bar
            if self.ShowHealthBar and Humanoid and HRPOnScreen and HeadOnScreen then
                local Bar = HealthBars[Target]
                local HeightHB = math.abs(HRPPos.Y - HeadPos.Y)
                local WidthHB = HeightHB * 0.6
                local BoxLeftHB = HRPPos.X - WidthHB / 2
                local BoxTopHB = HeadPos.Y

                local MaxH = Humanoid.MaxHealth
                local HP = Humanoid.Health
                local HealthPct = if MaxH > 0 then HP / MaxH else 0
                local BarHeight = HeightHB * math.clamp(HealthPct, 0, 1)
                local BarColor = self.HealthBarColorOverride or GetColor(HP, MaxH)

                Bar.From = Vector2.new(BoxLeftHB - 6, BoxTopHB + HeightHB - BarHeight)
                Bar.To = Vector2.new(BoxLeftHB - 6, BoxTopHB + HeightHB)
                Bar.Color = BarColor
                Bar.Visible = true
            elseif HealthBars[Target] then
                HealthBars[Target].Visible = false
            end

            -- Chams
            if self.ShowChams then
                local Cham = Chams[Target]
                if Cham then
                    Cham.Adornee = Character
                    Cham.Enabled = true
                    Cham.FillColor = self.ChamsColor or BaseCol
                end
            elseif Chams[Target] then
                Chams[Target].Enabled = false
            end

            -- 3D box
            if self.Show3DBox and Box3DLines[Target] then
                local Lines = Box3DLines[Target]
                local Size = HRP.Size * 1.5
                local CF = HRP.CFrame

                local Offsets = {
                    Vector3.new(-Size.X / 2,  Size.Y / 2, -Size.Z / 2),
                    Vector3.new( Size.X / 2,  Size.Y / 2, -Size.Z / 2),
                    Vector3.new( Size.X / 2,  Size.Y / 2,  Size.Z / 2),
                    Vector3.new(-Size.X / 2,  Size.Y / 2,  Size.Z / 2),
                    Vector3.new(-Size.X / 2, -Size.Y / 2, -Size.Z / 2),
                    Vector3.new( Size.X / 2, -Size.Y / 2, -Size.Z / 2),
                    Vector3.new( Size.X / 2, -Size.Y / 2,  Size.Z / 2),
                    Vector3.new(-Size.X / 2, -Size.Y / 2,  Size.Z / 2),
                }

                local Points2D = table.create(8)
                local OnScreenAny = false

                for i = 1, 8 do
                    local WorldPos = (CF * CFrame.new(Offsets[i])).Position
                    local V2, OnScreen = Camera:WorldToViewportPoint(WorldPos)
                    Points2D[i] = { Vector2.new(V2.X, V2.Y), OnScreen }
                    if OnScreen then
                        OnScreenAny = true
                    end
                end

                if OnScreenAny then
                    local Col = self.BoxColor or BaseCol

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
            if self.ShowSkeleton and SkeletonLines[Target] then
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

                local PairsDef = {
                    { "Head", "Torso" },
                    { "Torso", "LeftArm" },
                    { "Torso", "RightArm" },
                    { "Torso", "LeftLeg" },
                    { "Torso", "RightLeg" },
                }

                local Idx = 1
                local Col = self.BoxColor or BaseCol

                for _, Pair in next, PairsDef do
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
    ApplyContainers({ Players })

    return self
end

return ESP
