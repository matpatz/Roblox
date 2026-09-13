-- // this_game — score solver
-- src/games/this_game/core.lua
--
-- Soccer pool: you shoot one of your discs, it knocks the ball, the ball has to
-- end up in the opponent's goal. The game ships its own deterministic physics
-- (Shared.Sim.SoccerSim) and keeps the live board on the client, so this does
-- NOT guess: it replays candidate shots through the real simulation and only
-- fires one that provably scores.
--
-- It fires through the match session's own shoot handler, not by sending the
-- Shot packet itself. That matters: the shooter's client runs the resolve
-- locally and reports TurnResolved, which is what makes the point register and
-- the board animate. Sending the packet directly leaves the turn unresolved.
--
-- It aims outwards from the goal: the first candidate is the shot that sends
-- the ball straight at the goal mouth, and it only works away from that aim
-- until MinimumRun samples in a row score. So it reacts in a handful of
-- simulations and takes the shot a player would have taken, instead of some
-- wild bank off a rail. It yields on a time budget so the game keeps its frame
-- rate while it searches.

-- // Services

const ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // Modules

const Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"))
const Shared = ReplicatedStorage:WaitForChild("Shared")
const SoccerSim = require(Shared.Sim.SoccerSim)
const GameConfig = require(Shared.Config.GameConfig)

-- // Types

export type Shot = {
	Disc: number,
	DirX: number,
	DirY: number,
	Power: number,
	Time: number, -- seconds until the ball crosses the line
	Run: number, -- how many neighbouring angles score the same shot
}

export type SolverConfig = {
	TargetGoal: number?, -- 1 = goal at y < 0, 2 = goal at y > FieldH
	MyDiscs: { number }?, -- disc indices we may shoot
	Powers: { number }?, -- powers to try, in the order tried
	AngleStep: number?, -- degrees between samples inside the ball cone
	MinimumRun: number?, -- scoring samples in a row needed to take the shot
	BankStep: number?, -- degrees when sweeping the whole circle as a fallback
	BankPowers: { number }?,
	MaxTime: number?, -- give up on one shot after this many simulated seconds
	Budget: number?, -- seconds of solving to do per frame before yielding
	Fire: boolean?, -- shoot through the match session once a shot is found
}

-- // Config

-- Everything here is in the board's local space: our discs are always 1..5 and
-- the goal we attack is always goal 1, whichever side we were given.
const config = {
	TargetGoal = 1,
	MyDiscs = { 1, 2, 3, 4, 5 },
	Powers = { 1, 0.8 },
	AngleStep = 0.5,
	MinimumRun = 2,
	BankStep = 6,
	BankPowers = { 1 },
	MaxTime = 7,
	Budget = 0.008,
	Fire = true,
}

local core = {}
core.config = config

-- // Session

-- The live match (OnlineMatch online, LocalMatch against the AI) owns the board
-- and the turn state. Shooting through it is what makes the whole turn resolve.
local Cached = nil

local function Session()
	if Cached ~= nil and Cached._board ~= nil then
		return Cached
	end

	const Ok, Result = pcall(function()
		return Knit.GetController("GameController")._session
	end)
	Cached = if Ok then Result else nil

	return Cached
end

-- True while the server says it is our turn to shoot.
function core.IsMyTurn(): boolean
	const Live = Session()
	if Live == nil then
		return false
	end
	if Live._myTurn ~= nil then
		return Live._phase == "turn" and Live._myTurn == true
	end
	return Live._phase == "turn" and Live._turnSide == 1
end

-- // Board

-- The live board, cloned so the searches can't touch the real one.
function core.Board(): { any }?
	const Live = Session()
	if Live == nil or Live._board == nil then
		return nil
	end

	const Source = Live._board:GetBodies()
	const Bodies = SoccerSim.newBodies()
	for Index, Body in Bodies do
		const Entry = Source[Index]
		if Entry ~= nil then
			Body.x, Body.y = Entry.x, Entry.y
			Body.vx, Body.vy = 0, 0
		end
	end

	return Bodies
end

-- // Simulation

local LastYield = os.clock()

-- One simulation costs ~2ms, so hand the frame back after every Budget of
-- solving; the search takes longer but the game keeps its frame rate.
local function Breathe()
	const Now = os.clock()
	if Now - LastYield >= config.Budget then
		LastYield = os.clock()
		task.wait()
	end
end

-- Replay a shot on a copy of the board; returns whether it scores for us and
-- how long the ball took to cross the line.
local function Play(Bodies: { any }, Disc: number, DirX: number, DirY: number, Power: number): (boolean, number)
	Breathe()

	const Trial = SoccerSim.clone(Bodies)
	SoccerSim.applyShot(Trial, Disc, DirX, DirY, Power)

	local Time = 0
	while Time < config.MaxTime do
		const Info = SoccerSim.step(Trial, GameConfig.FixedTimestep)
		Time += GameConfig.FixedTimestep

		const Goal = Info.goal
		if Goal ~= nil and Goal ~= 0 then
			return Goal == config.TargetGoal, Time
		end
		if SoccerSim.settled(Trial) then
			break
		end
	end

	return false, Time
end

-- // Search

-- Sample the cone of directions that actually reach the ball, starting from the
-- one that sends the ball straight at the goal (the shot a player would take)
-- and working outwards. Returns as soon as MinimumRun samples in a row score,
-- which usually means a handful of simulations instead of hundreds.
local function ScanCone(Bodies: { any }, Disc: number, Ball: any, Goal: { x: number, y: number }): Shot?
	const Body = Bodies[Disc]
	const DeltaX = Ball.x - Body.x
	const DeltaY = Ball.y - Body.y
	const Distance = math.sqrt(DeltaX * DeltaX + DeltaY * DeltaY)
	const Reach = GameConfig.DiscRadius + GameConfig.BallRadius

	if Distance <= Reach or Distance > 4000 then
		return nil
	end

	const Base = math.atan2(DeltaY, DeltaX)
	const Spread = math.asin(math.min(1, Reach / Distance))
	const Steps = math.max(4, math.ceil(math.deg(Spread) * 2 / config.AngleStep))

	-- The aim that punts the ball at the goal mouth.
	const Wanted = math.atan2(Goal.y - Ball.y, Goal.x - Ball.x)
	const Middle = math.clamp((Wanted - (Base - Spread)) / (Spread * 2) * Steps, 0, Steps)

	for _, Power in config.Powers do
		local Count = 0
		local Total = 0

		for Index = 0, Steps do
			-- middle, then one either side, then two either side, ...
			const Offset = math.ceil(Index / 2) * (if Index % 2 == 1 then 1 else -1)
			const Step = Middle + Offset
			if Step < 0 or Step > Steps then
				continue
			end

			const Angle = Base - Spread + (Step / Steps) * Spread * 2
			const Scored, Time = Play(Bodies, Disc, math.cos(Angle), math.sin(Angle), Power)

			if not Scored then
				Count, Total = 0, 0
				continue
			end

			Count += 1
			Total += Step
			if Count >= config.MinimumRun then
				const Best = Total / Count
				const Aim = Base - Spread + (Best / Steps) * Spread * 2
				return {
					Disc = Disc,
					DirX = math.cos(Aim),
					DirY = math.sin(Aim),
					Power = Power,
					Time = Time,
					Run = Count,
				}
			end
		end
	end

	return nil
end

-- Fallback: when the ball can't be hit straight at the goal, sweep the whole
-- circle and let the disc bank off a rail first.
local function ScanBank(Bodies: { any }, Disc: number): Shot?
	const Steps = math.ceil(360 / config.BankStep)

	for _, Power in config.BankPowers do
		for Step = 0, Steps - 1 do
			const Angle = math.rad(Step * config.BankStep)
			const Scored, Time = Play(Bodies, Disc, math.cos(Angle), math.sin(Angle), Power)
			if Scored then
				return {
					Disc = Disc,
					DirX = math.cos(Angle),
					DirY = math.sin(Angle),
					Power = Power,
					Time = Time,
					Run = 1,
				}
			end
		end
	end

	return nil
end

-- Every shot that scores on the current board, best first. The disc nearest
-- the ball is tried first (the shot a player would actually take), and bank
-- shots are only searched when no direct hit on the ball can score.
function core.Find(Overrides: SolverConfig?): { Shot }
	if Overrides ~= nil then
		for Key, Value in Overrides do
			if Value ~= nil then
				config[Key] = Value
			end
		end
	end

	const Bodies = core.Board()
	assert(Bodies ~= nil, "core: no match session yet")

	const Ball = Bodies[SoccerSim.BALL]
	const Goal = if config.TargetGoal == 1
		then { x = GameConfig.FieldW / 2, y = 0 }
		else { x = GameConfig.FieldW / 2, y = GameConfig.FieldH }

	const Discs = table.clone(config.MyDiscs)
	table.sort(Discs, function(A: number, B: number): boolean
		const LeftX, LeftY = Bodies[A].x - Ball.x, Bodies[A].y - Ball.y
		const RightX, RightY = Bodies[B].x - Ball.x, Bodies[B].y - Ball.y
		return LeftX * LeftX + LeftY * LeftY < RightX * RightX + RightY * RightY
	end)

	const Shots: { Shot } = {}

	for _, Disc in Discs do
		if not Bodies[Disc].off then
			const Shot = ScanCone(Bodies, Disc, Ball, Goal)
			if Shot ~= nil then
				table.insert(Shots, Shot)
			end
		end
	end

	if #Shots == 0 then
		for _, Disc in Discs do
			if not Bodies[Disc].off then
				const Shot = ScanBank(Bodies, Disc)
				if Shot ~= nil then
					table.insert(Shots, Shot)
					break
				end
			end
		end
	end

	table.sort(Shots, function(A: Shot, B: Shot): boolean
		if A.Run ~= B.Run then
			return A.Run > B.Run
		end
		return A.Time < B.Time
	end)

	return Shots
end

-- // Fire

-- Hand the shot to the match session. It sends the Shot packet, simulates the
-- resolve locally and reports TurnResolved back to the server, exactly like a
-- real drag would. Safe to call out of turn: the session ignores it.
function core.Shoot(Shot: Shot): boolean
	const Live = Session()
	if Live == nil then
		return false
	end

	const Fire = Live._onMyShoot or Live._onPlayerShoot
	if Fire == nil then
		return false
	end

	Fire(Live, Shot.Disc, Shot.DirX, Shot.DirY, Shot.Power)

	return true
end

-- Solve and take the shot. Returns the shot it fired, or nil if nothing scores.
function core.Solve(Overrides: SolverConfig?): Shot?
	if not core.IsMyTurn() then
		return nil
	end

	const Shot = core.Find(Overrides)[1]
	if Shot == nil then
		return nil
	end

	if config.Fire and not core.Shoot(Shot) then
		return nil
	end

	return Shot
end

return core
