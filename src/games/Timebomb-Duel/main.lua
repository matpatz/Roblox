getgenv().PlayerHelper = true

local Services = loadstring(game:HttpGet(
    "https://roblox-alpha-murex.vercel.app/src/Modules/Variables.lua"
))()

local Game = Services.MarketplaceService:GetProductInfo(game.PlaceId).Name

local Rayfield = loadstring(game:HttpGet(
    "https://website-iota-ivory-12.vercel.app/code/loader/u/ui/rayfield.lua"
))()

local Player = Services.Player
local Players = Services.Players
local RunService = Services.RunService
local UserInputService = Services.UserInputService
local Workspace = workspace

local Window = Rayfield:CreateWindow({
    Name = Game,
    LoadingTitle = "Loading",
    LoadingSubtitle = "Teleport",
})

local Tabs = {
    Main = Window:CreateTab("Main", 4483362458),
    Settings = Window:CreateTab("Settings", 4483362458),
}

local Connections = {
    Gameplay = {},
}

local States = {
    Runtime = {},

    Values = {
        AutoTeleport = false,
        LastTarget = nil,
        Teleported = false,

        Communication = Instance.new("BindableEvent"),
    },
}

local function SetValue(Object, Key, Value)
    Object[Key] = Value

    States.Values.Communication:Fire({
        Object = Object,
        Key = Key,
        Value = Value,
    })
end

local function AddConnection(Category: table, Name: string, Connection: RBXScriptConnection | thread)
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
    States.Runtime[Name] = true
end

local function RemoveConnection(Category: table, Name: string)
    if not Category[Name] then
        return
    end

    pcall(function()
        if typeof(Category[Name]) == "RBXScriptConnection" then
            Category[Name]:Disconnect()
        else
            task.cancel(Category[Name])
        end
    end)

    Category[Name] = nil
    States.Runtime[Name] = false
end

local function GetCharacter()
    return Player.Character
end

local function GetRoot()
    local Character = GetCharacter()
    return Character and Character:FindFirstChild("HumanoidRootPart")
end

local function GetStatus(): string?
    return Player.Data:GetAttribute("Status")
end

local function GetClosestPlayer()
    local Character = GetCharacter()
    local Root = GetRoot()

    if not Character or not Root then
        return
    end

    local Status: string? = GetStatus()

    if Status ~= "InDuel" and Status ~= "InFFA" then
        return
    end

    local Closest
    local ClosestDistance = math.huge

    for _, Target in Players:GetPlayers() do
        if Target == Player then
            continue
        end

        local TargetCharacter = Target.Character
        if not TargetCharacter then
            continue
        end

        local TargetRoot = TargetCharacter:FindFirstChild("HumanoidRootPart")
        local Humanoid = TargetCharacter:FindFirstChildOfClass("Humanoid")

        if not TargetRoot or not Humanoid or Humanoid.Health <= 0 then
            continue
        end

        if TargetCharacter:FindFirstChild("Bomb") then
            continue
        end

        local TargetStatus: string? = Target:FindFirstChild("Data") and Target.Data:GetAttribute("Status")

        if TargetStatus ~= "InDuel" and TargetStatus ~= "InFFA" then
            continue
        end

        if Status == "InFFA" and Target == States.Values.LastTarget then
            continue
        end

        local ScreenPosition, Visible = Workspace.CurrentCamera:WorldToViewportPoint(TargetRoot.Position)

        if not Visible then
            continue
        end

        if (TargetRoot.Position - Root.Position).Magnitude > 60 then
            continue
        end

        local Delta = Vector2.new(ScreenPosition.X, ScreenPosition.Y) - UserInputService:GetMouseLocation()
        local Distance = Delta.X * Delta.X + Delta.Y * Delta.Y

        if Distance >= ClosestDistance then
            continue
        end

        ClosestDistance = Distance
        Closest = Target
    end

    return Closest
end

local function Teleport()
    local Character = GetCharacter()
    local Root = GetRoot()

    if not Character or not Root then
        return
    end

    local Status: string? = GetStatus()

    if Status ~= "InDuel" and Status ~= "InFFA" then
        return
    end

    if not Character:FindFirstChildWhichIsA("Tool") then
        if not States.Values.Teleported then
            Root.CFrame *= CFrame.new(0, 12, 0)
            SetValue(States.Values, "Teleported", true)
        end

        return
    end

    local Closest = GetClosestPlayer()

    if not Closest or not Closest.Character then
        SetValue(States.Values, "Teleported", false)
        return
    end

    local TargetRoot = Closest.Character:FindFirstChild("HumanoidRootPart")

    if not TargetRoot then
        SetValue(States.Values, "Teleported", false)
        return
    end

    Root.CFrame = TargetRoot.CFrame

    SetValue(States.Values, "LastTarget", Closest)
    SetValue(States.Values, "Teleported", false)
end

Tabs.Main:CreateButton({
    Name = "Teleport",
    Callback = function()
        Teleport()
    end,
})

Tabs.Main:CreateToggle({
    Name = "Auto Teleport",
    CurrentValue = false,
    Callback = function(Value)
        SetValue(States.Values, "AutoTeleport", Value)

        if Value then
            AddConnection(Connections.Gameplay, "AutoTeleport", RunService.RenderStepped:Connect(Teleport))
        else
            RemoveConnection(Connections.Gameplay, "AutoTeleport")
        end
    end,
})

Tabs.Settings:CreateLabel("Settings")

Rayfield:Notify({
    Title = Game,
    Content = "Loaded!",
    Duration = 5,
    Image = 4483362458,
})