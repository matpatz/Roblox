getgenv().PlayerHelper = true

local Services = loadstring(game:HttpGet(
    "https://website-iota-ivory-12.vercel.app/code/Modules/Services.lua"
))()

local Game = Services["MarketplaceService"]:GetProductInfo(game.PlaceId).Name

local Rayfield = loadstring(game:HttpGet(
    "https://website-iota-ivory-12.vercel.app/code/loader/u/ui/rayfield.lua"
))()

local Player = Services["Player"]
local Workspace = Services["Workspace"]
local ReplicatedStorage = Services["ReplicatedStorage"]

local Window = Rayfield:CreateWindow({
    Name = Game,
    LoadingTitle = "fahhhh",
    LoadingSubtitle = "subtitle",
})

local Tabs = {
    Autofarm = Window:CreateTab("Autofarm", 4483362458),
    Map = Window:CreateTab("Map", 4483362458),
    Funds = Window:CreateTab("Funds", 4483362458),
    Misc = Window:CreateTab("Misc", 4483362458),
}

local Connections = {
    Autofarm = {},
    Map = {},
    Funds = {},
    Misc = {},
}

local States = {
    Runtime = {},

    Values = {
        AutoCollectCoins = false,
        AutoRadioactiveSpin = false,
        SpinDelay = 2,
        AutoCollectCash = false,
        AutoUpgradeSpeed = false,
        SpeedUpgradeAmount = 1,
        SpeedThreshold = 100,
        AutoUpgradeCarry = false,
        AutoRebirth = false,
        GravityEnabled = false,
        GravityValue = 100,
        Noclip = false,
        DoubleSpeed = false,
        Walkspeed = false,
        WalkspeedValue = 100,
        ToolHitbox = false,
        ToolSize = 100,

        Communication = Instance.new("BindableEvent"),
    },
}

local OriginalGravity = Workspace.Gravity
local OriginalToolSize = Vector3.new(1, 1, 3)
local OriginalSpeed = nil
local PlatformTarget = nil
local PlatformOriginalSize = nil
local CurrentTool = nil

local function SetValue(Obj: table, Key: string, Value: any)
    Obj[Key] = Value
    States.Values.Communication:Fire({
        Object = Obj,
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
    if not Category[Name] then return end

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

local Plot
for _, Base in ipairs(Workspace.Bases:GetChildren()) do
    if Base:GetAttribute("Holder") == Player.UserId then
        Plot = Base
        break
    end
end

local SteppingStones = {}
for _, Gap in ipairs(Workspace.SummerMap:GetChildren()) do
    if not Gap.Name:find("Gap") then continue end
    local Count = 0
    for _, Child in ipairs(Gap:GetChildren()) do
        if Child.Name == "Mud" then
            Count += 1
            if Count == 3 then
                table.insert(SteppingStones, Child)
                break
            end
        end
    end
end

local function FindNearestMud(Position: Vector3, Ignore: Instance?, CurrentDistance: number, TargetPosition: Vector3): Instance?
    local Best, Dist = nil, math.huge
    for _, Mud in ipairs(SteppingStones) do
        if Mud ~= Ignore then
            local Distance = (Mud.Position - Position).Magnitude
            local TargetDistance = (Mud.Position - TargetPosition).Magnitude
            if TargetDistance < CurrentDistance and Distance < Dist then
                Best, Dist = Mud, Distance
            end
        end
    end
    return Best
end

local function TweenTo(TargetPosition: Vector3)
    local HumanoidRootPart = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if not HumanoidRootPart then return end

    local Current = FindNearestMud(HumanoidRootPart.Position, nil, math.huge, TargetPosition)
    if not Current then return end

    HumanoidRootPart.CFrame = Current.CFrame
    task.wait(0.15)

    local Hops = 0
    while true do
        Hops += 1
        if Hops > 10 then break end

        local CurrentDistance = (Current.Position - TargetPosition).Magnitude
        if CurrentDistance <= 15 then break end

        local NextMud = FindNearestMud(Current.Position, Current, CurrentDistance, TargetPosition)
        if not NextMud then break end

        Current = NextMud
        HumanoidRootPart.CFrame = Current.CFrame
        task.wait(2.4)
    end
end

Tabs.Autofarm:CreateSection("Brainrots")

if firetouchinterest then
    Tabs.Autofarm:CreateSection("Radioactive")
    local CoinQueue = {}

    Tabs.Autofarm:CreateToggle({
        Name = "Auto Collect Coins",
        CurrentValue = false,
        Flag = "AutoCollectCoins",
        Callback = function(Value: boolean)
            SetValue(States.Values, "AutoCollectCoins", Value)
            if Value then
                CoinQueue = {}
                AddConnection(Connections.Autofarm, "CoinChildAdded", Workspace.EventParts.ChildAdded:Connect(function(Item)
                    table.insert(CoinQueue, Item)
                end))

                for _, Item in ipairs(Workspace.EventParts:GetChildren()) do
                    table.insert(CoinQueue, Item)
                end

                AddConnection(Connections.Autofarm, "CoinCollector", task.spawn(function()
                    while States.Values.AutoCollectCoins do
                        for _, Item in ipairs(CoinQueue) do
                            local Coin = Item:FindFirstChild("Radioactive Coin")
                            local Hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                            if Coin and Hrp then
                                firetouchinterest(Hrp, Coin, 0)
                                firetouchinterest(Hrp, Coin, 1)
                            end
                        end
                        task.wait(0.2)
                    end
                end))
            else
                RemoveConnection(Connections.Autofarm, "CoinChildAdded")
                RemoveConnection(Connections.Autofarm, "CoinCollector")
            end
        end,
    })
end

Tabs.Autofarm:CreateToggle({
    Name = "Auto Radioactive Spin",
    CurrentValue = false,
    Flag = "AutoRadioactiveSpin",
    Callback = function(Value: boolean)
        SetValue(States.Values, "AutoRadioactiveSpin", Value)
        if Value then
            AddConnection(Connections.Autofarm, "SpinThread", task.spawn(function()
                while States.Values.AutoRadioactiveSpin do
                    ReplicatedStorage.Packages.Net["RF/WheelSpin.Roll"]:InvokeServer()
                    task.wait(States.Values.SpinDelay)
                end
            end))
        else
            RemoveConnection(Connections.Autofarm, "SpinThread")
        end
    end,
})

Tabs.Autofarm:CreateSlider({
    Name = "Auto Radioactive Spin Delay",
    Range = {0.2, 20},
    Increment = 1,
    Suffix = " Speed",
    CurrentValue = 2,
    Flag = "SpinDelay",
    Callback = function(Value: number)
        SetValue(States.Values, "SpinDelay", Value)
    end,
})

Tabs.Map:CreateSection("Teleports")

Tabs.Map:CreateButton({
    Name = "Teleport Home",
    Callback = function()
        local Home = Plot and Plot:FindFirstChild("Home")
        if Home then
            TweenTo(Home.Position)
        end
    end,
})

Tabs.Map:CreateSection("Wave (fake)")

Tabs.Map:CreateToggle({
    Name = "Remove Waves",
    CurrentValue = false,
    Flag = "RemoveWaves",
    Callback = function(Value: boolean)
        if Value then
            AddConnection(Connections.Map, "WaveRemover", Workspace.ActiveTsunamis.ChildAdded:Connect(function(Item)
                if Item:IsA("Model") then
                    Item:Destroy()
                end
            end))
        else
            RemoveConnection(Connections.Map, "WaveRemover")
        end
    end,
})

Tabs.Map:CreateButton({
    Name = "Clear Current",
    Callback = function()
        for _, Item in ipairs(Workspace.ActiveTsunamis:GetChildren()) do
            if Item:IsA("Model") then
                Item:Destroy()
            end
        end
    end,
})

Tabs.Funds:CreateSection("Earn")

local Slots = {}
if Plot and Plot:FindFirstChild("Slots") then
    for _, Item in ipairs(Plot.Slots:GetChildren()) do
        if Item:IsA("Model") and Item.Name:find("Slot") then
            table.insert(Slots, Item)
        end
    end
end

Tabs.Funds:CreateToggle({
    Name = "Auto Collect Cash",
    CurrentValue = false,
    Flag = "AutoCollectCash",
    Callback = function(Value: boolean)
        SetValue(States.Values, "AutoCollectCash", Value)
        if Value then
            AddConnection(Connections.Funds, "CashCollector", task.spawn(function()
                while States.Values.AutoCollectCash do
                    task.wait(6)
                    for _, Item in ipairs(Slots) do
                        if Item and Item.Parent then
                            local Package = {
                                "Collect Money",
                                tostring(Plot),
                                tostring(Item):match("%d+"),
                            }
                            pcall(function()
                                ReplicatedStorage.Packages.Net["RF/Plot.PlotAction"]:InvokeServer(table.unpack(Package))
                            end)
                        end
                    end
                end
            end))
        else
            RemoveConnection(Connections.Funds, "CashCollector")
        end
    end,
})

Tabs.Funds:CreateSection("Upgrades")

Tabs.Funds:CreateDropdown({
    Name = "Speed Upgrade",
    Options = {1, 5, 10},
    CurrentOption = {1},
    MultipleOptions = false,
    Flag = "SpeedUpgradeAmount",
    Callback = function(Option: {any})
        SetValue(States.Values, "SpeedUpgradeAmount", Option[1])
    end,
})

Tabs.Funds:CreateToggle({
    Name = "Auto Upgrade Speed until threshold",
    CurrentValue = false,
    Flag = "AutoUpgradeSpeed",
    Callback = function(Value: boolean)
        SetValue(States.Values, "AutoUpgradeSpeed", Value)
        if Value then
            AddConnection(Connections.Funds, "SpeedUpgrader", task.spawn(function()
                while States.Values.AutoUpgradeSpeed do
                    task.wait(0.2)
                    local Current = Player:GetAttribute("CurrentSpeed")
                    if not Current then break end
                    if Current >= States.Values.SpeedThreshold then
                        RemoveConnection(Connections.Funds, "SpeedUpgrader")
                        break
                    end
                    ReplicatedStorage.RemoteFunctions.UpgradeSpeed:InvokeServer(States.Values.SpeedUpgradeAmount)
                end
            end))
        else
            RemoveConnection(Connections.Funds, "SpeedUpgrader")
        end
    end,
})

Tabs.Funds:CreateSlider({
    Name = "Speed Stop Threshold",
    Range = {18, 1e4},
    Increment = 1,
    Suffix = " Speed",
    CurrentValue = 100,
    Flag = "SpeedThreshold",
    Callback = function(Value: number)
        SetValue(States.Values, "SpeedThreshold", Value)
    end,
})

Tabs.Funds:CreateToggle({
    Name = "Auto Upgrade Carry",
    CurrentValue = false,
    Flag = "AutoUpgradeCarry",
    Callback = function(Value: boolean)
        SetValue(States.Values, "AutoUpgradeCarry", Value)
        if Value then
            AddConnection(Connections.Funds, "CarryUpgrader", task.spawn(function()
                while States.Values.AutoUpgradeCarry do
                    task.wait(8)
                    local MaxCarry = Player:GetAttribute("MaxCarry")
                    if MaxCarry ~= 6 then
                        ReplicatedStorage.RemoteFunctions.UpgradeCarry:InvokeServer()
                    end
                end
            end))
        else
            RemoveConnection(Connections.Funds, "CarryUpgrader")
        end
    end,
})

Tabs.Funds:CreateToggle({
    Name = "Auto Rebirth when possible",
    CurrentValue = false,
    Flag = "AutoRebirth",
    Callback = function(Value: boolean)
        SetValue(States.Values, "AutoRebirth", Value)
        if Value then
            AddConnection(Connections.Funds, "RebirthThread", task.spawn(function()
                while States.Values.AutoRebirth do
                    task.wait(4)
                    ReplicatedStorage.RemoteFunctions.Rebirth:InvokeServer()
                end
            end))
        else
            RemoveConnection(Connections.Funds, "RebirthThread")
        end
    end,
})

Tabs.Misc:CreateSection("Misc")

Tabs.Misc:CreateToggle({
    Name = "Gravity",
    CurrentValue = false,
    Flag = "GravityEnabled",
    Callback = function(Value: boolean)
        SetValue(States.Values, "GravityEnabled", Value)
        Workspace.Gravity = Value and States.Values.GravityValue or OriginalGravity
    end,
})

Tabs.Misc:CreateSlider({
    Name = "Set Gravity",
    Range = {0, 650},
    Increment = 1,
    Suffix = "g",
    CurrentValue = 100,
    Flag = "GravityValue",
    Callback = function(Value: number)
        SetValue(States.Values, "GravityValue", Value)
        if States.Values.GravityEnabled then
            Workspace.Gravity = Value
        end
    end,
})

Tabs.Misc:CreateToggle({
    Name = "Create a platform below the map",
    CurrentValue = false,
    Flag = "PlatformBelow",
    Callback = function(Value: boolean)
        if Value then
            if not PlatformTarget then
                for _, Item in ipairs(Workspace.Misc.Gaps:GetChildren()) do
                    if Item.ClassName == "Model" then
                        local Mud = Item:FindFirstChild("Mud")
                        if Mud then
                            PlatformTarget = Mud
                            PlatformOriginalSize = Mud.Size
                            Mud.Size = Vector3.new(6.05, 260, 1e5)
                            break
                        end
                    end
                end
            end
        elseif PlatformTarget and PlatformOriginalSize then
            PlatformTarget.Size = PlatformOriginalSize
        end
    end,
})

Tabs.Misc:CreateSection("Movement")

Tabs.Misc:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Flag = "Noclip",
    Callback = function(Value: boolean)
        SetValue(States.Values, "Noclip", Value)
        if Value then
            AddConnection(Connections.Misc, "NoclipThread", task.spawn(function()
                while States.Values.Noclip do
                    local Character = Player.Character
                    if Character then
                        for _, Part in ipairs(Character:GetDescendants()) do
                            if Part:IsA("BasePart") then
                                Part.CanCollide = false
                            end
                        end
                    end
                    task.wait()
                end
            end))
        else
            RemoveConnection(Connections.Misc, "NoclipThread")
            local Character = Player.Character
            if Character then
                for _, Part in ipairs(Character:GetDescendants()) do
                    if Part:IsA("BasePart") then
                        Part.CanCollide = true
                    end
                end
            end
        end
    end,
})

Tabs.Misc:CreateToggle({
    Name = "Double Speed",
    CurrentValue = false,
    Flag = "DoubleSpeed",
    Callback = function(Value: boolean)
        SetValue(States.Values, "DoubleSpeed", Value)
        Player:SetAttribute("HasDoubleSpeed", Value)
    end,
})

Tabs.Misc:CreateToggle({
    Name = "Walkspeed",
    CurrentValue = false,
    Flag = "Walkspeed",
    Callback = function(Value: boolean)
        SetValue(States.Values, "Walkspeed", Value)
        if Value then
            OriginalSpeed = Player:GetAttribute("CurrentSpeed")
            Player:SetAttribute("CurrentSpeed", States.Values.WalkspeedValue)
        else
            Player:SetAttribute("CurrentSpeed", OriginalSpeed)
        end
    end,
})

Tabs.Misc:CreateSlider({
    Name = "Set Speed",
    Range = {18, 1000},
    Increment = 1,
    Suffix = " Speed",
    CurrentValue = 100,
    Flag = "WalkspeedValue",
    Callback = function(Value: number)
        SetValue(States.Values, "WalkspeedValue", Value)
    end,
})

Tabs.Misc:CreateSection("Tool")

Tabs.Misc:CreateToggle({
    Name = "Update hitbox",
    CurrentValue = false,
    Flag = "ToolHitbox",
    Callback = function(Value: boolean)
        SetValue(States.Values, "ToolHitbox", Value)
        local Tool = Player.Character and Player.Character:FindFirstChildWhichIsA("Tool")
        local Hitbox = Tool and Tool:FindFirstChild("Hitbox")
        if not Hitbox then return end
        CurrentTool = Hitbox
        if Value then
            OriginalToolSize = Hitbox.Size
            Hitbox.Size = Vector3.new(States.Values.ToolSize, States.Values.ToolSize, States.Values.ToolSize)
        else
            Hitbox.Size = OriginalToolSize
        end
    end,
})

Tabs.Misc:CreateSlider({
    Name = "Set Tool Size",
    Range = {18, 200},
    Increment = 1,
    Suffix = " s",
    CurrentValue = 100,
    Flag = "ToolSize",
    Callback = function(Value: number)
        SetValue(States.Values, "ToolSize", Value)
        if States.Values.ToolHitbox and CurrentTool then
            CurrentTool.Size = Vector3.new(Value, Value, Value)
        end
    end,
})

Rayfield:Notify({
    Title = Game,
    Content = "Successfully Loaded!",
    Duration = 5,
    Image = 4483362458,
})
