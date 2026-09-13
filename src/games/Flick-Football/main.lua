-- // Modules
const core = assert(loadstring(game:HttpGet("https://voltex.website/src/games/Flick-Football/core.lua")))()

-- // config
local config = {
	Goals = {
		AutoScore = false,
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

-- One shot per turn, and only while it is our turn. Nothing moves during our
-- turn, so a second solve would just repeat the first one: if the board has no
-- goal in it, that turn simply goes unplayed.
local WasMyTurn = false

task.spawn(function()
	while true do
		task.wait(0.5)

		if not config.Goals.AutoScore or not core.IsMyTurn() then
			WasMyTurn = false
			continue
		end

		if WasMyTurn then
			continue
		end

		-- fresh turn: let the board settle before solving
		WasMyTurn = true
		task.wait(config.Goals.Delay)
		Core.Score()
	end
end)
