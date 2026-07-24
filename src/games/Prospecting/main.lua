getgenv().SecureMode = true

local services = loadstring(game:HttpGet(
    "https://website-iota-ivory-12.vercel.app/code/loader/u/vars.lua"
))()

local Rayfield = loadstring(game:HttpGet(
    "https://website-iota-ivory-12.vercel.app/code/loader/u/ui/rayfield.lua"
))()

local lp = services["player"]

local WaterPosition = {
    -81.4958725, 9, 42.0576935,
    -0.016976133, 6.39132764e-08, 0.999855876,
    7.69858788e-10, 1, -6.39094182e-08,
    -0.999855876, -3.1518696e-10, -0.016976133,
}

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
    awdf = window:CreateTab("Lebron james")
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

        if Action == "Collecting" then
            if Remotes.Shake then
                Remotes.Shake:FireServer()
            end

            if Hrp and SavedPos then
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
            if Hrp then
                Hrp.CFrame = CFrame.new(unpack(WaterPosition))
            end

            if Remotes.Pan then
                Remotes.Pan:InvokeServer()
            end

            if Remotes.Shake then
                Remotes.Shake:FireServer()
            end

            task.wait(0.02)

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

Rayfield:Notify({
    Title = "Prospecting",
    Content = "successfully loaded!",
    Duration = 5,
    Image = 4483362458,
})
