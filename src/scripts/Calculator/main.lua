--[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]
local gui = Instance.new("ScreenGui", gethui() or game.CoreGui)
gui.Name = "e" .. math.random(1e9, 2e9)
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 360, 0, 500)
frame.Position = UDim2.new(0.5, -180, 0.5, -250)
frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

local corner = Instance.new("UICorner", frame)
corner.CornerRadius = UDim.new(0, 10)

local close = Instance.new("TextButton", frame)
close.Size = UDim2.new(0, 28, 0, 28)
close.Position = UDim2.new(1, -34, 0, 6)
close.Text = "X"
close.BackgroundColor3 = Color3.fromRGB(120, 30, 30)
close.TextColor3 = Color3.new(1, 1, 1)
close.Font = Enum.Font.SourceSansBold
close.TextScaled = true

local closeCorner = Instance.new("UICorner", close)
closeCorner.CornerRadius = UDim.new(0, 6)

close.MouseButton1Click:Connect(function()
	gui:Destroy()
end)

local display = Instance.new("TextLabel", frame)
display.Size = UDim2.new(1, -20, 0, 50)
display.Position = UDim2.new(0, 10, 0, 40)
display.Text = ""
display.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
display.TextColor3 = Color3.fromRGB(0, 0, 0)
display.Font = Enum.Font.Code
display.TextXAlignment = Enum.TextXAlignment.Right
display.TextSize = 20
display.BorderSizePixel = 0
display.ClipsDescendants = true

local layout = {
	{"2nd", "DRG", "DEL"},
	{"LOG", "PRB", "o", "'", "\""},
	{"LN", "Ab/c", "DATA", "STARVAR", "CLEAR"},
	{"π", "SIN", "COS", "TAN", "÷"},
	{"^", "x⁻¹", "(", ")", "×"},
	{"x²", "7", "8", "9", "−"},
	{"MEMVAR", "4", "5", "6", "+"},
	{"STO>", "1", "2", "3", "="},
	{"ON", "0", ".", "(−)"}
}

local startX, startY = 10, 100
local spacing = 5
local btnHeight = 36
local maxRow = 5
local btnWidth = (frame.AbsoluteSize.X - (startX * 2) - (spacing * (maxRow - 1))) / maxRow

-- they expect radians
local function dsin(x) return math.sin(math.rad(x)) end
local function dcos(x) return math.cos(math.rad(x)) end
local function dtan(x) return math.tan(math.rad(x)) end

local function evaluate()
	local success, result = pcall(function()
		local expr = display.Text
		expr = expr:gsub("π", tostring(math.pi))
		expr = expr:gsub("÷", "/")
		expr = expr:gsub("×", "*")
		expr = expr:gsub("−", "-")
		expr = expr:gsub("x²", "^2")
		expr = expr:gsub("x⁻¹", "1/")
		expr = expr:gsub("SIN", "_dsin")
		expr = expr:gsub("COS", "_dcos")
		expr = expr:gsub("TAN", "_dtan")
		expr = expr:gsub("LOG", "_log10")
		expr = expr:gsub("LN", "math.log")
		local env = setmetatable({
			_dsin = dsin,
			_dcos = dcos,
			_dtan = dtan,
			_log10 = math.log10 or function(x) return math.log(x, 10) end,
			math = math,
		}, { __index = _G })
		local fn = loadstring("return " .. expr)
		setfenv(fn, env)
		return fn()
	end)
	display.Text = success and tostring(result) or "Error"
end

for rowIndex, row in ipairs(layout) do
	for colIndex, text in ipairs(row) do
		local x = startX + (btnWidth + spacing) * (colIndex - 1)
		local y = startY + (btnHeight + spacing) * (rowIndex - 1)

		local btn = Instance.new("TextButton", frame)
		btn.Position = UDim2.new(0, x, 0, y)
		btn.Size = UDim2.new(0, btnWidth, 0, btnHeight)
		btn.Text = text
		btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		btn.TextColor3 = Color3.new(1, 1, 1)
		btn.Font = Enum.Font.SourceSansBold
		btn.TextScaled = true
		btn.TextWrapped = true

		local btnCorner = Instance.new("UICorner", btn)
		btnCorner.CornerRadius = UDim.new(0, 6)

		btn.MouseButton1Click:Connect(function()
			if text == "CLEAR" then
				display.Text = ""
			elseif text == "DEL" then
				display.Text = display.Text:sub(1, -2)
			elseif text == "=" then
				evaluate()
			elseif text == "SIN" or text == "COS" or text == "TAN" or text == "LOG" or text == "LN" then
				display.Text = display.Text .. text .. "("
			else
				display.Text = display.Text .. text
			end
		end)
	end
end

game:GetService("UserInputService").InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.UserInputType == Enum.UserInputType.Keyboard then
		local k = input.KeyCode
		if k == Enum.KeyCode.Backspace then
			display.Text = display.Text:sub(1, -2)
		elseif k == Enum.KeyCode.Return or k == Enum.KeyCode.KeypadEnter then
			evaluate()
		elseif k.Value:match("[%w]") or k == Enum.KeyCode.Period then
			display.Text = display.Text .. k.Name
		end
	end
end)