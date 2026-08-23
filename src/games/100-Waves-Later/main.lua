-- // Services
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Players = game:GetService("Players")
const RunService = game:GetService("RunService")

-- // Knit services
const KnitServices = ReplicatedStorage.Packages._Index["sleitnick_knit@1.6.0"].knit.Services

const RaidManagement = KnitServices.RaidManagementService.RE
const RoundEndSkills = KnitServices.RoundEndSkillsV2Service.RE
const PickupManager = KnitServices.PickupManager.RE
const ExplosionService = KnitServices.ExplosionService.RF
const PlayerDamageService = KnitServices.PlayerDamageService

-- // Events
const CreateReviveBillboard = RaidManagement.CreateReviveBillboard
const RevivePromptTriggeredClient = RaidManagement.RevivePromptTriggeredClient
const enqueSkillSelect = RoundEndSkills.enqueSkillSelect
const finishSelect = RoundEndSkills.finishSelect
const Collect = PickupManager.Collect
const GenerateExplosion = ExplosionService.GenerateExplosion
const ApplyRadiationDamage = PlayerDamageService.RF.ApplyRadiationDamage

-- // Workspace
const Zombies = workspace:FindFirstChild("Zombies")
if not Zombies then
    print("Do not execute in lobby")
    return
end

-- // LocalPlayer
const LocalPlayer = Players.LocalPlayer

--// variables
local Flags = {}
Flags.__index = Flags

-- // config
local config = {
	AutoRevive = false,
	AutoSkill = {
		Enabled = false,
		PreferSuper = true,
	},
	InfiniteMoney = {
		Enabled = false,
		Amount = 32124,
	},
	KillAll = {
		Range = math.huge,
		Delay = 0.1,
	},
}

-- // cheat
local cheat = {
	Utils = {},
	Core = {},
}
local Utils = cheat.Utils
local Core = cheat.Core

-- // connections
local Connections = {}

Utils.Connect = function(Key, Signal, Callback)
	Utils.Disconnect(Key)
	if typeof(Signal) == "Instance" and Signal:IsA("RemoteEvent") then
		Signal = Signal.OnClientEvent
	end
	Connections[Key] = Signal:Connect(Callback)
end

Utils.Disconnect = function(Key)
	if Connections[Key] then
		Connections[Key]:Disconnect()
		Connections[Key] = nil
	end
end

-- // Auto Revive
Core.SetAutoRevive = function(Enabled)
	if not Enabled then
		Utils.Disconnect("AutoRevive")
		return
	end

	Utils.Connect("AutoRevive", CreateReviveBillboard, function(a1, a2)
		task.wait(0.1)
		pcall(function()
			RevivePromptTriggeredClient:FireServer(a2)
		end)
	end)
end

-- // Auto Select Skill
Core.Toggle_AutoSkill = function(Enabled)
	if not Enabled then
		Utils.Disconnect("AutoSkill")
		return
	end

	Utils.Connect("AutoSkill", enqueSkillSelect, function(Payload)
		local Options = Payload and Payload.skillChoices
		local Choice = 1

		if config.AutoSkill.PreferSuper and type(Options) == "table" then
			for Index, Skill in next, Options do
				if type(Skill) == "string" and Skill:sub(1, 5) == "Super" then
					Choice = Index
					break
				end
			end
		end

		finishSelect:FireServer("CHOOSE", Choice)
	end)
end

-- // Infinite Money
Core.Toggle_InfiniteMoney = function(Enabled)
	if not Enabled then
		Utils.Disconnect("InfiniteMoney")
		return
	end

	Utils.Connect("InfiniteMoney", workspace.DescendantAdded, function(Scrap)
		local Id = Scrap:GetAttribute("Id")
		if not Id then
            return
        end
        pcall(function()
            Collect:FireServer(Id, "SCRAP", config.InfiniteMoney.Amount)
        end)
	end)
end

-- // Kill All
Core.KillZombie = function(Zombie)
	local HumanoidRootPart = Zombie:FindFirstChild("HumanoidRootPart")
    if not HumanoidRootPart then
        return
    end
    GenerateExplosion:InvokeServer(HumanoidRootPart.Position, config.KillAll.Range, 2, "EXPLOSIVE CROSSBOW")
end

Core.KillAll = function()
	for _, Zombie in next, Zombies:GetChildren() do
		Core.KillZombie(Zombie)
	end
end

local hits = {}
Core.Toggle_KillAura = function(Enabled)
	if not Enabled then
		Utils.Disconnect("KillAll")
		return
	end

	Utils.Connect("KillAll", Zombies.DescendantAdded, function(Zombie)
        task.spawn(function()
            while Zombie.Parent ~= nil do
                Core.KillZombie(Zombie)
                local Id = Zombie:GetDebugId()

                if not hits[Zombie] then
                    task.wait(config.KillAll.Delay) -- first hit delay
                else
                    task.wait(0.01) -- just dont crash the loop
                end
                hits[Id] = true
            end
        end)
	end)
end

-- // Interface

local Rayfield = loadstring(game:HttpGet("https://voltex.website/libraries/Rayfield/main.lua"))()
Flags = Rayfield.Flags

local Window = Rayfield:CreateWindow({
	Name = "100 Waves Later",
	LoadingTitle = "Loading...",
	LoadingSubtitle = "subtitle",
})

local tabs = {
	Main = Window:CreateTab("Main"),
	Combat = Window:CreateTab("Combat"),
}

-- // Main

tabs.Main:CreateToggle({
	Name = "Auto Revive",
	CurrentValue = false,
	Flag = "AutoRevive",
	Callback = function(Value)
		config.AutoRevive = Value
		Core.SetAutoRevive(Value)
	end,
})

tabs.Main:CreateToggle({
	Name = "Auto Select Skill",
	CurrentValue = false,
	Flag = "AutoSkill",
	Callback = function(Value)
		config.AutoSkill.Enabled = Value
		Core.Toggle_AutoSkill(Value)
	end,
})

tabs.Main:CreateToggle({
	Name = "Prefer Super Skills",
	CurrentValue = true,
	Flag = "PreferSuper",
	Callback = function(Value)
		config.AutoSkill.PreferSuper = Value
	end,
})

tabs.Main:CreateDivider()

tabs.Main:CreateToggle({
	Name = "Infinite Money (Scrap)",
	CurrentValue = false,
	Flag = "InfiniteMoney",
	Callback = function(Value)
		config.InfiniteMoney.Enabled = Value
		Core.Toggle_InfiniteMoney(Value)
	end,
})

tabs.Main:CreateSlider({
	Name = "Scrap Amount",
	Range = {1, 100000},
	Increment = 1,
	Suffix = "",
	CurrentValue = config.InfiniteMoney.Amount,
	Flag = "ScrapAmount",
	Callback = function(Value)
		config.InfiniteMoney.Amount = Value
	end,
})

-- // Combat

tabs.Combat:CreateToggle({
	Name = "Kill All",
	CurrentValue = false,
	Flag = "KillAll",
	Callback = function(Value)
		Core.Toggle_KillAura(Value)
	end,
})

tabs.Combat:CreateButton({
	Name = "Kill All (Once)",
	Callback = function()
		task.spawn(function()
			Core.KillAll()
		end)
	end,
})

tabs.Combat:CreateSlider({
	Name = "Kill Delay",
	Range = {0.05, 4},
	Increment = 0.05,
	Suffix = "s",
	CurrentValue = config.KillAll.Delay,
	Flag = "KillDelay",
	Callback = function(Value)
		config.KillAll.Delay = Value
	end,
})

--[[
tabs.Combat:CreateSlider({
	Name = "Kill Range",
	Range = {10, 1000},
	Increment = 10,
	Suffix = " studs",
	CurrentValue = config.KillAll.Range,
	Flag = "KillRange",
	Callback = function(Value)
		config.KillAll.Range = Value
	end,
})
--]]