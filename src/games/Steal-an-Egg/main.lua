-- // Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- // Modules
local EggCmds = require(ReplicatedStorage.Library.Client.EggCmds)
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

--// locals
const UserId = LocalPlayer.UserId
local Flags = {}

-- // config
local config = {
	Eggs = {
		BestEgg = {
			Area = "Forest",
			DesireMutations = true
		}
	}
}

-- // cheat
local cheat = {
	Utils = {

	},
	Core = {

	}
}
local Utils = cheat.Utils
local Core = cheat.Core

const Zones = {
    ["Cosmic"] = 9,
    ["Prehistoric"] = 8,
    ["Abyss Ocean"] = 7,
    ["Volcano"] = 6,
    ["Snow"] = 5,
    ["Jungle"] = 4,
    ["Desert"] = 3,
    ["Lake"] = 2,
    ["Forest"] = 1,
	["Random"] = 0
}

-- // Utils
Utils.GetBestEgg = function(Options)
    local Area = Options.Area
    local DesireMutations = Options.DesireMutations == true
    local BestEgg
    local BestRank = -math.huge

    for _, Egg in next, (EggCmds.GetAreaEggSnapshot().Records) do
		if Egg.State ~= "Slot" then
			continue
		end
		if Area ~= "Random" then
			if Egg.AreaId ~= Area then
				continue
			end
		end

		local Rank = Zones[Area] or 0

		if DesireMutations then
			if #Egg.Mutations > 0 then
				Rank += 100
			else
				Rank -= 100
			end
		end

		if Rank > BestRank then
			BestRank = Rank
			BestEgg = Eggs:FindFirstChild(Egg.Uid)
		end
    end

    return BestEgg
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
	local Duration = Distance / (Humanoid.WalkSpeed * 1.1)

	local Tween = TweenService:Create(HumanoidRootPart, TweenInfo.new(Duration, Enum.EasingStyle.Linear), {
		CFrame = Area.CFrame
	})

	Tween:Play()
	Tween.Completed:Wait()
end

local function GetSlot(Name: string)
    return Name:match("([^_]+:.-)$")
end

Core.StealBestEgg = function(Options)
	if not Utils.VerifySteal() then
		return false
	end

	local Egg = Utils.GetBestEgg(Options):WaitForChild("Hitbox")
	if not Egg then
		return false
	end
	local Name = Egg.Parent.Name

	Utils.TweenTo(Egg)
	task.wait(.15)

	if Name:find("FirstAreaEgg") then
		RequestAreaEggCarry:InvokeServer(
			{
				FirstAreaSlotKey = GetSlot(Name),
				Uid = Name
			}
		)
	else
		RequestAreaEggCarry:InvokeServer(
			{
				Uid = Name
			}
		)
	end

	task.wait(.25)

	Utils.TweenTo(SpawmPoint)

	return true
end

Utils.HatchEgg = function(Uid: string)
	RequestHatchEgg:InvokeServer(
		Uid
	); task.wait(0.5) -- not sure
	RequestCompleteHatchEgg:InvokeServer(
		Uid
	)
end

Core.HatchEggs = function()
	const Snapshot = EggCmds.GetRuntimeSnapshot()

	for _, Owner in next, (Snapshot) do
		if Owner.OwnerUserId ~= UserId then
			continue
		end
		for Uid, Egg in next, (Owner.Records) do
			if Egg.Placement and EggCmds.IsLocalEggReady(Uid) then
				Utils.HatchEgg(Uid)
			end
		end
	end
	return true
end

-- // Interface

local Rayfield = loadstring(game:HttpGet("https://voltex.website/libraries/Rayfield/main.lua"))()
Flags = Rayfield.Flags

local Window = Rayfield:CreateWindow({
    Name = "Steal an Egg",
    LoadingTitle = "Loading...",
    LoadingSubtitle = "subtitle",
})

local tabs = {
    Eggs = Window:CreateTab("Eggs"),
    Pen = Window:CreateTab("Pen"),
}

-- // Eggs

tabs.Eggs:CreateDropdown({
    Name = "Zone",
    Options = {
        "Cosmic",
        "Prehistoric",
        "Abyss Ocean",
        "Volcano",
        "Snow",
        "Jungle",
        "Desert",
        "Lake",
        "Forest",
		"Random"
    },
    CurrentOption = {config.Eggs.BestEgg.Area},
    MultipleOptions = false,
    Flag = "EggZone",
    Callback = function(Option)
        config.Eggs.BestEgg.Area = Option[1]
    end
})

tabs.Eggs:CreateToggle({
    Name = "Auto Steal Egg",
    CurrentValue = false,
    Flag = "AutoStealEgg",
    Callback = function(Value)
        if not Value then
            return
        end

        task.spawn(function()
            while Value do
                if Core.StealBestEgg(config.Eggs.BestEgg) then
                    task.wait(.2)
                else
                    task.wait()
                end
            end
        end)
    end,
})

tabs.Eggs:CreateButton({
    Name = "Steal Egg",
    Callback = function()
		Core.StealBestEgg(config.Eggs.BestEgg)
    end,
})

-- // Pen
tabs.Pen:CreateToggle({
    Name = "Auto Hatch all Eggs",
    CurrentValue = false,
    Flag = "AutoHatchEggs",
    Callback = function(Value)
        if not Value then
            return
        end

        task.spawn(function()
            while Value do
                if Core.HatchEggs() then
                    task.wait(.2)
                else
                    task.wait()
                end
            end
        end)
    end,
})

tabs.Pen:CreateButton({
    Name = "Hatch all Eggs",
    Callback = function()
		Core.HatchEggs()
    end,
})
