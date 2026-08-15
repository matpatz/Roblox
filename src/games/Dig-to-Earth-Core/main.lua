--[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
	Name = "Lebron James",
	LoadingTitle = "fuh you",
	LoadingSubtitle = "Subtitle",
})

local main = Window:CreateTab("autostuff")
local a = Window:CreateTab("lebron")

main:CreateLabel("Funds", 1234567890)

local fps = game:GetService("Stats").Workspace.FPS:GetValue()

local mr = false
main:CreateToggle({
   Name = "Money",
   CurrentValue = false,
   Flag = "m_money",
   Callback = function(v)
      mr = v
      if v then
         task.spawn(function()
            while mr do
               for i = 1, fps do
                  game:GetService("ReplicatedStorage").Remotes.DigEvent:FireServer("hello")
               end
               task.wait()
            end
         end)
      end
   end,
})

local gr = false
main:CreateToggle({
   Name = "Gems",
   CurrentValue = false,
   Flag = "g_gems",
   Callback = function(v)
      gr = v
      if v then
         task.spawn(function()
            while gr do
               for i = 1, fps do
                  game:GetService("ReplicatedStorage").Remotes.GemEvent:FireServer(20, "bye")
               end
               task.wait()
            end
         end)
      end
   end,
})

main:CreateLabel("upgrades", 1234567890)

local upg = {"WalkSpeed", "Strength", "GemChance", "PetLuck"}
local su = upg[1]

local upgrades = main:CreateDropdown({
	Name = "Upgrades",
	Options = upg,
	CurrentOption = {su},
	MultipleOptions = false,
	Flag = "upg",
	Callback = function(opt) 
		su = opt[1]
	end,
})

local upgb = main:CreateButton({
	Name = "Max + Free upgrade",
	Callback = function()
        for i = 1, 15 do
            game:GetService("ReplicatedStorage").Remotes.UpgradeEvent:FireServer(su, 1)
        end
	end,
})

main:CreateLabel("Spins", 1234567890)

local rewards, rid = {"100 Gems","2.5K Cash","3 Spins","Pet","250 Gems","1K Cash","x10 Cash","75 Gems","Ten Spins"}, {["100 Gems"]=1,["2.5K Cash"]=2,["3 Spins"]=3,["Pet"]=4,["250 Gems"]=5,["1K Cash"]=6,["x10 Cash"]=8,["75 Gems"]=9,["Ten Spins"]=10}
local reward = rewards[1]

local rewd = main:CreateDropdown({
	Name = "Rewards",
	Options = rewards,
	CurrentOption = {reward},
	MultipleOptions = false,
	Flag = "rewd",
	Callback = function(opt) reward = opt[1] end,
})

main:CreateButton({
	Name = "Spin Reward",
	Callback = function()
		game:GetService("ReplicatedStorage").Remotes.SpinPrizeEvent:FireServer(rid[reward])
	end,
})
