getgenv().autowin = getgenv().autowin or true
getgenv().infmoney = getgenv().infmoney or false

local Services = game:GetService("ReplicatedStorage").Packages._Index["sleitnick_knit@1.5.1"].knit.Services
local path = workspace.Areas:FindFirstChildWhichIsA("Folder")
while getgenv().autowin do
    task.wait(0.6)

    Services.FightService.RE.JoinContest:FireServer(path.Name)
    for i, gate in ipairs(path.WinGates:GetChildren()) do
        Services.FightService.RE.GetWinsEvent:FireServer("WinGate_" .. tostring(i), gate:FindFirstChild("gate").Position)
    end
    Services.FightService.RE.QuitContestEvent:FireServer(path.Name)
end

if getgenv().infmoney then Services.RandomPotionService.RE.BuyPotionEvent:FireServer(table.unpack({[1] = -1e64, [2] = {}, [3] = true, [4] = "yippie!", })) end
