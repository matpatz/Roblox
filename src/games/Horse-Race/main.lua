getgenv().autowin = getgenv().autowin or false
getgenv().infmoney = getgenv().infmoney or true

local path = workspace.Areas:FindFirstChildWhichIsA("Model")
while getgenv().autowin do
    task.wait(0.6)

    game:GetService("ReplicatedStorage").Packages._Index["sleitnick_knit@1.5.1"].knit.Services.FightService.RE.JoinContest:FireServer(path.Name)
    for i, gate in ipairs(path.WinGates:GetChildren()) do
        game:GetService("ReplicatedStorage").Packages._Index["sleitnick_knit@1.5.1"].knit.Services.FightService.RE.GetWinsEvent:FireServer("WinGate_" .. tostring(i), gate:FindFirstChild("gate").Position)
    end
    game:GetService("ReplicatedStorage").Packages._Index["sleitnick_knit@1.5.1"].knit.Services.FightService.RE.QuitContestEvent:FireServer(path.Name)
end

if getgenv().infmoney then game:GetService("ReplicatedStorage").Packages._Index["sleitnick_knit@1.5.1"].knit.Services.RandomPotionService.RE.BuyPotionEvent:FireServer(table.unpack({[1] = -1e64, [2] = {}, [3] = true, [4] = "yippie!", })) end
