local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteEvents = ReplicatedStorage.Networking.Server.RemoteEvents

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

while task.wait() do
    for i = 1, 25 do
        local inv = ReplicatedStorage.PlayerData[LocalPlayer.Name].Inventory.OwnedActions
		if not inv:FindFirstChild("SlapHand") then
            RemoteEvents.PurchaseAction:FireServer("SlapHand")
        else
            RemoteEvents.DamageEvents.SlapDamage:FireServer(Vector3.new())
            RemoteEvents.DamageEvents.PhysicsDamage:FireServer(115, Vector3.new())
        end
    end
end
