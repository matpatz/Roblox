local Knit = shared.Knit
local services = Knit.services

--// Services
local RunService = services.RunService

--// Variables
local LocalPlayer = services.Players.LocalPlayer
local Events = services.ReplicatedStorage.ReplicatedStorageHolders.Events

--// Events
local AddCoins = Events.AddCoins
local AddXP = Events.AddXP

-- core

local conn
conn = RunService.RenderStepped:Connect(function()
    if not LocalPlayer:GetAttribute("InRound") then
		return
	end
	AddCoins:FireServer(1e6);
	AddXP:FireServer(1e5) -- the max
end)

--conn:Disconnect()
