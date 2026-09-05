local gui = Instance.new("ScreenGui")
gui.Name = "e" .. math.random(1e9, 2e9)
gui.ResetOnSpawn = false
gui.Parent = gethui() or game.CoreGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 520, 0, 320)
frame.Position = UDim2.new(0.3, 0, 0.2, 0)
frame.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
frame.Active = true
frame.Draggable = true
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.Text = "Executor"
title.Size = UDim2.new(1, -40, 0, 30)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

local close = Instance.new("TextButton")
close.Text = "X"
close.Size = UDim2.new(0, 30, 0, 30)
close.Position = UDim2.new(1, -30, 0, 0)
close.BackgroundTransparency = 1
close.TextColor3 = Color3.fromRGB(255, 60, 60)
close.Parent = frame
close.MouseButton1Click:Connect(function() gui:Destroy() end)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(0.94, 0, 0.70, 0)
scroll.Position = UDim2.new(0.03, 0, 0.12, 0)
scroll.CanvasSize = UDim2.new(0, 0, 3, 0)
scroll.ScrollBarThickness = 6
scroll.BorderSizePixel = 0
scroll.BackgroundColor3 = Color3.fromRGB(35,35,35)
scroll.Parent = frame
Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, 6)

local textbox = Instance.new("TextBox")
textbox.Size = UDim2.new(1, -10, 3, 0)
textbox.Position = UDim2.new(0, 5, 0, 0)
textbox.MultiLine = true
textbox.ClearTextOnFocus = false
textbox.TextWrapped = false
textbox.TextYAlignment = Enum.TextYAlignment.Top
textbox.TextXAlignment = Enum.TextXAlignment.Left
textbox.Font = Enum.Font.Code
textbox.TextSize = 14
textbox.TextColor3 = Color3.new(1,1,1)
textbox.BackgroundTransparency = 1
textbox.Text = " -- enter code here"
textbox.Parent = scroll

local execute = Instance.new("TextButton")
execute.Size = UDim2.new(0, 120, 0, 30)
execute.Position = UDim2.new(0.03, 0, 0.85, 0)
execute.Text = "Execute"
execute.Font = Enum.Font.GothamBold
execute.TextSize = 12
execute.TextColor3 = Color3.new(1,1,1)
execute.BackgroundColor3 = Color3.fromRGB(60,60,60)
execute.Parent = frame
Instance.new("UICorner", execute).CornerRadius = UDim.new(0, 5)

execute.MouseButton1Click:Connect(function()
	local success, func = pcall(loadstring, textbox.Text)

	if success and func then
		local ran, err = pcall(func)

		if not ran then
			textbox.Text = "Runtime error: " .. tostring(err)
		end
	else
		textbox.Text = "Compile error: " .. tostring(func)
	end
end)
