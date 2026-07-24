loadstring(game:HttpGet("https://github.com/matpatz/luau/raw/main/public/code/loader/u/device.lua"))()
local device = getgenv()["device"]

local get = (type(cloneref) == "function") and cloneref or function(x) return x end
local players = get(game:GetService("Players")); local lp = players["LocalPlayer"]
local rs = get(game:GetService("RunService"))
local input = get(game:GetService("UserInputService"))
local vim = get(game:GetService("VirtualInputManager"))
local rep = get(game:GetService("ReplicatedStorage"))
local core = get(game:GetService("CoreGui"))
local lighting = get(game:GetService("Lighting"))
local https = get(game:GetService("HttpService"))
local cs = get(game:GetService("CollectionService"))
local stats = get(game:GetService("Stats"))
local marketplace = get(game:GetService("MarketplaceService"))
local analytic = get(game:GetService("RbxAnalyticsService"))
local log = get(game:GetService("LogService"))

local cam = workspace.CurrentCamera

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "Voltex - " .. tostring(game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name),
    LoadingTitle = "Title",
    LoadingSubtitle = "Subtitle",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = nil,
        FileName = "vfig"
    }
})

local main = Window:CreateTab("Main")
main:CreateSection("Aimbot / Combat")

local function isme(char)
    local player = players:GetPlayerFromCharacter(char)
    return player ~= lp
end

local function gclosest()
    local closest, dist = nil, math.huge
    local mouse = input:GetMouseLocation()

    for _, p in ipairs(players:GetPlayers()) do
        if p ~= lp and p.Character then
            local t = p.Character:FindFirstChild("HumanoidRootPart") or p.Character:FindFirstChild("Torso")
            if t then
                local v, on = cam:WorldToViewportPoint(t.Position)

                if on and v.Z > 0 then
                    if (cam.CFrame.Position - t.Position).Magnitude <= 1000 then
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

local aimbot = false
main:CreateToggle({
    Name = "Enable Aimbot",
    CurrentValue = aimbot,
    Flag = "ea",
    Callback = function(v)
        aimbot = v
    end
})

local tbot = false
main:CreateToggle({
    Name = "TriggerBot",
    CurrentValue = tbot,
    Flag = "tb",
    Callback = function(v)
        tbot = v
    end
})

local holding = false
input.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton2 then
        holding = true
    end
end)

input.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton2 then
        holding = false
    end
end)

if device == "Mobile" then
    local gui = Instance.new("ScreenGui")
    gui.Name = "aimlock"
    gui.Parent = core

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
rs.RenderStepped:Connect(function()
    local target = gclosest()
    if not target or not target.Character then return end

    local hrp = target.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local camPos = cam.CFrame.Position
    local direction = (hrp.Position - camPos).Unit

    if aimbot and holding then
        cam.CFrame = cam.CFrame:Lerp(
            CFrame.new(camPos, camPos + direction),
            0.6
        )
    end

    if tbot then
        local pos, onScreen = cam:WorldToViewportPoint(hrp.Position)
        if onScreen then
            local mouse = input:GetMouseLocation()
            local dx = pos.X - mouse.X
            local dy = pos.Y - mouse.Y
            local dist = dx*dx + dy*dy

            -- radius 12px (squared = 144)
            if dist < 144 and (time() - last) > 0.05 then
                last = time()

                vim:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                vim:SendMouseButtonEvent(0, 0, 0, false, game, 0)
            end
        end
    end
end)

main:CreateSection("Combat + Visuals")

local cesp = loadstring(game:HttpGet("https://website-iota-ivory-12.vercel.app/code/loader/u/esp.lua"))();local esp = cesp()
main:CreateDropdown({
    Name = "Esp Settings",
    Options = {"Box", "Name", "Held Item", "Tracer", "Health", "Distance", "Chams", "Health Bar", "Team Color", "Performance Mode"},
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "es",
    Callback = function(selectedOptions)
        esp:box(false)
        esp:name(false)
        esp:held(false)
        esp:tracer(false)
        esp:health(false)
        esp:distance(false)
        esp:chams(false)
        esp:healthbar(false)
        esp:team(false)
        esp:performance(false)

        for _, option in pairs(selectedOptions) do
            if option == "Box" then esp:box(true)
            elseif option == "Name" then esp:name(true)
            elseif option == "Held Item" then esp:held(true)
            elseif option == "Tracer" then esp:tracer(true)
            elseif option == "Health" then esp:health(true)
            elseif option == "Distance" then esp:distance(true)
            elseif option == "Chams" then esp:chams(true)
            elseif option == "Health Bar" then esp:healthbar(true)
            elseif option == "Team Color" then esp:team(true)
            elseif option == "Performance Mode" then esp:performance(true)
            end
        end
    end,
})

main:CreateToggle({
    Name = "Enable",
    CurrentValue = false,
    Flag = "esp",
    Callback = function(v)
        if v then esp:enable() else esp:disable() end
    end,
})

main:CreateDivider()

local hitbox, hsize = false, 20; local boxes = {}
local function applyHitbox(char)
    if not isme(char) then return end

    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if hitbox then
        hrp.Size = Vector3.new(hsize, hsize, hsize)
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

for _, p in ipairs(players:GetPlayers()) do
    hookPlayer(p)
end

players.PlayerAdded:Connect(hookPlayer)

main:CreateToggle({
    Name = "Hitbox Expander",
    CurrentValue = hitbox,
    Flag = "he",
    Callback = function(v)
        hitbox = v

        for _, p in ipairs(players:GetPlayers()) do
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
    CurrentValue = hsize,
    Flag = "hs",
    Callback = function(v)
        hsize = v

        if hitbox then
            for _, p in ipairs(players:GetPlayers()) do
                if p.Character then
                    applyHitbox(p.Character)
                end
            end
        end
    end
})

local misc = Window:CreateTab("Misc")

local gquality = settings().Rendering.QualityLevel
misc:CreateToggle({
    Name = "Anti-Lag",
    CurrentValue = false,
    Flag = "al",
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
    Flag = "av",
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

local autofarm = false; local grav = workspace.Gravity
auto:CreateToggle({
    Name = "Autofarm",
    CurrentValue = autofarm,
    Flag = "af",
    Callback = function(v)
        autofarm = v
        workspace.Gravity = v and 0 or grav
    end
})

auto:CreateLabel("Settings")

local method, methods = "Safe", {
    "Safe", -- orbits around the map shooting
    "Teleport" -- auto teleports to closest
}
auto:CreateDropdown({
    Name = "Method",
    Options = methods,
    CurrentOption = methods[1],
    Flag = "am",
    Callback = function(v)
        method = v
    end
})

auto:CreateDivider()

local chars, listed = {}, {}
for _, item in ipairs(workspace["Spawn"]["CharacterSelectTouchParts"]:GetChildren()) do
    chars[item.Name] = item
    table.insert(listed, item.Name)
end
--listed = table.sort(listed)

local selected = chars[listed[1]]
auto:CreateDropdown({
    Name = "Character",
    Options = listed,
    CurrentOption = listed[1],
    Flag = "sm",
    Callback = function(v)
        selected = chars[v]
    end
})

local aselect = false
auto:CreateToggle({
    Name = "Auto select character on death",
    CurrentValue = aselect,
    Flag = "as",
    Callback = function(v)
        aselect = v
    end
})

local function selectCharacter()
    if not selected or not aselect then return end

    if firetouchinterest then
        local root = lp.Character.HumanoidRootPart
        firetouchinterest(selected, root, true)
        firetouchinterest(selected, root, false)
    else
        root.CFrame = selected.CFrame + Vector3.new(0, 3, 0)
        task.wait(0.5)
    end
end

auto:CreateDivider()

local bselected = "1"; local s = {"1", "2", "3", "all"}
auto:CreateDropdown({
    Name = "Tool to select",
    Options = s,
    CurrentOption = s[1],
    Flag = "bs",
    Callback = function(v)
        bselected = v
    end
})

local autobackpack = false
auto:CreateToggle({
    Name = "Auto Select",
    CurrentValue = autobackpack,
    Flag = "asb",
    Callback = function(v)
        autobackpack = v
    end
})

local function equipTool()
    if not lp.Character then return end
    
    local hum = lp.Character:FindFirstChild("Humanoid")
    local backpack = lp:FindFirstChildOfClass("Backpack")

    if not hum or not backpack then return end

    if bselected == "all" then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then
                hum:EquipTool(tool)
                task.wait(0.05)
            end
        end
    else
        local index = tonumber(bselected)
        if index then
            local tool = backpack:GetChildren()[index]
            if tool and tool:IsA("Tool") then
                hum:EquipTool(tool)
            end
        end
    end
end

-- main --

local died = Instance.new("BindableEvent")
local wasaf = false
local wasaimbot = false
local wastbot = false

lp.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid", 10)
    if hum then
        hum.Died:Connect(function()
            died:Fire()
        end)
    end
    
    local hrp = char:WaitForChild("HumanoidRootPart", 10)
    if not hrp then return end
    
    task.wait(0.5)

    if aselect then
        selectCharacter()
        task.wait(1)
    end

    if autobackpack then
        task.wait(1)
        equipTool()
    end

    if wasaf then
        autofarm = true
        wasaf = false
    end
    
    if wasaimbot then
        aimbot = true
        wasaimbot = false
    end
    if wastbot then
        tbot = true
        wastbot = false
    end
end)

if lp.Character then
    local hum = lp.Character:FindFirstChild("Humanoid")
    if hum then
        hum.Died:Connect(function()
            died:Fire()
        end)
    end
end

died.Event:Connect(function()
    wasaf = autofarm
    autofarm = false
    wasaimbot = aimbot
    wastbot = tbot
end)

local t = 0
rs.Heartbeat:Connect(function(dt)
    if not autofarm then return end

    pcall(function()
        local char = lp.Character
        if not char then return end
        
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        local target = gclosest()
        if not target or not target.Character then return end
        
        local troot = target.Character:FindFirstChild("HumanoidRootPart")
        if not troot then return end

        aimbot, tbot, holding = true, true, true

        if method == "Teleport" then
            root.CFrame = troot.CFrame * CFrame.new(0, 0, 3)

        elseif method == "Safe" then
            t = t + dt
            local radius, height = 225, 75

            local baseplate = game:GetDescendants()["Baseplate"] -- or has the MapFolder tag
            local center = baseplate and baseplate.Position or Vector3.new(0, 0, 0)

            local pos = center + Vector3.new(
                math.cos(t * 0.5) * radius,
                height,
                math.sin(t * 0.5) * radius
            )

            root.CFrame = root.CFrame:Lerp(CFrame.new(pos), 0.25)
        end
    end)
end)
