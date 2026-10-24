-- // Services
const ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // Modules
const SoccerSim = require(ReplicatedStorage.Shared.Sim.SoccerSim)
const GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

-- // config
const config = {
	Targets = { 0, -0.55, 0.55, -1, 1 }, -- fractions of the goal mouth
	Depths = { 20, 70 }, -- aim this far past the goal line, not at it
	PowerScale = 0.75,
	BankStep = 6,
	BankSims = 800, -- a blocked lane isnt worth more of the turn than this
	Budget = 0.1, -- solve for this long before handing the frame back
}

const Timestep = GameConfig.FixedTimestep
const Mouth = GameConfig.GoalWidth / 2 - GameConfig.BallRadius
const Contact = GameConfig.DiscRadius + GameConfig.BallRadius - 2

local core = {}

-- // Session

-- the live match isnt reachable through a controller, so grab the instance off
-- the gc. our discs are always 1..5 and we always score in goal 1, mirroring is
-- handled by the game itself
local Cached = nil

local function Find()
	if not getgc then
		return nil
	end

	local Fallback = nil

	for _, Object in getgc(true) do
		if type(Object) == "table" and rawget(Object, "_myTurn") ~= nil then
			const Board = rawget(Object, "_board")

			if type(Board) == "table" and Board.GetBodies ~= nil then
				if Object._phase == "turn" then
					return Object
				end

				Fallback = Fallback or Object
			end
		end
	end

	return Fallback
end

local NextScan = 0

function core.Session()
	if Cached ~= nil and Cached._phase ~= "over" then
		return Cached
	end

	if os.clock() < NextScan then
		return nil
	end

	NextScan = os.clock() + 1
	Cached = Find()

	return Cached
end

function core.IsMyTurn(): boolean
	const Live = core.Session()

	return Live ~= nil and Live._phase == "turn" and Live._myTurn == true
end

-- // Simulation

local LastYield = os.clock()

local function Breathe()
	if os.clock() - LastYield >= config.Budget then
		LastYield = os.clock()
		task.wait()
	end
end

local function Play(Bodies, Order, Disc, DirX, DirY, Power)
	Breathe()

	const Trial = SoccerSim.clone(Bodies)
	SoccerSim.applyShot(Trial, Disc, DirX, DirY, Power)

	local Time = 0
	while Time < GameConfig.ResolveMaxTime do
		const Info = SoccerSim.step(Trial, Timestep, Order)
		Time += Timestep

		if Info.goal and Info.goal ~= 0 then
			return Info.goal == 1, Time
		end

		if SoccerSim.settled(Trial) then
			break
		end
	end

	return false, Time
end

-- the ball leaves along the line of centres, so the disc has to touch it on the
-- far side: aim at where the disc centre is at contact, and follow the game's
-- own distance -> power curve
local function Aim(Bodies, Disc, TargetX, TargetY)
	const Ball = Bodies[SoccerSim.BALL]
	const DeltaX, DeltaY = Ball.x - TargetX, Ball.y - TargetY
	const Distance = math.sqrt(DeltaX * DeltaX + DeltaY * DeltaY)

	if Distance < 1e-4 then
		return 0, 1, 0.7
	end

	const FromX = Ball.x + DeltaX / Distance * Contact - Bodies[Disc].x
	const FromY = Ball.y + DeltaY / Distance * Contact - Bodies[Disc].y
	const Length = math.sqrt(FromX * FromX + FromY * FromY)

	if Length < 1e-4 then
		return 0, 1, 0.7
	end

	return FromX / Length, FromY / Length, math.clamp(Length / 380 + 0.5, 0.45, 1)
end

local function Targets()
	const List = {}

	for _, Fraction in config.Targets do
		for _, Depth in config.Depths do
			table.insert(List, { GameConfig.FieldW / 2 + Fraction * Mouth, -Depth })
		end
	end

	return List
end

local function Discs(Bodies)
	const Ball = Bodies[SoccerSim.BALL]
	const List = {}

	for Index = 1, 5 do
		const Body = Bodies[Index]

		if Body ~= nil and not Body.off then
			const DeltaX, DeltaY = Body.x - Ball.x, Body.y - Ball.y
			table.insert(List, { Index = Index, Distance = DeltaX * DeltaX + DeltaY * DeltaY })
		end
	end

	table.sort(List, function(A, B)
		return A.Distance < B.Distance
	end)

	return List
end

-- // Search

function core.Find()
	const Live = core.Session()

	if Live == nil then
		return nil
	end

	const Board = Live._board
	const Bodies = SoccerSim.clone(Board:GetBodies())
	const Order = rawget(Board, "_simOrder")
	const Candidates = Discs(Bodies)
	const Shots = Targets()
	const Ball = Bodies[SoccerSim.BALL]

	if Ball.y < 0 then
		return nil -- ball still in the net from the last goal
	end

	for _, Entry in Candidates do
		local Best = nil

		for _, Target in Shots do
			const DirX, DirY, Power = Aim(Bodies, Entry.Index, Target[1], Target[2])

			for _, Try in { Power, 1, Power * config.PowerScale } do
				const Scored, Time = Play(Bodies, Order, Entry.Index, DirX, DirY, Try)

				if Scored and (Best == nil or Time < Best.Time) then
					Best = { Disc = Entry.Index, DirX = DirX, DirY = DirY, Power = Try, Time = Time }
				end
			end
		end

		if Best ~= nil then
			return Best
		end
	end

	-- lane blocked: bounce the ball off a rail and into the goal
	local Sims = 0

	for _, Entry in Candidates do
		for Degrees = 0, 360 - config.BankStep, config.BankStep do
			if Sims >= config.BankSims then
				return nil
			end

			const Radians = math.rad(Degrees)
			const DirX, DirY, Power = Aim(Bodies, Entry.Index, Ball.x + math.cos(Radians) * 200, Ball.y + math.sin(Radians) * 200)

			Sims += 1

			const Scored, Time = Play(Bodies, Order, Entry.Index, DirX, DirY, Power)

			if Scored then
				return { Disc = Entry.Index, DirX = DirX, DirY = DirY, Power = Power, Time = Time }
			end
		end
	end

	return nil
end

-- // Fire

-- goes through the session's own shoot handler so the client runs the resolve
-- and reports TurnResolved, same as a real drag
function core.Shoot(Shot): boolean
	const Live = core.Session()

	if Live == nil or not core.IsMyTurn() then
		return false
	end

	Live:_onMyShoot(Shot.Disc, Shot.DirX, Shot.DirY, Shot.Power)

	return true
end

function core.Solve()
	if not core.IsMyTurn() then
		return nil
	end

	const Shot = core.Find()

	if Shot == nil or not core.Shoot(Shot) then
		return nil
	end

	return Shot
end

return core
