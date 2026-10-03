--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

--// Evemts
local KnitService = ReplicatedStorage.Packages._Index["sleitnick_knit@1.5.3"].knit.Services

local BubbleReward = KnitService.BubbleService.RF.BubbleReward
local BuyUpgrade = KnitService.UpgradeService.RF.BuyUpgrade
local GetUpgrades = KnitService.UpgradeService.RF.GetUpgrades

--// vars
local Countries = workspace.Countries

local start_country_name = ReplicatedStorage:GetAttribute("StartCountry")
local StartCountry = Countries[start_country_name]

local upgrades = GetUpgrades:InvokeServer()
repeat task.wait() until upgrades

local function getdna()
	print("big dna")

	BubbleReward:InvokeServer(
		StartCountry,
		"Red"
	)
end

local function upgrade(name, req)
	for i = 1, req do
		getdna()
	end

	BuyUpgrade:InvokeServer(
		name
	)
end

local keys = {
	["autofarmdna"] = getdna,
}

task.spawn(function()
	while task.wait(0.25) do
		for i, v in keys do
			if not getgenv()[i] then
				continue
			end
			pcall(v)
		end
	end
end)

if getgenv().upgradeall then
	for i, v in upgrades do
		print("aaaa")
		if v.Owned or v.Mutated then
			continue
		end
		
		local name = i
		local req = v.Cost

		upgrade(name, req)
	end
end