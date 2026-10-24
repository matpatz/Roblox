-- // Knit
local Knit = shared.Knit
local conmanager = Knit.conmanager

-- // Modules
const core = Knit.require("games/Flick-Football", "core")

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

-- // Score

Core.Score = function()
	return core.Solve()
end

-- // Auto score

-- one shot per turn: nothing moves during our turn, so a second solve would just
-- repeat the first one
local WasMyTurn = false

Core.Toggle_AutoScore = function(Enabled)
	conmanager.disconnect("AutoScore")

	if not Enabled then
		WasMyTurn = false

		return
	end

	conmanager.connect("AutoScore", 0.5, function()
		if not core.IsMyTurn() then
			WasMyTurn = false

			return
		end

		if WasMyTurn then
			return
		end

		-- fresh turn: let the board settle before solving
		WasMyTurn = true
		task.wait(config.Goals.Delay)
		Core.Score()
	end)
end

-- // Interface

const Rayfield = Knit.ui.new("Rayfield")()
const Window = Rayfield:CreateWindow({
	Name = "Flick Football",
	LoadingTitle = "Loading...",
	LoadingSubtitle = "subtitle",
})

const Main = Window:CreateTab("Main")

-- // Main

Main:CreateToggle({
	Name = "Auto Score Goal",
	CurrentValue = config.Goals.AutoScore,
	Flag = "AutoScoreGoal",
	Callback = function(Value)
		config.Goals.AutoScore = Value
		Core.Toggle_AutoScore(Value)
	end,
})

Main:CreateDivider()

Main:CreateButton({
	Name = "Score Goal",
	Callback = function()
		Core.Score()
	end,
})
