--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

--// Evemts
local Train = ReplicatedStorage.Train
local Win = ReplicatedStorage.Win
local Rebirth = ReplicatedStorage.Rebirth
local Egg = ReplicatedStorage.Egg

--// vars
local MobsFolder = workspace.Mobs
local Arena = LocalPlayer.stats.Area.Value

local function train()
	local Mobs = MobsFolder:GetChildren()
	local Mob = Mobs[math.random(1, #Mobs)]

	Train:FireServer(
		Mob.Name,
		1 -- hardcoded in game, idk
	)
end

local function win()
	Win:FireServer(
		Arena
	)
end

local function rebirth()
	Rebirth:FireServer()
end

--getgenv().autohatch = true
--getgenv().hatchselection = "Rock Egg"

local function autohatch()
	local hatchselection = getgenv().hatchselection -- like: "Rock Egg"
	if not hatchselection then
		return
	end

	Egg:FireServer(
		hatchselection,
		3
	)
end

local keys = {
	["autotrain"] = train, -- has some in-game error, floods console.
	["autowin"] = win,
	["autorebirth"] = rebirth,
	["autohatch"] = autohatch,
}

while task.wait() do
	Arena = LocalPlayer.stats.Area.Value

	for i, v in keys do
		if not getgenv()[i] then
			continue
		end
		pcall(v)
	end
end