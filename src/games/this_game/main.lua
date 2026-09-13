-- // Modules
const core = assert(loadstring(game:HttpGet("https://voltex.website/src/games/this_game/core.lua")))()

-- // config
local config = {
	Goals = {
		AutoScore = false,
		Attempts = 2, -- solves per turn before giving up
		Delay = 0.75, -- seconds to wait after the turn starts before shooting
	},
}

-- // cheat
local cheat = {
	Core = {},
}
local Core = cheat.Core

-- // Core

Core.Score = function()
	return core.Solve()
end

-- // Interface

const Rayfield = assert(loadstring(game:HttpGet("https://voltex.website/libraries/Rayfield/main.lua")))()

const Window = Rayfield:CreateWindow({
	Name = "this game",
	LoadingTitle = "Loading...",
	LoadingSubtitle = "subtitle",
})

const tabs = {
	Score = Window:CreateTab("Score"),
	Settings = Window:CreateTab("Settings"),
}

-- // Score

tabs.Score:CreateButton({
	Name = "Score Goal",
	Callback = function()
		Core.Score()
	end,
})

tabs.Score:CreateToggle({
	Name = "Auto Score Goal",
	CurrentValue = false,
	Flag = "AutoScoreGoal",
	Callback = function(Value)
		config.Goals.AutoScore = Value
	end,
})

-- // Auto score

-- One shot per turn, and only while it is our turn. core.Solve() returns nil
-- when the board has no goal in it, so it retries a couple of times before
-- giving the turn up.
local WasMyTurn = false
local Attempts = 0

task.spawn(function()
	while true do
		task.wait(0.5)

		if not config.Goals.AutoScore or not core.IsMyTurn() then
			WasMyTurn = false
			continue
		end

		-- fresh turn: let the board settle before solving
		if not WasMyTurn then
			WasMyTurn = true
			Attempts = 0
			task.wait(config.Goals.Delay)
		elseif Attempts >= config.Goals.Attempts then
			continue
		end

		Attempts += 1
		if Core.Score() ~= nil then
			Attempts = config.Goals.Attempts
		end
	end
end)
