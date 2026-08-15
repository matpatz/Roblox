--[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]
local UpgradeDeposit = false
local BuySoldiers = false
local MergeSoldiers = false

local MoneyWanted = 1000
local XP = 1000

local rep = game:GetService("ReplicatedStorage")

local TycoonService = require(rep.Modules.TycoonSystem.TycoonService)
local tycoon = TycoonService:GetPlayerTycoon()

rep.Remotes.TycoonSystem.UpdateXPValue:FireServer(MoneyWanted)
rep.Remotes.TycoonSystem.Deposit:FireServer(tycoon, XP)

task.spawn(function()
	while task.wait() do
		if UpgradeDeposit then
			rep.Remotes.TycoonSystem.UpgradeDeposit:FireServer(tycoon, tycoon.Upgrades.UpgradeDeposit)
		end

		if BuySoldiers then
			rep.Remotes.TycoonSystem.AddCell:FireServer(
				tycoon,
				1,
				nil,
				nil
			)
		end

		if MergeSoldiers then
			rep.Remotes.TycoonSystem.Merge:InvokeServer(
				tycoon
			)
		end
	end
end)
