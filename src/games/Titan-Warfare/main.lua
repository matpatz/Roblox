loadstring(game:HttpGet("https://website-iota-ivory-12.vercel.app/code/scripts/antikick/main.lua"))()

local rep = game:GetService("ReplicatedStorage")
local block = {
    ["RemoteFunction"] = rep:WaitForChild("Remotes"):WaitForChild("Titans"):WaitForChild("DepleteStamina"),
    ["Remote"] = rep:WaitForChild("Remotes"):WaitForChild("General"):WaitForChild("Log"),
	["Remote"] = rep:WaitForChild("Remotes"):WaitForChild("Titans"):WaitForChild("Grab")
}

local success, mt = pcall(function() return getrawmetatable(game) end)

if success and mt then
    setreadonly(mt, false)
    local oldNamecall = mt.__namecall

    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        
        for typeName, remote in pairs(block) do
            if self == remote then
                if method == "FireServer" or method == "InvokeServer" then
                    warn(": "..self.Name)
                    return nil
                end
            end
        end
        
        return oldNamecall(self, ...)
    end)

    setreadonly(mt, true)
end

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "Titan Warfare",
    LoadingTitle = "Subtitle",
    KeySystem = false
})

local runs = game:GetService("RunService")
local lp = game:GetService("Players").LocalPlayer

local Hit = rep.Remotes.Blades.Hit
local GrabRemote = rep.Remotes.Titans.Grab

local svt = Window:CreateTab("Main", 4483362458)
local titan = svt:CreateLabel("Titan", "wind")

local kal = nil
local ka = svt:CreateToggle({
    Name = "Kill Aura (Eldian / Pve)",
    CurrentValue = false,
    Flag = "ka",
    Callback = function(v)
        if v then
            kal = runs.Heartbeat:Connect(function()
                for _, titan in pairs(workspace.Objects.Titans:GetChildren()) do
                    local nape = titan:FindFirstChild("Nape")
                    if nape then
                        game:GetService("ReplicatedStorage").Remotes.Blades.Hit:FireServer(nape, 401)
                    end
                end
            end)
        else
            if kal then
                kal:Disconnect()
                kal = nil
            end
        end
    end,
})

--[[
local ad = nil
local tpToggle = svt:CreateToggle({
    Name = "Tp Bellow Map",
    CurrentValue = false,
    Flag = "ad",
    Callback = function(v)
        if v then
            ad = runs.Heartbeat:Connect(function()
                if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then lp.Character.HumanoidRootPart.CFrame = CFrame.new(158, 75, -4) end
            end)
        else
            if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then lp.Character.HumanoidRootPart.CFrame = CFrame.new(695, 25, -285) end

            if ad then
                ad:Disconnect()
                ad = nil
            end
        end
    end,
}) --]]

local apt = nil
local sniperToggle = svt:CreateToggle({
    Name = "Auto punch has Titan",
    CurrentValue = false,
    Flag = "apt",
    Callback = function(v)
        killAll = v
        if v then
            apt = runs.Heartbeat:Connect(function()

			local Punch = rep.Remotes.Titans.Punch
			Punch:FireServer(false)
              
            end)
        else
            if apt then
                apt:Disconnect()
                apt = nil
            end
        end
    end,
})

local GunsRemote = rep.Remotes.Guns
local GunFire = GunsRemote.Fire

local svtl = svt:CreateLabel("Pvp", "wind")

local killAll = false
local function getnearest()
    local target = nil
    local dist = math.huge
    for _, player in pairs(game.Players:GetPlayers()) do
        if player ~= lp and lp.Character then
            if player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 and player.Character:FindFirstChild("PlayerHitbox") and player.Team ~= lp.Team then
                if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                    local magnitude = (player.Character.HumanoidRootPart.Position - lp.Character.HumanoidRootPart.Position).magnitude
                    if magnitude < dist then
                        target = player
                        dist = magnitude
                    end
                end
            end
        end
    end
    return target
end

local sniperLoop = nil
local sniperToggle = svt:CreateToggle({
    Name = "Soldier Arua",
    CurrentValue = false,
    Flag = "sniper",
    Callback = function(v)
        killAll = v
        if v then
            sniperLoop = runs.Heartbeat:Connect(function()
                pcall(function()
                    if killAll and lp.Character then
                        local target = getnearest()
                        if target and target.Character then
                            -- Sniper shot
                            local args = {
                                [1] = "Sniper",
                                [2] = target.Character.Head.CFrame,
                                [3] = target.Character.Head
                            }
                            game:GetService("ReplicatedStorage").Remotes.Guns.Fire:FireServer(unpack(args))
                            
                            -- Bazooka shot
                            local args2 = {
                                [1] = target.Character.HumanoidRootPart.CFrame
                            }
                            game:GetService("ReplicatedStorage").Remotes.Guns.BazookaFire:FireServer(unpack(args2))
                        end
                    end
                end)
            end)
        else
            if sniperLoop then
                sniperLoop:Disconnect()
                sniperLoop = nil
            end
        end
    end,
})

local misc = Window:CreateTab("Misc", 4483362458)
local codes = misc:CreateLabel("Codes", "wind")

local RedeemCode = rep.Remotes.General.RedeemCode

misc:CreateButton({
    Name = "Redeem all Codes",
    Callback = function()
        local codes = {"STOP_EREN", "STOP_THE_RUMBLING", "THIS_IS_FREEDOM", "GIANT_SPINE", "FREEDOM_IS_HERE", "BREAK_FREEEEEE", "TRUE_FREEDOM", "IF_I_LOSE_IT_ALL", "MIKASA_SUKASA", "ILOVETITANWARFARE", "HANG3", "45KLIKESYAY"}
        for _, code in pairs(codes) do
            RedeemCode:InvokeServer(code)
        end
    end
})

local cs = misc:CreateLabel("Crosshair", "wind")

local crosshairColor = Color3.fromRGB(255, 0, 0)
local crosshairLines = {}

local CrosshairColorPicker = misc:CreateColorPicker({
    Name = "Crosshair Color",
    Color = crosshairColor,
    Flag = "CrosshairColor",
    Callback = function(value)
        crosshairColor = value
    end
})

local ct = misc:CreateToggle({
    Name = "Crosshair",
    CurrentValue = false,
    Flag = "ct",
    Callback = function(value)
        if not value then
            for _, line in pairs(crosshairLines) do
                if line then
                    line.Visible = false
                    line:Remove()
                end
            end
            crosshairLines = {}
        end
    end,
})

local function updtcross()
    if not ct.CurrentValue then 
        return 
    end

    if #crosshairLines == 0 then
        for i = 1, 2 do
            local line = Drawing.new("Line")
            line.Color = crosshairColor
            line.Thickness = 2
            line.Visible = true
            table.insert(crosshairLines, line)
        end
    end

    local mousePos = game:GetService("UserInputService"):GetMouseLocation()
    local posX, posY = mousePos.X, mousePos.Y

    local size = 10
    crosshairLines[1].From = Vector2.new(posX - size, posY)
    crosshairLines[1].To = Vector2.new(posX + size, posY)
    crosshairLines[2].From = Vector2.new(posX, posY - size)
    crosshairLines[2].To = Vector2.new(posX, posY + size)

    for _, line in pairs(crosshairLines) do
        if line then
            line.Color = crosshairColor
        end
    end
end

runs.RenderStepped:Connect(updtcross)

Rayfield:Notify({
    Title = "Titan Warfare",
    Content = "successfully loaded!",
    Duration = 5,
    Image = 4483362458,
})