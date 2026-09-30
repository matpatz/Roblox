--[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]
local rewards = {{"Power", 1e9}, {"x2 Potion", 1e9}}

while task.wait() do
    for i = 1, 25 do
        local reward = rewards[(i % #rewards) + 1]
        game:GetService("ReplicatedStorage").Remotes.ClaimReward:FireServer(reward[1], reward[2])
		--game:GetService("Players").LocalPlayer.Character.Punch.Event:FireServer(2) breaks with a diffrent tool and i dont wanna fix that
		game:GetService("ReplicatedStorage").DailyEvents.ClaimDaily:FireServer()
		game:GetService("ReplicatedStorage").Remotes.ClaimTimePet:InvokeServer(true)
    end
end
