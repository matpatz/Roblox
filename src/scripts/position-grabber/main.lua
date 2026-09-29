--[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]
local hrp = game["Players"]["LocalPlayer"]["Character"]["HumanoidRootPart"]

local gui = Instance.new("ScreenGui")
gui.Name = "e" .. math.random(1e9, 2e9)
gui.Parent = gethui() or game.CoreGui
gui.ResetOnSpawn = false

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 150)
frame.Position = UDim2.new(0.5, -150, 0.5, -75)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.Active = true
frame.Draggable = true
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel")
title.Text = "Voltex"
title.Size = UDim2.new(0, 200, 0, 20)
title.Position = UDim2.new(0, 5, 0, 5)
title.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.SourceSansBold
title.TextScaled = true
title.BackgroundTransparency = 0.95
title.Parent = frame

local close = Instance.new("TextButton")
close.Text = "X"
close.Size = UDim2.new(0, 20, 0, 20)
close.Position = UDim2.new(1, -31, 0, 5)
close.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
close.TextColor3 = Color3.new(1, 1, 1)
close.Font = Enum.Font.SourceSansBold
close.TextScaled = true
close.BackgroundTransparency = 0.95
close.Parent = frame
Instance.new("UICorner", close).CornerRadius = UDim.new(0, 6)
close.MouseButton1Click:Connect(function()
	gui:Destroy()
end)

local textbox = Instance.new("TextBox")
textbox.Text = "x, y, z"
textbox.Size = UDim2.new(0, 220, 0, 30)
textbox.Position = UDim2.new(0.5, -110, 0, 40)
textbox.TextColor3 = Color3.fromRGB(255, 255, 255)
textbox.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
textbox.Font = Enum.Font.SourceSans
textbox.TextScaled = true
textbox.Parent = frame
Instance.new("UICorner", textbox).CornerRadius = UDim.new(0, 6)

local save = Instance.new("TextButton")
save.Text = "Save"
save.Size = UDim2.new(0, 25, 0, 25)
save.Position = UDim2.new(0.5, 115, 0, 42)
save.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
save.TextColor3 = Color3.new(1, 1, 1)
save.Font = Enum.Font.SourceSansBold
save.TextScaled = true
save.Parent = frame
Instance.new("UICorner", save).CornerRadius = UDim.new(0, 6)

local cpos = Instance.new("TextButton")
cpos.Text = "Copy Position"
cpos.Size = UDim2.new(0, 100, 0, 35)
cpos.Position = UDim2.new(0.5, -115, 1, -60)
cpos.BackgroundColor3 = Color3.fromRGB(70, 110, 240)
cpos.TextColor3 = Color3.new(1, 1, 1)
cpos.Font = Enum.Font.SourceSans
cpos.TextSize = 20
cpos.Parent = frame
Instance.new("UICorner", cpos).CornerRadius = UDim.new(0, 8)

cpos.MouseButton1Click:Connect(function()
	local pos = hrp.Position
	setclipboard(string.format("%d, %d, %d", pos.X, pos.Y, pos.Z))
end)

local delayBox = Instance.new("TextBox")
delayBox.Text = "Delay"
delayBox.Size = UDim2.new(0, 60, 0, 20)
delayBox.Position = UDim2.new(0.5, -115, 1, -23)
delayBox.TextColor3 = Color3.fromRGB(255, 255, 255)
delayBox.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
delayBox.Font = Enum.Font.SourceSans
delayBox.TextScaled = true
delayBox.Parent = frame
Instance.new("UICorner", delayBox).CornerRadius = UDim.new(0, 4)

local loop = Instance.new("TextButton")
loop.Text = "Off"
loop.Size = UDim2.new(0, 20, 0, 20)
loop.Position = UDim2.new(0.5, -40, 1, -23)
loop.BackgroundColor3 = Color3.fromRGB(50, 110, 200)
loop.TextColor3 = Color3.new(1, 1, 1)
loop.Font = Enum.Font.SourceSans
loop.TextScaled = true
loop.Parent = frame
Instance.new("UICorner", loop).CornerRadius = UDim.new(0, 4)

local looping = false; local lthread

loop.MouseButton1Click:Connect(function()
	looping = not looping
	Loop.Text = looping and "On" or "Off"

	if looping and not lthread then
		lthread = task.spawn(function()
			while looping do
				local pos = hrp.Position
				setclipboard(string.format("%d, %d, %d", pos.X, pos.Y, pos.Z))
				local delay = tonumber(TextBoxD.Text)
				if not delay or delay <= 0 then
					delay = 0.2
				end
				task.wait(delay)
			end
			lthread = nil
		end)
	end
end)

local teleport = Instance.new("TextButton")
teleport.Text = "Teleport"
teleport.Size = UDim2.new(0, 100, 0, 35)
teleport.Position = UDim2.new(0.5, 15, 1, -60)
teleport.BackgroundColor3 = Color3.fromRGB(175, 85, 240)
teleport.TextColor3 = Color3.new(1, 1, 1)
teleport.Font = Enum.Font.SourceSans
teleport.TextSize = 20
teleport.Parent = frame
Instance.new("UICorner", teleport).CornerRadius = UDim.new(0, 8)

teleport.MouseButton1Click:Connect(function()
	local success, x, y, z = pcall(function()
		return unpack(textbox.Text:split(","))
	end)
	if success then
		hrp.CFrame = CFrame.new(tonumber(x), tonumber(y), tonumber(z))
	end
end)

local Loop = Instance.new("TextButton")
local tpDelay = Instance.new("TextBox")
tpDelay.Text = "Delay"
tpDelay.Size = UDim2.new(0, 60, 0, 20)
tpDelay.Position = UDim2.new(0.5, 15, 1, -23)
tpDelay.TextColor3 = Color3.fromRGB(255, 255, 255)
tpDelay.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
tpDelay.Font = Enum.Font.SourceSans
tpDelay.TextScaled = true
tpDelay.Parent = frame
Instance.new("UICorner", tpDelay).CornerRadius = UDim.new(0, 4)

local tpLoop = Instance.new("TextButton")
tpLoop.Text = "Off"
tpLoop.Size = UDim2.new(0, 20, 0, 20)
tpLoop.Position = UDim2.new(0.5, 90, 1, -23)
tpLoop.BackgroundColor3 = Color3.fromRGB(175, 85, 240)
tpLoop.TextColor3 = Color3.new(1, 1, 1)
tpLoop.Font = Enum.Font.SourceSans
tpLoop.TextScaled = true
tpLoop.Parent = frame
Instance.new("UICorner", tpLoop).CornerRadius = UDim.new(0, 4)

local teleporting = false; local tpthread
tpLoop.MouseButton1Click:Connect(function()
	teleporting = not teleporting
	tpLoop.Text = teleporting and "On" or "Off"

	if teleporting and not tpthread then
		tpthread = task.spawn(function()
			while teleporting do
				local success, x, y, z = pcall(function()
					return unpack(textbox.Text:split(","))
				end)
				if success and tonumber(x) and tonumber(y) and tonumber(z) then
					hrp.CFrame = CFrame.new(tonumber(x), tonumber(y), tonumber(z))
				end
				local delay = tonumber(tpDelay.Text)
				if not delay or delay <= 0 then
					delay = 0.2
				end
				task.wait(delay)
			end
			tpthread = nil
		end)
	end
end)

local loopt = Instance.new("TextButton")
loopt.Text = ">"
loopt.Size = UDim2.new(0, 20, 0, 20)
loopt.Position = UDim2.new(.5, 120, 1, -55)
loopt.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
loopt.TextColor3 = Color3.new(1, 1, 1)
loopt.Font = Enum.Font.SourceSans
loopt.TextSize = 20
loopt.Parent = frame
Instance.new("UICorner", loopt).CornerRadius = UDim.new(0, 6)
