--[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]
local player = game.Players.LocalPlayer

local answs = {}
local guessesFolder = player.PlayerGui:WaitForChild(player:GetAttribute("Level")):WaitForChild("1"):WaitForChild("Left"):WaitForChild("ZoomViewport"):WaitForChild("Content"):WaitForChild("guesses")

for _, child in ipairs(guessesFolder:GetChildren()) do
    if string.match(child.Name, "^guess_%d+$") or string.find(child.Name, "guess") then
        table.insert(answs, child)
    end
end

for i, obj in ipairs(answs) do
    print(i, obj.Name)

	local drawing = Drawing.new("Circle")
	drawing.Visible = true
	drawing.Filled = false
	drawing.Color = Color3.new(0, 0, 0)
	drawing.Thickness = 2
	drawing.Radius = obj.AbsoluteSize.X / 2
	drawing.Position = Vector2.new(obj.AbsolutePosition.X + obj.AbsoluteSize.X / 2, obj.AbsolutePosition.Y + obj.AbsoluteSize.Y / 2)

	if getconnections then
		local connections = getconnections(obj.MouseButton1Click)
		for _, connection in pairs(connections) do connection:Fire() end
	end
end
