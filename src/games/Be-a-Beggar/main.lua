getgenv().Autofarm = true

local Knit = shared.Knit
local services = Knit.services

local ReplicatedStorage = services.ReplicatedStorage
local Stats = services.Stats

local LocalPlayer = services.Players.LocalPlayer
local PlaerGui = LocalPlayer.PlayerGui

local Minigame = PlayerGui.Main.Minigame

while task.wait() do
	if not getgenv().Autofarm then
		continue
	end

	local FPS = Stats.Workspace.FPS:GetValue()
	for i = 1, FPS do
		ReplicatedStorage.Remotes.MinigameEvent:FireServer(true)
	end

	if firesignal then
		for i, v in next Minigame:GetChildren() do
			if v.Name ~= "Red" and v.Name ~= "Circle" then
				firesignal(v.MouseButton1Click)
			end
		end
	end
	--[[
	local Upgrade = rep.Remotes.Upgrade
	local upgrades = {"Beg Power", "Income", "Box Tier", "Alley Tier"}

	local uIndex = 1
	while _G.ag do
		Upgrade:FireServer(upgrades[upgradeIndex])

		upgradeIndex = upgradeIndex + 1
		if upgradeIndex > #upgrades then
			upgradeIndex = 1
		end
		task.wait(1)
	end --]]
end
