--[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]
local players,drawings = game:GetService("Players"), {}

game:GetService("RunService").RenderStepped:Connect(function()
	for i, player in ipairs(players:GetPlayers()) do
		if player ~= players.LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
			local head = player.Character.Head
			local pos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(head.Position + Vector3.new(0, 2, 0))

			if not drawings[player] then
				local text = Drawing.new("Text")
				text.Center = true
				text.Outline = true
				text.Size = 16
				text.Color = Color3.new(1, 1, 1)
				drawings[player] = text
			end

			local text = drawings[player]
			if onScreen then
				text.Text = "[ " .. player.Name .. " | " .. player.AccountAge .. "d ]"
				text.Position = Vector2.new(pos.X, pos.Y)
				text.Visible = true
			else
				text.Visible = false
			end
		elseif drawings[player] then
			drawings[player].Visible = false
		end
	end
end)

players.PlayerRemoving:Connect(function(player)
	if drawings[player] then
		drawings[player]:Remove()
		drawings[player] = nil
	end
end)
