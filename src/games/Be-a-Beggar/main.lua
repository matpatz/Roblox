--[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]
_G.af = not _G.af
-- _G.ag = not _G.ag

local rep = game:GetService("ReplicatedStorage")

while _G.af do
    if _G.af then
		local fps = game:GetService("Stats").Workspace.FPS:GetValue()
        for i = 1, fps do rep.Remotes.MinigameEvent:FireServer(true) end -- less lag

		if firesignal then
			for i, v in pairs(game:GetService("Players").LocalPlayer.PlayerGui.Main.Minigame:GetChildren()) do
				if v.Name ~= "Red" and v.Name ~= "Circle" then
					firesignal(v.MouseButton1Click)
				end
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

    task.wait()
end
