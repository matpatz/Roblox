local tpd, last = false, nil
game:GetService("RunService").RenderStepped:Connect(function()
	local lp = game.Players.LocalPlayer
	local char = lp.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not (lp and hrp) then return end

	local status = lp.Data:GetAttribute("Status")
	if status ~= "InDuel" and status ~= "InFFA" then return end

	if not char:FindFirstChildWhichIsA("Tool") then
		if not tpd then
			hrp.CFrame = hrp.CFrame * CFrame.new(0, 12, 0)
			tpd = true
		end
	else
		local closest, dist = nil, 9e9
		for _, plr in ipairs(game.Players:GetPlayers()) do
			if plr ~= lp and plr.Character then
				local root = plr.Character:FindFirstChild("HumanoidRootPart")
				local hum = plr.Character:FindFirstChildOfClass("Humanoid")
				if root and hum and hum.Health > 0 and not plr.Character:FindFirstChild("Bomb") then
					local pstatus = plr:FindFirstChild("Data") and plr.Data:GetAttribute("Status")
					if pstatus == "InDuel" or pstatus == "InFFA" then
						if not (status ~= "InDuel" and plr == last) then
							local s, on = workspace.CurrentCamera:WorldToViewportPoint(root.Position)
							if on then
								local rDist = (root.Position - hrp.Position).Magnitude
								if rDist <= 60 then
									local d = Vector2.new(s.X, s.Y) - game:GetService("UserInputService"):GetMouseLocation()
									local mag = d.X * d.X + d.Y * d.Y
									if mag < dist then
										dist = mag
										closest = plr
									end
								end
							end
						end
					end
				end
			end
		end

		if closest and closest.Character and closest.Character:FindFirstChild("HumanoidRootPart") then
			hrp.CFrame = closest.Character.HumanoidRootPart.CFrame
			last = closest
		end
		tpd = false
	end
end)
