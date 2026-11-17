--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

--// Evemts
local Events = ReplicatedStorage.Shared.Packages.TypedRemote

local Train = Events.TrainingTap

--// modules
local ClientControllers = LocalPlayer.PlayerScripts.ClientControllers

local TapInput = require(ClientControllers.TrainingController.TapInput)

local function train()
	TapInput.SendTap()
end

local keys = {
	["autotrain"] = train,
}

while task.wait() do
	for i, v in keys do
		if not getgenv()[i] then
			continue
		end
		pcall(v)
	end
end