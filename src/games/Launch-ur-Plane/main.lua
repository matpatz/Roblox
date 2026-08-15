--[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]
while task.wait() do for i = 1, 10 do game:GetService("ReplicatedStorage").Remotes.FlightComplete:FireServer({money = 1e16, distance = 1e16, landed = true}) end end
