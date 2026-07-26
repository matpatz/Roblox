getgenv().SecureMode = true

local services = loadstring(game:HttpGet(
    "https://website-iota-ivory-12.vercel.app/code/loader/u/vars.lua"
))()

local Rayfield = loadstring(game:HttpGet(
    "https://website-iota-ivory-12.vercel.app/code/loader/u/ui/rayfield.lua"
))()

local lp = services["player"]

local window = Rayfield:CreateWindow({
    Name = "Prospecting",
    LoadingTitle = "Prospecting",
    LoadingSubtitle = "Automation",
    ConfigurationSaving = { Enabled = true, FileName = "figcon" },
    Discord = { Enabled = false },
    KeySystem = false,
})

local Tabs = {
    main = window:CreateTab("Main", 4483362458),
    settings = window:CreateTab("Settings", 4483362458),
}

local Connections = {
    automation = {},
}

local States = {
    runtime = {},
    values = {
        AutoFarm = false,
        CurrentAction = "Collecting",
        SavedPosition = nil,
        WaterPosition = nil,
        PlayerPosition = nil,
        PanSpeed = 0.05,
    },
}

local function SetValue(obj, key, value)
    obj[key] = value
end

local function AddConnection(category, name, connection)
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
    States.runtime[name] = true
end

local function RemoveConnection(category, name)
    if not category[name] then return end

    pcall(function()
        if typeof(category[name]) == "RBXScriptConnection" then
            category[name]:Disconnect()
        else
            task.cancel(category[name])
        end
    end)

    category[name] = nil
    States.runtime[name] = false
end

local function GetTool()
    return lp.Character and lp.Character:FindFirstChildOfClass("Tool")
end

local function GetRemotes()
    local Tool = GetTool()
    local Scripts = Tool and Tool:FindFirstChild("Scripts")
    return Scripts and {
        Collect = Scripts:FindFirstChild("Collect"),
        Pan = Scripts:FindFirstChild("Pan"),
        Shake = Scripts:FindFirstChild("Shake"),
        PanningComplete = Scripts:FindFirstChild("PanningComplete"),
    } or {}
end

local function GetCurrentFill()
    local FillText = lp.PlayerGui
        and lp.PlayerGui:FindFirstChild("ToolUI")
        and lp.PlayerGui.ToolUI:FindFirstChild("FillingPan")
        and lp.PlayerGui.ToolUI.FillingPan:FindFirstChild("FillText")

    return tonumber(FillText and FillText.Text:match("^(%d+)") or "0") or 0
end

local function GetMaxCapacity()
    local Tool = GetTool()
    local Stats = Tool and Tool:FindFirstChild("Stats")
    return Stats and Stats:GetAttribute("Capacity") or 0
end

local function CFrameToTable(cframe)
    return {
        cframe.X, cframe.Y, cframe.Z,
        cframe:GetComponents()
    }
end

local function TableToCFrame(t)
    if not t or #t < 12 then return nil end
    return CFrame.new(t[1], t[2], t[3], t[4], t[5], t[6], t[7], t[8], t[9], t[10], t[11], t[12])
end

local function RunAutomation()
    local Hrp
    local Tool

    repeat
        Hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        Tool = GetTool()
        task.wait(0.02)
    until Hrp and Tool and States.values.AutoFarm

    while States.values.AutoFarm do
        Hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        Tool = GetTool()
        local Remotes = GetRemotes()
        local MaxCap = GetMaxCapacity()
        local CurrentFill = GetCurrentFill()
        local Action = States.values.CurrentAction
        local SavedPos = States.values.SavedPosition
        local PlayerPos = States.values.PlayerPosition
        local WaterPos = States.values.WaterPosition

        if Action == "Collecting" then
            if Remotes.Shake then
                Remotes.Shake:FireServer()
            end

            if Hrp and PlayerPos then
                Hrp.CFrame = PlayerPos
            elseif Hrp and SavedPos then
                Hrp.CFrame = SavedPos
            end

            if Remotes.Collect then
                Remotes.Collect:InvokeServer(1)
            end

            task.wait(0.02)

            if CurrentFill >= MaxCap then
                SetValue(States.values, "CurrentAction", "Panning")
            end

        elseif Action == "Panning" then
            if Hrp and WaterPos then
                Hrp.CFrame = WaterPos
            end

            if Remotes.Pan then
                Remotes.Pan:InvokeServer()
            end

            if Remotes.Shake then
                Remotes.Shake:FireServer()
            end

            task.wait(States.values.PanSpeed)

            CurrentFill = GetCurrentFill()
            if CurrentFill == 0 then
                SetValue(States.values, "CurrentAction", "Collecting")
            end
        end

        task.wait(0.02)
    end
end

Tabs.main:CreateLabel("Automation")

Tabs.main:CreateToggle({
    Name = "Auto Collect / Pan / Sell",
    CurrentValue = false,
    Callback = function(value)
        SetValue(States.values, "AutoFarm", value)
        SetValue(States.values, "CurrentAction", "Collecting")

        if value then
            local Hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
            if Hrp then
                SetValue(States.values, "SavedPosition", Hrp.CFrame)
            end

            AddConnection(Connections, "automation", task.spawn(RunAutomation))
        else
            RemoveConnection(Connections, "automation")
        end
    end,
})

Tabs.settings:CreateLabel("Position Saving")

Tabs.settings:CreateButton({
    Name = "Save Player Position",
    Callback = function()
        local Hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if Hrp then
            SetValue(States.values, "PlayerPosition", Hrp.CFrame)
            Rayfield:Notify({
                Title = "Position Saved",
                Content = "Player position saved! ✓",
                Duration = 3,
                Image = 4483362458,
            })
        else
            Rayfield:Notify({
                Title = "Error",
                Content = "Could not find player position.",
                Duration = 3,
                Image = 4483362458,
            })
        end
    end,
})

Tabs.settings:CreateButton({
    Name = "Save Water Position",
    Callback = function()
        local Hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if Hrp then
            SetValue(States.values, "WaterPosition", Hrp.CFrame)
            Rayfield:Notify({
                Title = "Position Saved",
                Content = "Water position saved!",
                Duration = 3,
                Image = 4483362458,
            })
        else
            Rayfield:Notify({
                Title = "Error",
                Content = "Could not find water position.",
                Duration = 3,
                Image = 4483362458,
            })
        end
    end,
})

Tabs.settings:CreateLabel("Pan Speed")

Tabs.settings:CreateSlider({
    Name = "Pan Speed (Lower = Faster)",
    Range = {0.01, 0.2},
    Increment = 0.01,
    Suffix = "s",
    CurrentValue = 0.05,
    Callback = function(value)
        SetValue(States.values, "PanSpeed", value)
    end,
})

Tabs.settings:CreateButton({
    Name = "Clear Saved Positions",
    Callback = function()
        SetValue(States.values, "PlayerPosition", nil)
        SetValue(States.values, "WaterPosition", nil)
        Rayfield:Notify({
            Title = "Cleared",
            Content = "All saved positions cleared.",
            Duration = 3,
            Image = 4483362458,
        })
    end,
})

Rayfield:Notify({
    Title = "Prospecting",
    Content = "successfully loaded!",
    Duration = 5,
    Image = 4483362458,
})
