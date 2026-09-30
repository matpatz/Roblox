local ReplicatedStorage = game:GetService("ReplicatedStorage")

while task.wait() do 
    ReplicatedStorage.Event.Train:FireServer(1e16) 
    ReplicatedStorage.Event.WinGain:FireServer(1e16) 
    ReplicatedStorage.Event.Enchanted:FireServer(0, 0.15) 
    ReplicatedStorage.Event.BuyPower:FireServer("Gust", 0) 
end
