--// Services
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Players = game:GetService("Players")

-- // Modules
local LeafSim
--  local MapRegistry = require(ReplicatedStorage.MapRegistry)

--// Events
const EmptyBackpack = ReplicatedStorage.Remotes.EmptyBackpack

-- // Workspace
const Leaves = workspace:WaitForChild("Leaves", 10)
-- const Leave_Locations = MapRegistry.get("Leave_Locations", 10)

-- // LocalPlayer
const LocalPlayer = Players.LocalPlayer
const PlayerScripts = LocalPlayer.PlayerScripts

if not LocalPlayer.Character then
	LocalPlayer.CharacterAdded:Wait()
end
local Character = LocalPlayer.Character
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

LocalPlayer.CharacterAdded:Connect(function(NewCharacter)
	Character = NewCharacter
	HumanoidRootPart = NewCharacter:WaitForChild("HumanoidRootPart")
	Humanoid = NewCharacter:WaitForChild("Humanoid")
end)

LeafSim = require(PlayerScripts.LeafSim) -- yk

-- // cheat
local cheat = {
	Utils = {

	},
	Core = {

	}
}
local Utils = cheat.Utils
local Core = cheat.Core

function Utils.Sell()
    EmptyBackpack:FireServer()
end

function Utils.Claim(Leaf)
    task.wait(0.15)
	LeafSim.collect(Leaf)
end

function Core.ClaimAll()
	for _, Leaf in next, Leaves:GetChildren() do
		Utils.Sell()
		
		Utils.Claim(Leaf)
	end
end

Core.ClaimAll()