local required = 1
game:GetService("ReplicatedStorage").Remotes.StatsUpdated.OnClientEvent:Connect(function(data)
    required = data.XPRequired
end)

local function fire(tofire)
    game:GetService("ReplicatedStorage").Remotes.StepTaken:FireServer(
        tofire, -- steps moved / xp granted
        false -- is on the road
        -- roadid
    )
end

fire(required)
task.spawn(function()
    while task.wait() do
        fire(required)
    end
end)

