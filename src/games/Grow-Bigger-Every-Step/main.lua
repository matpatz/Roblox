local cup
local highest = 0
for _, model in ipairs(workspace.Folder:GetChildren()) do
    local button = model:FindFirstChild("button1")
    local addCount = button and button:FindFirstChild("AddCount")

    if addCount then
        if addCount.Value > highest then
            highest = addCount.Value
            cup = button
        end
    end
end

local lp = game.Players.LocalPlayer

-- grow
for i = 1, 50 do
    task.spawn(function()
        while task.wait() do
            game:GetService("ReplicatedStorage").GrowCharacter:FireServer()

            if cup then
                local hrp = lp["Character"]["HumanoidRootPart"]
                hrp.CFrame = cup.CFrame

                --local tint = cup:FindFirstChildWhichIsA("TouchTransmitter")
                firetouchinterest(hrp, cup, true); firetouchinterest(hrp, cup, false)
            end
        end
    end)
end
