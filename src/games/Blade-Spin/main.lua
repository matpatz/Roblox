local LocalPlayer = game:GetService("Players").LocalPlayer
local Events = game:GetService("ReplicatedStorage").ReplicatedStorageHolders.Events

local AddCoins = Events.AddCoins
local AddXP = Events.AddXP

local conn
conn = game:GetService("RunService").RenderStepped:Connect(function()
    if not LocalPlayer:GetAttribute("InRound") then
		return
	end
	AddCoins:FireServer(1e6);
	AddXP:FireServer(1e5) -- the max
end)

--conn:Disconnect()
