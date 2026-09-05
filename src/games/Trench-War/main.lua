--[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]
loadstring(game:HttpGet("https://www.voltex.website/src/Modules/Platform.lua"))()
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

local misc = Window:CreateTab("Op / Misc")

local function gteam()
    local tname = lp.Team.Name
    local target

    if tname == "Allies" then
        target = "Axis"
    else
        target = "Allies"
    end

    return tname, target
end

local function gflag(target)
    if target == "Axis" then
        return "GermanFlag"
    elseif target == "Allies" then
        return "BritishFlag"
    end
end

local char = lp.Character or lp.CharacterAdded:Wait()

misc:CreateButton({
	Name = "Capture Flag",
	Callback = function()
        local tname, target = gteam()
        local flag = workspace["Infrastructures"][gflag(target)]["Pad"]

        local root = char.HumanoidRootPart
        if firetouchinterest then
            firetouchinterest(flag, root, true)
            firetouchinterest(flag, root, false)
        else
            local old = root.CFrame
            root.CFrame = flag
            root.CFrame = old
        end
	end,
})

misc:CreateDivider()

local function gtool()
    local tool = char:FindFirstChildWhichIsA("Tool")
    if not tool then return end

    local remote = tool:FindFirstChildWhichIsA("RemoteEvent")
    local muzzle = tool:FindFirstChild("BPos")
    if not remote then return end

    return tool, remote, muzzle
end

local function kill(tool, remote, muzzle, hum, hrp, model)
    local name = tool.Name

    local origin = muzzle.Position
    local target = hrp.Position

    if name == "Mortar" or "Gernade" then
        remote:FireServer(target)
        return
    end

    local dist = (origin - target).Magnitude
    local cf = CFrame.new(origin, target) * CFrame.Angles(0, math.pi/2, 0) * CFrame.new(dist / 2, 0, 0)

    if name == "M1Garand" or name == "Machine Gun" then
        remote:FireServer(false, 40, {dist, cf})
        return
    end

    if name == "Pistol" then
        remote:FireServer(nil, nil, {dist, cf})
        return
    end

    if name == "Sniper" then
        remote:FireServer({
            [3] = {dist, cf}
        })
        return
    end

    local dmg = model:FindFirstChild("Head") and 200 or 100
    remote:FireServer(hum, dmg, {dist, cf})
end

local function all()
    local tool, remote, muzzle = gtool()
    if not tool or not remote then return end

    for _, model in ipairs(workspace:GetChildren()) do
        local hum = model:FindFirstChildWhichIsA("Humanoid")
        local hrp = model:FindFirstChild("HumanoidRootPart")

        if hum and hrp and model ~= char then
            kill(tool, remote, muzzle, hum, hrp, model)
        end
    end
end

misc:CreateButton({
	Name = "Kill All",
	Callback = function()
        all()
	end,
})

local function report(user)
    rep.Event:FireServer(
        "BanHacker",
        {
            game:GetService("Players")[tostring(user)]
        }
    )
end

local function getNames()
    local t = {}
    for _, p in ipairs(players:GetPlayers()) do
        table.insert(t, p.Name)
    end
    return t
end

misc:CreateDivider()

local player = misc:CreateDropdown({
    Name = "Player",
    Options = getNames(),
    CurrentOption = getNames()[1],
    MultipleOptions = false,
    Flag = "player",
    Callback = function(v)
    end,
})

local function refresh()
    player:Refresh(getNames())
end

players.PlayerAdded:Connect(refresh)
players.PlayerRemoving:Connect(refresh)

misc:CreateButton({
    Name = "Report Player",
    Callback = function()
        local selected = player.CurrentOption

        if type(selected) == "table" then
            selected = selected[1]
        end

        report(selected)
    end,
})

misc:CreateDivider()

misc:CreateButton({
    Name = "Load fly GUI",
    Callback = function()
        loadstring(game:HttpGet("https://pastebin.com/raw/MsL78SwX"))()
    end,
})
