loadstring(game:HttpGet("https://www.voltex.website/src/Modules/Platform.lua"))()
local device = getgenv()["device"]

getgenv().PlayerHelper = true

local Services = loadstring(game:HttpGet(
    "https://roblox-alpha-murex.vercel.app/src/Modules/Variables.lua"
))()

local Players = Services.Players
local Player = Services.Player
local RunService = Services.RunService
local UserInputService = Services.UserInputService
local VirtualInputManager = Services.VirtualInputManager
local CoreGui = Services.CoreGui
local CurrentCamera = Services.Workspace.CurrentCamera

if not Player.Character then
    Player.CharacterAdded:Wait()
end
local Character = Player.Character
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

Player.CharacterAdded:Connect(function(NewCharacter)
    Character = NewCharacter
    HumanoidRootPart = NewCharacter:WaitForChild("HumanoidRootPart")
    Humanoid = NewCharacter:WaitForChild("Humanoid")
end)

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "Teen-Titan Battleground",
    LoadingTitle = "Title",
    LoadingSubtitle = "Subtitle",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = nil,
        FileName = "vfig"
    }
})

local Flags = Rayfield.Flags

local main = Window:CreateTab("Main")
main:CreateSection("Aimbot / Combat")

local function isme(char)
    local player = Players:GetPlayerFromCharacter(char)
    return player ~= Player
end

local function gclosest()
    local closest, dist = nil, math.huge
    local mouse = UserInputService:GetMouseLocation()

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player and p.Character then
            local t = p.Character:FindFirstChild("HumanoidRootPart") or p.Character:FindFirstChild("Torso")
            if t then
                local v, on = CurrentCamera:WorldToViewportPoint(t.Position)

                if on and v.Z > 0 then
                    if (CurrentCamera.CFrame.Position - t.Position).Magnitude <= 1000 then
                        local d = (Vector2.new(v.X, v.Y) - mouse).Magnitude
                        if d < dist then
                            dist = d
                            closest = p
                        end
                    end
                end
            end
        end
    end

    return closest
end

main:CreateToggle({
    Name = "Enable Aimbot",
    CurrentValue = false,
    Flag = "EnableAimbot",
    Callback = function() end
})

main:CreateToggle({
    Name = "Require Keybind",
    CurrentValue = true,
    Flag = "RequireKeybind",
    Callback = function() end
})

main:CreateToggle({
    Name = "TriggerBot",
    CurrentValue = false,
    Flag = "TriggerBot",
    Callback = function() end
})

local holding = false
UserInputService.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton2 then
        holding = true
    end
end)

UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton2 then
        holding = false
    end
end)

if device == "Mobile" then
    local gui = Instance.new("ScreenGui")
    gui.Name = "aimlock"
    gui.Parent = CoreGui

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 100, 0, 50)
    btn.Position = UDim2.new(0.8, 0, 0.8, 0)
    btn.Text = "LOCK"
    btn.Parent = gui

    btn.MouseButton1Down:Connect(function()
        holding = true
    end)

    btn.MouseButton1Up:Connect(function()
        holding = false
    end)
end

local last = 0
RunService.RenderStepped:Connect(function()
    local target = gclosest()
    if not target or not target.Character then return end

    local hrp = target.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local camPos = CurrentCamera.CFrame.Position
    local direction = (hrp.Position - camPos).Unit

    if Flags.EnableAimbot.CurrentValue and (not Flags.RequireKeybind.CurrentValue or holding) then
        CurrentCamera.CFrame = CurrentCamera.CFrame:Lerp(
            CFrame.new(camPos, camPos + direction),
            0.6
        )
    end

    if Flags.TriggerBot.CurrentValue then
        local pos, onScreen = CurrentCamera:WorldToViewportPoint(hrp.Position)
        if onScreen then
            local mouse = UserInputService:GetMouseLocation()
            local dx = pos.X - mouse.X
            local dy = pos.Y - mouse.Y
            local dist = dx*dx + dy*dy

            -- radius 12px (squared = 144)
            if dist < 144 and (time() - last) > 0.05 then
                last = time()

                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
            end
        end
    end
end)

main:CreateSection("Combat + Visuals")

local esp = loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/Libraries/Esp/main.lua"))()

main:CreateDropdown({
    Name = "Esp Settings",
    Options = {
        "Box",
        "Corners",
        "Name",
        "Held Item",
        "Tracer",
        "Quad",
        "Health",
        "Distance",
        "Chams",
        "Health Bar",
        "Team Color",
        "Performance Mode",
        "Skeleton",
        "3D Box",
    },
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "EspSettings",
    Callback = function(selectedOptions)
        -- Reset all options
        esp:SetProperty("ShowBox", false)
        esp:SetProperty("ShowCorners", false)
        esp:SetProperty("ShowName", false)
        esp:SetProperty("ShowHeld", false)
        esp:SetProperty("ShowTracer", false)
        esp:SetProperty("ShowQuad", false)
        esp:SetProperty("ShowHealth", false)
        esp:SetProperty("ShowDistance", false)
        esp:SetProperty("ShowChams", false)
        esp:SetProperty("ShowHealthBar", false)
        esp:SetProperty("TeamColor", false)
        esp:SetProperty("PerformanceMode", false)
        esp:SetProperty("ShowSkeleton", false)
        esp:SetProperty("Show3DBox", false)

        -- Enable selected options
        for _, option in ipairs(selectedOptions) do
            if option == "Box" then
                esp:SetProperty("ShowBox", true)
            elseif option == "Corners" then
                esp:SetProperty("ShowCorners", true)
            elseif option == "Name" then
                esp:SetProperty("ShowName", true)
            elseif option == "Held Item" then
                esp:SetProperty("ShowHeld", true)
            elseif option == "Tracer" then
                esp:SetProperty("ShowTracer", true)
            elseif option == "Quad" then
                esp:SetProperty("ShowQuad", true)
            elseif option == "Health" then
                esp:SetProperty("ShowHealth", true)
            elseif option == "Distance" then
                esp:SetProperty("ShowDistance", true)
            elseif option == "Chams" then
                esp:SetProperty("ShowChams", true)
            elseif option == "Health Bar" then
                esp:SetProperty("ShowHealthBar", true)
            elseif option == "Team Color" then
                esp:SetProperty("TeamColor", true)
            elseif option == "Performance Mode" then
                esp:SetProperty("PerformanceMode", true)
            elseif option == "Skeleton" then
                esp:SetProperty("ShowSkeleton", true)
            elseif option == "3D Box" then
                esp:SetProperty("Show3DBox", true)
            end
        end
    end,
})

main:CreateToggle({
    Name = "Enable",
    CurrentValue = false,
    Flag = "Enable",
    Callback = function(v)
        if v then
            esp:Enable()
        else
            esp:Disable()
        end
    end,
})

main:CreateSlider({
    Name = "Esp Distance",
    Range = {1, 2000},
    Increment = 10,
    Suffix = "studs",
    CurrentValue = 1000,
    Flag = "EspDistance",
    Callback = function(v)
        esp:SetProperty("MaxDist", v)
    end,
})

main:CreateDivider()

local boxes = {}
local function applyHitbox(char)
    if not isme(char) then return end

    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if Flags.HitboxExpander.CurrentValue then
        local size = Flags.HitboxSize.CurrentValue
        hrp.Size = Vector3.new(size, size, size)
        hrp.Transparency = 0.7
        hrp.CanCollide = false
    else
        hrp.Size = Vector3.new(2, 2, 1)
        hrp.Transparency = 1
        hrp.CanCollide = false
    end
end

local function hookPlayer(p)
    p.CharacterAdded:Connect(function(char)
        task.wait(0.1)
        applyHitbox(char)
    end)

    if p.Character then
        applyHitbox(p.Character)
    end
end

main:CreateToggle({
    Name = "Hitbox Expander",
    CurrentValue = false,
    Flag = "HitboxExpander",
    Callback = function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character then
                applyHitbox(p.Character)
            end
        end
    end
})

main:CreateSlider({
    Name = "Hitbox Size",
    Range = {10, 60},
    Increment = 1,
    Suffix = "studs",
    CurrentValue = 20,
    Flag = "HitboxSize",
    Callback = function()
        if Flags.HitboxExpander.CurrentValue then
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character then
                    applyHitbox(p.Character)
                end
            end
        end
    end
})

for _, p in ipairs(Players:GetPlayers()) do
    hookPlayer(p)
end

Players.PlayerAdded:Connect(hookPlayer)

local misc = Window:CreateTab("Misc")

local gquality = settings().Rendering.QualityLevel
misc:CreateToggle({
    Name = "Anti-Lag",
    CurrentValue = false,
    Flag = "AntiLag",
    Callback = function(v)
        if v then
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        else
            settings().Rendering.QualityLevel = gquality
        end
    end
})

local rnum = tostring(math.random(1e7, 1e9))
misc:CreateToggle({
    Name = "Anti-Void",
    CurrentValue = false,
    Flag = "AntiVoid",
    Callback = function(val)
        if val then
            if not workspace:FindFirstChild(rnum) then
                local part = Instance.new("Part", workspace)
                part.Name = rnum
                part.Anchored = true
                part.Size = Vector3.new(1000, 1, 1000)
                part.Position = Vector3.new(0, -1, 0)
                part.Transparency = 0.8
                part.CanCollide = true
                part.BrickColor = BrickColor.new("Really red")
            end
        else
            if workspace:FindFirstChild(rnum) then
                workspace[rnum]:Destroy()
            end
        end
    end
})

local auto = Window:CreateTab("Autofarm")
auto:CreateSection("Autofarm")

local grav = workspace.Gravity
auto:CreateToggle({
    Name = "Autofarm",
    CurrentValue = false,
    Flag = "Autofarm",
    Callback = function(v)
        workspace.Gravity = v and 0 or grav
    end
})

auto:CreateLabel("Settings")

local methods = {
    "Safe", -- orbits around the map shooting
    "Teleport" -- auto teleports to closest
}
auto:CreateDropdown({
    Name = "Method",
    Options = methods,
    CurrentOption = methods[1],
    Flag = "Method",
    Callback = function() end
})

auto:CreateDivider()

local chars, listed = {}, {}
local spawnFolder = workspace:FindFirstChild("Spawn")
local touchFolder = spawnFolder and spawnFolder:FindFirstChild("CharacterSelectTouchParts")
if touchFolder then
    for _, item in ipairs(touchFolder:GetChildren()) do
        chars[item.Name] = item
        table.insert(listed, item.Name)
    end
end
--listed = table.sort(listed)

auto:CreateDropdown({
    Name = "Character",
    Options = listed,
    CurrentOption = listed[1],
    Flag = "Character",
    Callback = function() end
})

auto:CreateToggle({
    Name = "Auto Select Character on death",
    CurrentValue = false,
    Flag = "AutoSelectCharacter",
    Callback = function() end
})

local function selectCharacter()
    if not Flags.AutoSelectCharacter.CurrentValue then return end

    local char = chars[Flags.Character.CurrentOption[1]]
    if not char then return end

    if firetouchinterest then
        firetouchinterest(char, HumanoidRootPart, true)
        firetouchinterest(char, HumanoidRootPart, false)
    else
        HumanoidRootPart.CFrame = char.CFrame + Vector3.new(0, 3, 0)
        task.wait(0.5)
    end
end

auto:CreateDivider()

local s = {"1", "2", "3", "all"}
auto:CreateDropdown({
    Name = "Tool to select",
    Options = s,
    CurrentOption = s[1],
    Flag = "ToolSelect",
    Callback = function() end
})

auto:CreateToggle({
    Name = "Auto Select",
    CurrentValue = false,
    Flag = "AutoSelect",
    Callback = function() end
})

local function equipTool()
    if not Humanoid then return end

    local backpack = Player:FindFirstChildOfClass("Backpack")
    if not backpack then return end

    if Flags.ToolSelect.CurrentOption[1] == "all" then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then
                Humanoid:EquipTool(tool)
                task.wait(0.05)
            end
        end
    else
        local index = tonumber(Flags.ToolSelect.CurrentOption[1])
        if index then
            local tool = backpack:GetChildren()[index]
            if tool and tool:IsA("Tool") then
                Humanoid:EquipTool(tool)
            end
        end
    end
end

-- main --

local wasaf = false

local function onDied()
    wasaf = Flags.Autofarm.CurrentValue
    Flags.Autofarm:Set(false)
end

Humanoid.Died:Connect(onDied)

Player.CharacterAdded:Connect(function()
    Humanoid.Died:Connect(onDied)

    task.wait(0.5)

    if Flags.AutoSelectCharacter.CurrentValue then
        selectCharacter()
        task.wait(1)
    end

    if Flags.AutoSelect.CurrentValue then
        task.wait(1)
        equipTool()
    end

    if wasaf then
        Flags.Autofarm:Set(true)
        wasaf = false
    end
end)

local t = 0
RunService.Heartbeat:Connect(function(dt)
    if not Flags.Autofarm.CurrentValue then return end

    pcall(function()
        local target = gclosest()
        if not target or not target.Character then return end
        
        local troot = target.Character:FindFirstChild("HumanoidRootPart")
        if not troot then return end

        if Flags.Method.CurrentOption[1] == "Teleport" then
            HumanoidRootPart.CFrame = troot.CFrame * CFrame.new(0, 0, 3)

        elseif Flags.Method.CurrentOption[1] == "Safe" then
            t = t + dt
            local radius, height = 225, 75

            local baseplate = game:GetDescendants()["Baseplate"] -- or has the MapFolder tag
            local center = baseplate and baseplate.Position or Vector3.new(0, 0, 0)

            local pos = center + Vector3.new(
                math.cos(t * 0.5) * radius,
                height,
                math.sin(t * 0.5) * radius
            )

            HumanoidRootPart.CFrame = HumanoidRootPart.CFrame:Lerp(CFrame.new(pos), 0.25)
        end
    end)
end)
