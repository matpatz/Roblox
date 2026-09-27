local Players = game:GetService("Players")
local Drawings = {}

game:GetService("RunService").PreRender:Connect(function()
	for i, player in ipairs(Players:GetPlayers()) do
		if player ~= players.LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
			local head = player.Character.Head
			local pos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(head.Position + Vector3.new(0, 2, 0))

			if not Drawings[player] then
				local text = Drawing.new("Text")
				text.Center = true
				text.Outline = true
				text.Size = 16
				text.Color = Color3.new(1, 1, 1)
				Drawings[player] = text
			end

			local text = Drawings[player]
			if onScreen then
				text.Text = "[ " .. player.Name .. " | " .. player.AccountAge .. "d ]"
				text.Position = Vector2.new(pos.X, pos.Y)
				text.Visible = true
			else
				text.Visible = false
			end
		elseif Drawings[player] then
			Drawings[player].Visible = false
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	if Drawings[player] then
		Drawings[player]:Remove()
		Drawings[player] = nil
	end
end)
