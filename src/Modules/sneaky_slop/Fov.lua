-- vendored from https://sneekysscripts.uk/Scripts/FOV_LIBRARY/main.luau
-- perf: no redundant per-frame property writes, hoisted UIStroke lookup, 128-side circle,
--       camera read once per frame (respawn-safe), visibility only written on change.

local cloneref = cloneref or function(i: Instance) return i; end;

local RS: RunService = cloneref(game:GetService("RunService"));
local UIS: UserInputService = cloneref(game:GetService("UserInputService"));
local _ = cloneref(game:GetService("CoreGui"));
local hui = _:FindFirstChild("RobloxGui") or _;
if gethui then local s, r = pcall(gethui); if s then hui = cloneref(r); end; end;

local SIDES: number = 128;

local code = function(n: string): string
    if crypt and crypt.base64encode then
        return crypt.base64encode(n);
    end;
    return n;
end;

local DrawLib = {};
DrawLib.__index = DrawLib;

function DrawLib.new(sFOV: number, tFunc: (origin: Vector3?) -> (Model | BasePart)?, mCenter: boolean?)
    local self = setmetatable({}, DrawLib);
    self.size = sFOV;
    self.func = tFunc;
    self.on = false;
    self.center = mCenter and (UIS.TouchEnabled and not UIS.KeyboardEnabled and not UIS.MouseEnabled);

    local Stroke: UIStroke?;

    if DrawingImmediate then
        self.signal = DrawingImmediate.GetPaint(1);
    elseif Drawing and cleardrawcache then
        self.fov = Drawing.new("Circle");
        self.fov.Color = Color3.new(1, 0, 0);
        self.fov.Radius = self.size;
        self.fov.Thickness = 1;
        self.fov.Transparency = 1;
        self.fov.Filled = false;
        -- self.fov.NumSides = SIDES;
        self.fov.Visible = false;

        self.line = Drawing.new("Line");
        self.line.Thickness = 2;
        self.line.Color = Color3.new(1, 0, 0);
        self.line.Transparency = 0.5;
        self.line.Visible = false;
    else
        self.p = Instance.new("ScreenGui", hui);
        self.p.Name = code(self.p:GetDebugId());

        do
            self.fov = Instance.new("Frame", self.p);
            self.fov.Name = code(self.p:GetDebugId());
            self.fov.AnchorPoint = Vector2.new(0.5, 0.5);
            self.fov.Size = UDim2.new(0, self.size*2, 0, self.size*2);
            self.fov.Position = UDim2.new(0, 0);
            self.fov.BackgroundTransparency = 1;
            self.fov.Visible = false;

            local FovCorner = Instance.new("UICorner", self.fov);
            FovCorner.Name = code(FovCorner:GetDebugId());
            FovCorner.CornerRadius = UDim.new(1, 0);

            local FovStroke = Instance.new("UIStroke", self.fov);
            FovStroke.Name = code(FovStroke:GetDebugId());
            FovStroke.Color = Color3.new(1, 0, 0);
            FovStroke.Thickness = 1;
            FovStroke.LineJoinMode = Enum.LineJoinMode.Round;
            FovStroke.Transparency = 0;

            Stroke = FovStroke;
        end;

        do
            self.line = Instance.new("Frame", self.p);
            self.line.Name = code(self.line:GetDebugId());
            self.line.AnchorPoint = Vector2.new(0.5, 0.5);
            self.line.Size = UDim2.new(0, 0);
            self.line.Position = UDim2.new(0, 0);
            self.line.BackgroundTransparency = 0.5;
            self.line.Visible = false;

            local LineStroke = Instance.new("UIStroke", self.line);
            LineStroke.Name = code(LineStroke:GetDebugId());
            LineStroke.Color = Color3.new(1, 0, 0);
            LineStroke.Thickness = 1;
            LineStroke.LineJoinMode = Enum.LineJoinMode.Round;
            LineStroke.Transparency = 0.5;
        end;
    end;

    local LastPosition: Vector2?;
    local LastSize: number?;
    local LastFovVisible: boolean?;
    local LastLineVisible: boolean?;

    local SetFovVisible = function(Value: boolean)
        if LastFovVisible == Value then return; end;
        LastFovVisible = Value;
        if self.fov then self.fov.Visible = Value; end;
    end;

    local SetLineVisible = function(Value: boolean)
        if LastLineVisible == Value then return; end;
        LastLineVisible = Value;
        if self.line then self.line.Visible = Value; end;
    end;

    local cSet = function(isGreen: boolean)
        local Color = isGreen and Color3.new(0, 1, 0) or Color3.new(1, 0, 0);

        if Stroke then
            Stroke.Color = Color;
            return;
        end;

        if self.signal then
            return Color;
        end;

        self.fov.Color = Color;
        return;
    end;

    local UpdateFov = function(Position: Vector2)
        if not self.fov then return; end;

        if self.p then
            if LastPosition ~= Position then
                LastPosition = Position;
                self.fov.Position = UDim2.new(0, Position.X, 0, Position.Y);
            end;
            if LastSize ~= self.size then
                LastSize = self.size;
                self.fov.Size = UDim2.new(0, self.size*2, 0, self.size*2);
            end;
        else
            if LastPosition ~= Position then
                LastPosition = Position;
                self.fov.Position = Position;
            end;
            if LastSize ~= self.size then
                LastSize = self.size;
                self.fov.Radius = self.size;
            end;
        end;

        SetFovVisible(true);
    end;

    self.connection = self.signal and (self.signal::RBXScriptSignal):Connect(function()
        if not self.on then return; end;

        local camera = workspace.CurrentCamera;
        local Position = self.center and Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2) or UIS:GetMouseLocation();
        local Target = self.func(camera.CFrame.Position);
        local Found = false;

        if Target then
            local ScreenPosition, OnScreen = camera:WorldToViewportPoint(Target:IsA("Model") and Target:GetPivot().Position or Target.Position);
            if OnScreen then
                DrawingImmediate.Line(Position, Vector2.new(ScreenPosition.X, ScreenPosition.Y), Color3.new(1, 0, 0), 1, 2);
                Found = true;
            end;
        end;

        DrawingImmediate.Circle(Position, self.size, cSet(Found), 1, SIDES, 1);
    end) or RS.RenderStepped:Connect(function()
        if not self.on then
            SetFovVisible(false);
            SetLineVisible(false);
            cSet(false);
            return;
        end;

        local camera = workspace.CurrentCamera;
        local Position = self.center and Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2) or UIS:GetMouseLocation();

        UpdateFov(Position);

        local Target = self.func(camera.CFrame.Position);
        if Target then
            local ScreenPosition, OnScreen = camera:WorldToViewportPoint(Target:IsA("Model") and Target:GetPivot().Position or Target.Position);
            if OnScreen then
                local ScreenPoint = Vector2.new(ScreenPosition.X, ScreenPosition.Y);

                if self.p then
                    local Midpoint = (Position + ScreenPoint) / 2;
                    local Length = (Position - ScreenPoint).Magnitude;
                    local Angle = math.atan2(ScreenPoint.Y - Position.Y, ScreenPoint.X - Position.X);

                    self.line.Position = UDim2.fromOffset(Midpoint.X, Midpoint.Y);
                    self.line.Size = UDim2.fromOffset(Length, 0);
                    self.line.Rotation = math.deg(Angle);
                else
                    self.line.From = Position;
                    self.line.To = ScreenPoint;
                end;

                SetLineVisible(true);
                cSet(true);
                return;
            end;
        end;

        SetLineVisible(false);
        cSet(false);
    end);

    return self;
end;

function DrawLib:set(sFOV: number)
    self.size = sFOV;
end;

function DrawLib:start()
    self.on = true;
end;

function DrawLib:stop()
    self.on = false;
end;

function DrawLib:terminate()
    self.on = nil;
    if self.connection then self.connection:Disconnect(); self.connection = nil; end;
    if self.p then
        self.p:Destroy();
        self.p = nil;
        if self.fov then self.fov:Destroy(); self.fov = nil; end;
        if self.line then self.line:Destroy(); self.line = nil; end;
    elseif self.signal then
        self.signal = nil;
    else
        cleardrawcache();
    end;
end;

return DrawLib;
