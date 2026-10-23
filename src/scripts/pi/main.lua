local pi = game:HttpGet("https://nineplanets.org/billion-pi.txt")

local cloneref = cloneref or function(x)
    return x
end

local CoreGui = game:GetService("CoreGui")

local CHUNK_SIZE = (200000 - 1) -- 200000 max char limit on TextLabels

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "uw and wu"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local ScrollingFrame = Instance.new("ScrollingFrame")
ScrollingFrame.AnchorPoint = Vector2.new(0.5, 0.5)
ScrollingFrame.Position = UDim2.fromScale(0.5, 0.5)
ScrollingFrame.Size = UDim2.fromScale(0.8, 0.8)
ScrollingFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ScrollingFrame.CanvasSize = UDim2.new()
ScrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
ScrollingFrame.ScrollBarThickness = 8
ScrollingFrame.Parent = ScreenGui

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Parent = ScrollingFrame

local pos = 1
local index = 0

while pos <= #pi do
	local nextPos = utf8.offset(pi, CHUNK_SIZE + 1, pos) or (#pi + 1)

	index += 1
	local label = Instance.new("TextLabel")
	label.Name = "Chunk" .. index
	label.LayoutOrder = index
	label.Size = UDim2.fromScale(1, 0)
	label.AutomaticSize = Enum.AutomaticSize.Y  -- grows to fit the text
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextSize = 14
	label.Font = Enum.Font.Code
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.Text = string.sub(pi, pos, nextPos - 1)
	label.Parent = ScrollingFrame

	pos = nextPos

	if index % 5 == 0 then
		task.wait()
	end
end

print("Created", index, "labels")