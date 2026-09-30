local rewards = {{"Power", 1e9}, {"x2 Potion", 1e9}}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

while task.wait() do
    for i = 1, 25 do
        local reward = rewards[(i % #rewards) + 1]
        ReplicatedStorage.Remotes.ClaimReward:FireServer(reward[1], reward[2])
		--game:GetService("Players").LocalPlayer.Character.Punch.Event:FireServer(2) breaks with a diffrent tool and i dont wanna fix that
		ReplicatedStorage.DailyEvents.ClaimDaily:FireServer()
		ReplicatedStorage.Remotes.ClaimTimePet:InvokeServer(true)
    end
end
