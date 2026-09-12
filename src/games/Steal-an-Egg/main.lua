--[[ TODO:
	[+] Min Egg Size Slider
--]]

-- // Services
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Players = game:GetService("Players")
const TweenService = game:GetService("TweenService")
const RunService = game:GetService("RunService")

-- // Modules
const Remotes = require(ReplicatedStorage.Shared.Remotes)
const EggState = require(ReplicatedStorage.Client.EggState)
const PlotState = require(ReplicatedStorage.Client.PlotState)
const AreaEggCycle = require(ReplicatedStorage.Shared.Util.AreaEggCycle)
const AreaEggSlotIdentity = require(ReplicatedStorage.Shared.Util.AreaEggSlotIdentity)
const EggToolDisplay = require(ReplicatedStorage.Shared.Eggs.EggToolDisplay)
const Trails = require(ReplicatedStorage.Data.Trails)

const Anticheat = loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/games/Steal-an-Egg/bypass.lua"))()

-- // Workspace
const SpawmPoint = workspace:FindFirstChildWhichIsA("SpawnLocation")

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

--// variables
const UserId = LocalPlayer.UserId
local Flags = {}
Flags.__index = Flags

--const Trails = ReplicatedStorage.Directory.Trails._Index

local OnTreadmill = false
Remotes.Treadmill.RenderStateShifted.OnClientEvent:Connect(function(Player, Active)
    if Player == LocalPlayer then
        OnTreadmill = Active
    end
end)

-- // config
local config = {
    AnticheatBypass = true,

	Eggs = {
		BestEgg = {
			Area = "Forest",
			DesireMutations = true,
			MinimumRank = 1,
			MaximumRank = 10
		},
		EggRadius = 2,
		AutoPlace = false
	},
    Shop = {
        Trail = {
            Selected = "GreenTrail"
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

-- A steal only keeps the egg carried for about a second before the game drops it -- but the egg
-- lands in your inventory as an owned, unplaced record, and PlantEgg expects *that* record's
-- Uid (the field egg's Uid is not a plantable identity).
Utils.GetUnplacedEggUid = function()
    for _, Owner in next, EggState.ReadOwnedEggs() do
        if Owner.OwnerUserId ~= UserId then
            continue
        end

        for Uid, Egg in next, Owner.Records do
            if not Egg.Placement then
                return Uid
            end
        end
    end

    return nil
end

Utils.WaitForUnplacedEggUid = function(Timeout: number)
    local Deadline = os.clock() + (Timeout or 3)

    repeat
        local Uid = Utils.GetUnplacedEggUid()

        if Uid then
            return Uid
        end

        task.wait(.1)
    until os.clock() >= Deadline

    return nil
end

-- Where to stand to steal an egg: next to it, never on top of it. Landing on the egg makes the
-- physics engine eject and ragdoll the character, and the server refuses the carry until it gets up
Utils.GetEggStandCFrame = function(Egg, Angle)
    local Radius = math.max(Egg.BoundsSize.X, Egg.BoundsSize.Z) / 2 + 5
    local Direction = (Egg.BoundsCFrame * CFrame.Angles(0, Angle or 0, 0)).LookVector

    return CFrame.lookAt(Egg.BottomCFrame.Position + Direction * Radius, Egg.BoundsCFrame.Position)
end

-- The server also refuses the carry while the character is airborne or knocked down
Utils.CanCarryEgg = function()
    if Humanoid == nil or Humanoid.FloorMaterial == Enum.Material.Air then
        return false
    end

    local State = Humanoid:GetState()

    return State ~= Enum.HumanoidStateType.Physics
        and State ~= Enum.HumanoidStateType.GettingUp
        and State ~= Enum.HumanoidStateType.FallingDown
        and State ~= Enum.HumanoidStateType.Ragdoll
end

-- thank you great and mighty chatgpt
Utils.GetOccupiedEggPositions = function()
    local Occupied = {}
    local Snapshot = EggState.ReadOwnedEggs()

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

Utils.GetFreeEggPositions = function(Plot, EggRadius, CenterPoint, PlotFolder)
    local PlacementArea = Plot:FindFirstChild("PlacementArea") or Plot

    if not PlacementArea or not PlacementArea:IsA("BasePart") then
        return {}
    end

    local Occupied = Utils.GetOccupiedEggPositions()
    local Size = PlacementArea.Size
    local Candidates = {}

    for X = -Size.X / 2, Size.X / 2, EggRadius * 2 do
        for Z = -Size.Z / 2, Size.Z / 2, EggRadius * 2 do
            local Position = PlacementArea.CFrame:PointToWorldSpace(Vector3.new(X, 0, Z))

            -- The server only accepts placements inside the plot bounds, which are smaller than PetArea
            if PlotFolder and not PlotState.ContainsLocalPoint(Position) then
                continue
            end

            local Free = true

            for _, OccupiedLocalCFrame in next, Occupied do
                -- Convert LocalCFrame to world space for comparison
                local OccupiedWorldPos = CenterPoint.CFrame:PointToWorldSpace(OccupiedLocalCFrame.Position)

                if (Position - OccupiedWorldPos).Magnitude < EggRadius * 2 then
                    Free = false
                    break
                end
            end

            if Free then
                Candidates[#Candidates + 1] = CFrame.new(Position)
            end
        end
    end

    -- Closest to the base first, so eggs stack in a tidy cluster
    table.sort(Candidates, function(A, B)
        return (A.Position - CenterPoint.Position).Magnitude < (B.Position - CenterPoint.Position).Magnitude
    end)

    return Candidates
end

Core.PlaceEgg = function(Uid: string)
    local Record = Uid and EggState.ReadOwnedEgg(UserId, Uid)

    -- The stolen egg only becomes an owned, unplaced record a moment after the carry, so fall
    -- back to whatever unplaced egg we own
    if not Record or Record.Placement then
        Uid = Utils.WaitForUnplacedEggUid(3)
    end

    if not Uid then
        return false
    end

    local PlotData = PlotState.ResolvePlot()
    if not PlotData then
        return false
    end

    local Candidates = Utils.GetFreeEggPositions(PlotData.PetArea, config.Eggs.EggRadius, PlotData.CenterPoint, PlotData.PlotFolder)

    if #Candidates == 0 then
        return false
    end

    -- The server rejects some spots ("Get closer to your area to place an egg!"), so walk the
    -- candidates from the base outwards until one sticks
    local Message

    for Index = 1, math.min(#Candidates, 12) do
        local CFrame = Candidates[Index]

        Utils.TweenTo(CFrame)

        -- The server refuses the placement while the character is airborne or knocked down
        for _ = 1, 20 do
            if Utils.CanCarryEgg() then
                break
            end

            task.wait(.1)
        end

        task.wait(.15)

        local Success
        Success, Message = EggState.PlantEgg(Uid, PlotData.CenterPoint.CFrame:ToObjectSpace(CFrame))

        if Success then
            return true
        end
    end

    warn("Failed to place egg " .. Uid .. ": " .. tostring(Message))

    --Utils.TweenTo(SpawmPoint) -- otherwise you noclip = lotta problems

    return false
end

const Zones = {
    ["Light Dark"] = 12,
    ["Titan Temple"] = 11,
    ["Cherry Blossom"] = 10,
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
    local MaxRank = Options.MaximumRank or 10
    local BestEgg
    local BestRank = -math.huge

    for _, Egg in next, (EggState.ReadFieldEggs().Records) do
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

        if Area == "Random" and EggRank > MaxRank then
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
            BestRank = Rank
            BestEgg = Egg
        end
    end

    return BestEgg
end

Utils.IsNight = function()
	return AreaEggCycle.IsNightPhase(workspace:GetServerTimeNow())
end

-- for a larger script it would have other checks
Utils.VerifySteal = function()
	local Night = Utils.IsNight()
	if Night then
		return false
	end
    if OnTreadmill then
        Remotes.Treadmill.AskDoff:InvokeServer()
    end

	return true
end

Utils.TweenTo = function(Area, SpeedMultiplier)
    local Target: CFrame = typeof(Area) == "Instance" and Area.CFrame or Area
    if config.AnticheatBypass and Anticheat then
        Anticheat.Core.Teleport(Target)

        return
    end

    local Start = HumanoidRootPart.Position

    local Distance = (Start - Target.Position).Magnitude
    local Duration = Distance / (Humanoid.WalkSpeed * (SpeedMultiplier or 0.9))

    local Gravity = workspace.Gravity
    local VelocityY = 0
    local StartTime = os.clock()
    local LastTime = StartTime

    local Connection

    Connection = RunService.Heartbeat:Connect(function()
        local Now = os.clock()
        local DeltaTime = Now - LastTime
        LastTime = Now

        local Alpha = math.clamp((Now - StartTime) / Duration, 0, 1)

        local Position = Start:Lerp(Target.Position, Alpha)

        VelocityY -= Gravity * DeltaTime
        Position += Vector3.yAxis * VelocityY * DeltaTime

        local RayOrigin = Position + Vector3.yAxis * 2
        local RayDirection = Vector3.yAxis * -6

        local Result = workspace:Raycast(
            RayOrigin,
            RayDirection,
            RaycastParams.new()
        )

        if Result and VelocityY < 0 then
            local Height = Humanoid.HipHeight + HumanoidRootPart.Size.Y / 2
            local GroundY = Result.Position.Y + Height

            if Position.Y <= GroundY then
                Position = Vector3.new(Position.X, GroundY, Position.Z)
                VelocityY = 0
            end
        end

        HumanoidRootPart.CFrame = CFrame.new(Position) * Target.Rotation

        if Alpha >= 1 then
            Connection:Disconnect()
        end
    end)

    repeat
        RunService.Heartbeat:Wait()
    until not Connection.Connected
end

Core.StealBestEgg = function(Options)
	if not Utils.VerifySteal() then
		return false
	end

	local Egg = Utils.GetBestEgg(Options)
	if not Egg then
		return false
	end

	local Uid = Egg.Uid

	local Stand = Utils.GetEggStandCFrame(Egg, math.rad(90))

    Utils.TweenTo(SpawmPoint)
	Utils.TweenTo(Stand)
	task.wait(.2)

	-- Wait until the character has landed and is not knocked down
	for _ = 1, 20 do
		if Utils.CanCarryEgg() then
			break
		end

		task.wait(.1)
	end

	-- The server needs time to accept where a teleport put us, and the further we jumped the longer
	-- that takes -- so hold the position and retry instead of guessing a wait. Every teleport
	-- restarts it, so we only move again if we actually got pushed off the spot
	local Success, Message
	local Deadline = os.clock() + (config.AnticheatBypass and 6 or 2)

	while os.clock() < Deadline do
		if HumanoidRootPart and (HumanoidRootPart.Position - Stand.Position).Magnitude > 6 then
			Utils.TweenTo(Stand)
			task.wait(.3)
		end

		if Utils.CanCarryEgg() then
			if AreaEggSlotIdentity.LooksLikeFirstAreaUid(Uid) then
				Success, Message = EggState.CarryFieldEgg(Uid, AreaEggSlotIdentity.SlotKey(Egg.AreaId, Egg.NestId))
			else
				Success, Message = EggState.CarryFieldEgg(Uid)
			end

			if Success then
				break
			end

			-- A carry that never dropped blocks every steal until it is cleared
			if Message == "Already carrying an egg" then
				EggState.DropFieldEgg("PlayerRequest")
				task.wait(1)
			end
		end

		task.wait(.5)
	end

	if not Success then
		warn("Failed to carry " .. Uid .. ": " .. tostring(Message))
	end

	task.wait(.15)

	Utils.TweenTo(SpawmPoint)

    if config.Eggs.AutoPlace then
        task.wait(.5)

        Core.PlaceEgg(Uid)
    end

	return Success == true
end

Utils.HatchEgg = function(Uid: string)
	EggState.BeginHatch(
		Uid
	); task.wait(0.5) -- not sure
	EggState.FinishHatch(
		Uid
	)
end

Core.HatchEggs = function()
	const Snapshot = EggState.ReadOwnedEggs()

	for _, Owner in next, (Snapshot) do
		if Owner.OwnerUserId ~= UserId then
			continue
		end
		for Uid, Egg in next, (Owner.Records) do
			if Egg.Placement and EggState.IsReadyToHatch(Uid) then
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
    Shop = Window:CreateTab("Shop"),
    Settings = Window:CreateTab("Settings"),
}

-- // Eggs

tabs.Eggs:CreateDropdown({
    Name = "Zone",
    Options = {
        "Light Dark",
        "Titan Temple",
        "Cherry Blossom",
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
                Core.StealBestEgg(config.Eggs.BestEgg)
                task.wait(.2)
            end
        end)
    end,
})

tabs.Eggs:CreateButton({
    Name = "Steal Egg",
    Callback = function()
        task.spawn(function()
            Core.StealBestEgg(config.Eggs.BestEgg)
        end)
    end,
})

tabs.Eggs:CreateToggle({
    Name = "Auto Place Stolen Egg",
    CurrentValue = false,
    Flag = "AutoPlaceStolenEgg",
    Callback = function(Value)
        config.Eggs.AutoPlace = Value
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

tabs.Eggs:CreateSlider({
    Name = "Maximum Zone Rank",
    Range = {1, 10},
    Increment = 1,
    Suffix = "",
    CurrentValue = config.Eggs.BestEgg.MaximumRank,
    Flag = "MaxEggRank",
    Callback = function(Value)
        config.Eggs.BestEgg.MaximumRank = Value
    end
})

--[[
tabs.Eggs:CreateSlider({
    Name = "Egg Radius",
    Range = {1, 5},
    Increment = 0.5,
    Suffix = "",
    CurrentValue = config.Eggs.EggRadius,
    Flag = "EggRadius",
    Callback = function(Value)
        config.Eggs.EggRadius = Value
    end
})
--]]

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

-- // Shop
Core.BuyTrail = function(config)
    Remotes.Trailwear.AskPurchase:InvokeServer(
        config.Shop.Trail.Selected
    )
end

local TrailOptions = {}

for Id in next, Trails.Directory do
	TrailOptions[#TrailOptions + 1] = Id
end

table.sort(TrailOptions)

tabs.Shop:CreateDropdown({
    Name = "Select Trail",
    Options = TrailOptions,
    CurrentOption = {config.Shop.Trail.Selected},
    MultipleOptions = false,
    Flag = "SelectedTrail",
    Callback = function(Option)
        config.Shop.Trail.Selected = Option[1]
    end
})

tabs.Shop:CreateButton({
    Name = "Buy Trail",
    Callback = function()
        Core.BuyTrail(config)
    end,
})

Core.PetCapacityUpgrade = function()
    Remotes.Homestead.AskBaseTierRaise:FireServer()
end

tabs.Shop:CreateButton({
    Name = "Upgrade Pet Capacity",
    Callback = function()
		Core.PetCapacityUpgrade()
    end,
})

-- // Settings
tabs.Settings:CreateToggle({
    Name = "Anticheat Bypass",
    CurrentValue = true,
    Flag = "AnticheatBypass",
    Callback = function(Value)
        config.AnticheatBypass = Value
    end,
})