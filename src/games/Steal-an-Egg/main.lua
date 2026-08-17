--[[ TODO:
	[+] Auto Place Egg (after finishing a steal)
	[+] Min Egg Size Slider
--]]

print("ran")

-- // Services
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Players = game:GetService("Players")
const TweenService = game:GetService("TweenService")

-- // Modules
const EggCmds = require(ReplicatedStorage.Library.Client.EggCmds)
const AreaEggResetTimeUtil = require(ReplicatedStorage.Library.Util.AreaEggResetTimeUtil)

-- // Events
const RequestHatchEgg = game:GetService("ReplicatedStorage").Network["Eggs: RequestHatchEgg"]
const RequestCompleteHatchEgg = ReplicatedStorage.Network["Eggs: RequestCompleteHatchEgg"]
const RequestAreaEggCarry = game:GetService("ReplicatedStorage").Network["Eggs: RequestAreaEggCarry"]

-- // Workspace
const SpawmPoint = workspace:FindFirstChildWhichIsA("SpawnLocation")
const Eggs = workspace.AreaEggSlotsClient

-- // LocalPlayer
const LocalPlayer = Players.LocalPlayer

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
        AutoPlaceStolenEgg = false,
		BestEgg = {
			Area = "Forest",
			DesireMutations = true,
			MinimumRank = 1
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

-- thank you great and mighty chatgpt
Utils.GetOccupiedEggPositions = function()
    local Occupied = {}
    local Snapshot = EggCmds.GetRuntimeSnapshot()

    for _, Owner in next, Snapshot do
        if Owner.OwnerUserId ~= UserId then
            continue
        end

        for _, Egg in next, Owner.Records do
            if Egg.Placement and Egg.Placement.LocalCFrame then
                Occupied[#Occupied + 1] = Egg.Placement.LocalCFrame
            end
        end
    end

    return Occupied
end

Utils.GetFreeEggPosition = function(Plot, EggRadius)
    local PlacementArea = Plot:FindFirstChild("PlacementArea")

    if not PlacementArea then
        return nil
    end

    local Occupied = Utils.GetOccupiedEggPositions()
    local Size = PlacementArea.Size

    for X = -Size.X / 2, Size.X / 2, EggRadius * 2 do
        for Z = -Size.Z / 2, Size.Z / 2, EggRadius * 2 do
            local LocalPosition = Vector3.new(X, 0, Z)
            local Position = PlacementArea.CFrame:PointToWorldSpace(LocalPosition)

            local Free = true

            for _, CFrame in next, Occupied do
                if (Position - CFrame.Position).Magnitude < EggRadius * 2 then
                    Free = false
                    break
                end
            end

            if Free then
                return CFrame.new(Position)
            end
        end
    end

    return nil
end

Core.PlaceEgg = function(Uid: string)
    local CFrame = Utils.GetFreeEggPosition()

    if not CFrame then
        return false
    end

    local Success = EggCmds.RequestPlaceEgg(Uid, CFrame)

    return Success == true
end

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
    local MinRank = Options.MinimumRank
    local BestEgg
    local BestRank = -math.huge

    for _, Egg in next, (EggCmds.GetAreaEggSnapshot().Records) do
        if Egg.State ~= "Slot" then
            continue
        end

        local EggRank = Zones[Egg.AreaId] or 0

        if Area ~= "Random" and Egg.AreaId ~= Area then
            continue
        end

        if Area == "Random" and EggRank < MinRank then
            continue
        end

        local Rank = EggRank

        if DesireMutations then
            if #Egg.Mutations > 0 then
                Rank += 100
            else
                Rank -= 100
            end
        end

        if Rank > BestRank then
            local Instance = Eggs:FindFirstChild(Egg.Uid)

            if Instance then
                BestRank = Rank
                BestEgg = Instance
            end
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
    print("exists")
	if not Utils.VerifySteal() then
        print("fail check")
        return false
	end

	local Egg = Utils.GetBestEgg(Options):WaitForChild("Hitbox")
	if not Egg then
        print("no egg")
		return false
	end
    print("name")
	local Name = Egg.Parent.Name

    print("tween egg")
	Utils.TweenTo(Egg)
	task.wait(.15)

    print("if then else")
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

    print("pre tween")
	Utils.TweenTo(SpawmPoint)
    print("after")

    print(config.Eggs.AutoPlaceStolenEgg)
    if config.Eggs.AutoPlaceStolenEgg then
        print("yes")
        Core.PlaceEgg(Name)
    end

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
            while Flags.AutoStealEgg.CurrentValue do
                Core.StealBestEgg(config.Eggs.BestEgg)
                task.wait(.2)
            end
        end)
    end,
})

tabs.Eggs:CreateButton({
    Name = "Steal Egg",
    Callback = function()
        print("called")
		Core.StealBestEgg(config.Eggs.BestEgg)
    end,
})

tabs.Eggs:CreateToggle({
    Name = "Auto Place Stolen Egg",
    CurrentValue = false,
    Flag = "AutoPlaceStolenEgg",
    Callback = function(Value)
        config.Eggs.AutoPlaceStolenEgg = Value
    end,
})

tabs.Eggs:CreateDivider()

tabs.Eggs:CreateToggle({
    Name = "Desire Mutations",
    CurrentValue = true,
    Flag = "DesireMutations",
    Callback = function(Value)
		config.Eggs.BestEgg.DesireMutations = Value
    end,
})

tabs.Eggs:CreateSlider({
    Name = "Minimum Zone Rank",
    Range = {1, 9},
    Increment = 1,
    Suffix = "",
    CurrentValue = config.Eggs.BestEgg.MinimumRank,
    Flag = "MinEggRank",
    Callback = function(Value)
        config.Eggs.BestEgg.MinimumRank = Value
    end
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
            while Flags.AutoHatchEggs.CurrentValue do
                Core.HatchEggs()
                task.wait(.2)
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
