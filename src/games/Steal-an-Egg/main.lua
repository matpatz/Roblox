-- // Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- // Modules
local AreaEggResetTimeUtil = require(ReplicatedStorage.Library.Util.AreaEggResetTimeUtil)

-- // Events
local RequestHatchEgg = game:GetService("ReplicatedStorage").Network["Eggs: RequestHatchEgg"]
local RequestCompleteHatchEgg = ReplicatedStorage.Network["Eggs: RequestCompleteHatchEgg"]
local RequestAreaEggCarry = game:GetService("ReplicatedStorage").Network["Eggs: RequestAreaEggCarry"]

-- // Workspace
local SpawmPoint = workspace:FindFirstChildWhichIsA("SpawnLocation")
local Eggs = workspace.AreaEggSlotsClient

-- // LocalPlayer

local LocalPlayer = Players.LocalPlayer

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

-- // cheat
local cheat = {
	Utils = {

	},
	Core = {

	}
}
local Utils = cheat.Utils
local Core = cheat.Core

-- // Utils
Utils.GetBestEgg = function()
	local Egg = Eggs:GetChildren()[1]
	if not Egg then
		return false
	end
	return Egg
end

Utils.IsNight = function()
	local Time = workspace:GetServerTimeNow()
	return AreaEggResetTimeUtil.IsNight(Time)
end

-- for a larger script it would have other checks
Utils.VerifySteal = function()
	local Night = Utils.IsNight()
	if Night then
		return false
	end
	return true
end

Utils.TweenTo = function(Area: Instance)
	local Distance = (HumanoidRootPart.Position - Area.Position).Magnitude
	local Duration = Distance / Humanoid.WalkSpeed

	local Tween = TweenService:Create(HumanoidRootPart, TweenInfo.new(Duration, Enum.EasingStyle.Linear), {
		CFrame = Area.CFrame
	})

	Tween:Play()
	Tween.Completed:Wait()
end

Core.StealBestEgg = function()
	if not Utils.VerifySteal() then
		return false
	end

	local Egg = Utils.GetBestEgg():WaitForChild("Hitbox")
	if not Egg then
		return false
	end

	Utils.TweenTo(Egg)
	task.wait(.15)

	RequestAreaEggCarry:InvokeServer(
		{
			FirstAreaSlotKey = "Forest:Slot_002", -- only matters for the first stage but the server accepts it no matter what
			Uid = Egg.Parent.Name
		}
	)

	task.wait(.25)

	Utils.TweenTo(SpawmPoint)

	return true
end

Core.HatchEgg = function(Egg: Instance)
	local Id = Egg.Name -- also exists as an attribute
	RequestHatchEgg:InvokeServer(
		Id
	); task.wait(0.5) -- not sure
	RequestCompleteHatchEgg:InvokeServer(
		Id
	)
end

Core.StealBestEgg()
