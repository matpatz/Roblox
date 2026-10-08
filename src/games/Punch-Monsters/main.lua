--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

--// Evemts
local Train = ReplicatedStorage.Train
local Win = ReplicatedStorage.Win
local Rebirth = ReplicatedStorage.Rebirth

--// vars
local Arena = LocalPlayer.stats.Area.Value

local function train()
	Train:FireServer(
		"0A",
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

local keys = {
	["autotrain"] = train, -- has some in-game error, floods console.
	["autowin"] = win,
	["autorebirth"] = rebirth
}

local count = 0
while task.wait() do
	count += 1
	if count == 100 then
		count = 0

		Arena = LocalPlayer.stats.Area.Value
	end

	for i, v in keys do
		if not getgenv()[i] then
			continue
		end
		pcall(v)
	end
end