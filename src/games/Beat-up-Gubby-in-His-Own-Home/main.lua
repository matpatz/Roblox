--[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]
local rep = game:GetService("ReplicatedStorage")
local re = rep.Networking.Server.RemoteEvents

while task.wait() do
    for i = 1, game:GetService("Stats").Workspace.FPS:GetValue() / 7 do
        local inv = rep.PlayerData[game:GetService("Players").LocalPlayer.Name].Inventory.OwnedActions
		if not inv:FindFirstChild("SlapHand") then re.PurchaseAction:FireServer("SlapHand") else re.DamageEvents.SlapDamage:FireServer(Vector3.new()) re.DamageEvents.PhysicsDamage:FireServer(115, Vector3.new()) end
    end
end
