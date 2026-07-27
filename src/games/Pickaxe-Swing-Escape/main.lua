local Services = loadstring(game:HttpGet(
    "https://roblox-alpha-murex.vercel.app/src/Modules/Variables.lua"
))()

local Game = Services["MarketplaceService"]:GetProductInfo(game.PlaceId).Name

local Rayfield = loadstring(game:HttpGet(
    "https://website-iota-ivory-12.vercel.app/code/loader/u/ui/rayfield.lua"
))()

local player = Services["Players"].LocalPlayer
	-- we can only do this because of PlayerHelper
local ReplicatedStorage = Services["ReplicatedStorage"]
local HttpService = Services["HttpService"]
	-- ALWAYS use Services, unless told not too, or its workspace--dont use it on workspace

local TweenService = Services["TweenService"]
local RunService = Services["RunService"]

local Window = Rayfield:CreateWindow({
    Name = Game,
    LoadingTitle = "fah you",
    LoadingSubtitle = "subtitle",
})

local tabs = {
    main = Window:CreateTab("Main", 4483362458),
    settings = Window:CreateTab("Settings", 4483362458),
		-- all scripts need atleast 2 tabs, because Rayfield breaks without. The second tab does not need to contain anything
}

local connections = {
    communication = {},
    table = {},
    gameplay = {},
}

local states = {
    runtime = {},

    values = {
        World,

        communication = Instance.new("BindableEvent"),
    },
}

local CurrentWorld = player:GetAttribute("CurrentWorld")
states.values.World = workspace.Worlds:FindFirstChild("World" .. CurrentWorld)
    -- World1, 2, idk

local function SetValue(obj, key, value)
    obj[key] = value
    states.values.communication:Fire({
        Object = obj,
        Key = key,
        Value = value,
    })
end

local function addConnection(category: table, name: string, connection: RBXScriptConnection)
    if category[name] then
        pcall(function()
            if typeof(category[name]) == "RBXScriptConnection" then
                category[name]:Disconnect()
            else
                task.cancel(category[name])
            end
        end)
    end

    category[name] = connection
    states.runtime[name] = true
end

local function removeConnection(category: table, name: string)
    if not category[name] then return end

    pcall(function()
        if typeof(category[name]) == "RBXScriptConnection" then
            category[name]:Disconnect()
        else
            task.cancel(category[name])
        end
    end)

    category[name] = nil
    states.runtime[name] = false
end

tabs.main:CreateLabel("Auto Farm")

local WinPads = states.values.World.DefaultWinPads
local Options = {}

for _, Item in ipairs(WinPads:GetChildren()) do
    table.insert(Options, Item.Name)
end

local function Index(Item: string): Instance?
    return WinPads:FindFirstChild(Item)
end

tabs.main:CreateDropdown({
    Name = "Tp Zone",
    Options = Options,
    CurrentOption = Options[1],
    MultipleOptions = false,
    Callback = function(option)
        -- Rayfield sometimes passes a table even in single-select mode
        if typeof(option) == "table" then
            option = option[1]
        end
        SetValue(states.values, "TweenArea", option)
    end,
})

local function Teleport(HumanoidRootPart, Goal: CFrame): boolean
    if HumanoidRootPart then
        HumanoidRootPart.CFrame = Goal
    end
    return true
end

local speed = 60
local isTweening = false

local function TweenTo(Part: BasePart): boolean
    if isTweening then return false end -- don't start a new one while one's running

    local Character = player.Character
    if not Character then return false end
    local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
    if not HumanoidRootPart then return false end

    local GoalCFrame = Part.CFrame + Vector3.new(0, Part.Size.Y / 2 + 6, 0)
    local distance = (HumanoidRootPart.Position - GoalCFrame.Position).Magnitude

    isTweening = true

    local tween = TweenService:Create(
        HumanoidRootPart,
        TweenInfo.new(distance / speed, Enum.EasingStyle.Linear),
        { CFrame = GoalCFrame }
    )

    tween.Completed:Once(function(playbackState)
        if playbackState == Enum.PlaybackState.Completed then
            local FinalCharacter = player.Character
            local FinalHRP = FinalCharacter and FinalCharacter:FindFirstChild("HumanoidRootPart")
            Teleport(FinalHRP, GoalCFrame)
        end
        isTweening = false -- release the lock whether it completed or got cancelled
    end)

    tween:Play()
    return true
end

local function GetTween(): BasePart?
    local area = states.values.TweenArea
    if not area then return nil end

    if typeof(area) == "table" then
        area = area[1]
    end

    if typeof(area) ~= "string" then return nil end

    local model = Index(area)
    if not model then return nil end

    return model:FindFirstChild("HitBox")
end

tabs.main:CreateButton({
    Name = "Tween",
    Callback = function()
        local Part = GetTween()
        if not Part then
            Rayfield:Notify({
                Title = "Error",
                Content = "No valid Tp Zone selected",
                Duration = 3,
            })
            return
        end
        TweenTo(Part)
    end,
})

tabs.main:CreateToggle({
    Name = "Auto Tween",
    CurrentValue = false,
    Callback = function(value)
        SetValue(states.values, "AutoTween", value)

        if value then
            addConnection(connections.gameplay, "AutoTween", RunService.Heartbeat:Connect(function()
                local Part = GetTween()
                if Part then
                    TweenTo(Part) -- no-ops automatically if already tweening
                end
            end))
        else
            removeConnection(connections.gameplay, "AutoTween")
        end
    end,
})

tabs.main:CreateDivider()

local NpcName = "Dummy" .. (CurrentWorld > 1 and tostring(CurrentWorld) or "")
local Npc = workspace:FindFirstChild(NpcName)
    or workspace:WaitForChild(NpcName, 5)

local Npcs = {}

if Npc then
    for _, Item in ipairs(Npc:GetChildren()) do
        -- recursive search in case Hitbox is nested inside the model, not a direct child
        if Item:FindFirstChild("Hitbox", true) then
            table.insert(Npcs, Item.Name)
        end
    end
else
    warn("[AutoLevels] Could not find Dummy" .. CurrentWorld .. " in workspace")
end

tabs.main:CreateDropdown({
    Name = "Level Zone",
    Options = Npcs,
    CurrentOption = Npcs[1],
    MultipleOptions = false,
    Callback = function(option)
        if typeof(option) == "table" then
            option = option[1]
        end
        SetValue(states.values, "SelectedNpc", option)
    end,
})

local function GetSelectedHitbox(): BasePart?
    local selected = states.values.SelectedNpc
    if not selected or not Npc then return nil end

    local target = Npc:FindFirstChild(selected)
    if not target then return nil end

    return target:FindFirstChild("Hitbox", true) -- recursive, matches the build-list check above
end

tabs.main:CreateToggle({
    Name = "Auto Levels",
    CurrentValue = false,
    Callback = function(value)
        SetValue(states.values, "AutoLevels", value)

        if value then
            local hitbox = GetSelectedHitbox()

            if hitbox then
                local Character = player.Character
                local HumanoidRootPart = Character and Character:FindFirstChild("HumanoidRootPart")
                local GoalCFrame = hitbox.CFrame + Vector3.new(0, hitbox.Size.Y / 2 + 3, 0)
                Teleport(HumanoidRootPart, GoalCFrame)
            end

            addConnection(connections.gameplay, "AutoLevels", task.spawn(function()
                while states.values.AutoLevels do
                    local currentHitbox = GetSelectedHitbox()

                    if currentHitbox then
                        pcall(function()
                            ReplicatedStorage.Remotes.DamageBlock:InvokeServer(currentHitbox)
                        end)
                    end

                    task.wait()
                end
            end))
        else
            removeConnection(connections.gameplay, "AutoLevels")
        end
    end,
})

tabs.settings:CreateLabel("Settings")

tabs.settings:CreateToggle({
    Name = "Debug Mode",
    CurrentValue = false,
    Callback = function(value)
        SetValue(states.values, "Debug", value)
    end,
})

Rayfield:Notify({
    Title = Game,
    Content = "Successfully Loaded!",
    Duration = 5,
    Image = 4483362458,
})
