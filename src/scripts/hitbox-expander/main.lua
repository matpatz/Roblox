local players = game["Players"]
local Me = players["LocalPlayer"]

local function apply(p)
    if p ~= Me and p.Character and (not getgenv().teamcheck or p.Team ~= Me.Team) then
        local hrp = p.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            if getgenv().status == "on" then
                hrp.Size = Vector3.new(getgenv().size, getgenv().size, getgenv().size)
                hrp.Transparency = 0.7
                hrp.CanCollide = false
            else
                hrp.Size = Vector3.new(2, 2, 1)
                hrp.Transparency = 1
            end
        end
    end
end

for _, p in ipairs(players:GetPlayers()) do
    apply(p)
    p.CharacterAdded:Connect(function() task.wait(0.1) apply(p) end)
end

players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function() task.wait(0.1) apply(p) end)
end)
