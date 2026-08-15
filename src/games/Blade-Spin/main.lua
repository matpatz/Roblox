--[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]
local conn; local player = game:GetService("Players").LocalPlayer
conn = game:GetService("RunService").RenderStepped:Connect(function(dt)
    if player:GetAttribute("InRound") == true then
        game:GetService("ReplicatedStorage").ReplicatedStorageHolders.Events.AddCoins:FireServer(1e6); game:GetService("ReplicatedStorage").ReplicatedStorageHolders.Events.AddXP:FireServer(1e5)
    end
end)

--conn:Disconnect()
