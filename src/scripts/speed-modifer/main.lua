local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "Speedy",
    Icon = 0,
    LoadingTitle = "Rayfield is neat",
    LoadingSubtitle = "by Sirius",
    Theme = "Default",
    ConfigurationSaving = {Enabled = true, FileName = "SpeedConfig"},
    KeySystem = false
})

local main = Window:CreateTab("Movement", 4483362458)
main:CreateSection("Controls")

local uis = game:GetService("UserInputService")

local speed = 50
main:CreateSlider({
    Name = "Speed",
    Range = {0,200},
    Increment = 5,
    Suffix = " studs/s",
    CurrentValue = 50,
    Callback = function(v)
        speed = v
    end,
})

local moveConn
main:CreateToggle({
    Name = "Enable",
    CurrentValue = false,
    Callback = function(enabled)
        if moveConn then
            moveConn:Disconnect()
            moveConn = nil
        end

        if not enabled then return end

        moveConn = game:GetService("RunService").Heartbeat:Connect(function(dt)
            local char = game:GetService("Players").LocalPlayer.Character
            if not char then return end

            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            local cam = workspace.CurrentCamera
            local move = Vector3.zero

            if uis:IsKeyDown(Enum.KeyCode.W) then move += cam.CFrame.LookVector end
            if uis:IsKeyDown(Enum.KeyCode.S) then move -= cam.CFrame.LookVector end
            if uis:IsKeyDown(Enum.KeyCode.A) then move -= cam.CFrame.RightVector end
            if uis:IsKeyDown(Enum.KeyCode.D) then move += cam.CFrame.RightVector end

            move = Vector3.new(move.X, 0, move.Z)

            if move.Magnitude > 0 then
                hrp.CFrame += move.Unit * speed * dt
            end
        end)
    end,
})

Rayfield:LoadConfiguration()
