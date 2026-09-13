-- // this_game — score solver
-- src/games/this_game/core.lua
--
-- Soccer pool: you shoot one of your discs, it knocks the ball, the ball has to
-- end up in the opponent's goal. The game ships its own deterministic physics
-- (ReplicatedStorage.Shared.Sim.SoccerSim) and hands the settled board to the
-- client in TurnOutcome.bodies, so this does NOT guess: it replays candidate
-- shots through the real simulation and only fires one that provably scores.
--
-- It also keeps the WIDEST scoring window it finds (the longest run of
-- neighbouring angles that also score) so a small desync with the server can't
-- turn a goal into a miss.

-- // Services

const ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // Modules

const Shared = ReplicatedStorage:WaitForChild("Shared")
const SoccerSim = require(Shared.Sim.SoccerSim)
const GameConfig = require(Shared.Config.GameConfig)
const Packets = require(Shared.Network.Packets)

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
	MinimumRun: number?, -- stop as soon as a run this wide scores
	Thorough: boolean?, -- scan every power instead of stopping at the first run
	BankStep: number?, -- degrees when sweeping the whole circle as a fallback
	BankPowers: { number }?,
	MaxTime: number?, -- give up on one shot after this many simulated seconds
	Fire: boolean?, -- send the shot once one is found
}

-- // Config

const config = {
	TargetGoal = 1,
	MyDiscs = { 1, 2, 3, 4, 5 },
	Powers = { 1, 0.85, 0.7, 0.55 },
	AngleStep = 0.5,
	MinimumRun = 3,
	Thorough = false,
	BankStep = 4,
	BankPowers = { 1, 0.8 },
	MaxTime = 7,
	Fire = true,
}

local core = {}
core.config = config

-- // Board

-- The server posts the settled board after every turn: 11 entries of x/y in sim
-- units (5 of our discs, 5 of theirs, ball last). Bodies between turns are at
-- rest, so the velocities are zero.
local function ToBodies(Payload: { { x: number, y: number } }): { any }
	const Bodies = SoccerSim.newBodies()
	for Index, Entry in Payload do
		const Body = Bodies[Index]
		if Body ~= nil then
			Body.x, Body.y = Entry.x, Entry.y
			Body.vx, Body.vy = 0, 0
		end
	end
	return Bodies
end

-- Latest board we have seen, or nil until the first turn resolves.
core.board = nil

for _, Name in { "TurnOutcome", "TurnResolved" } do
	const Packet = Packets[Name]
	if Packet ~= nil then
		pcall(function()
			Packet.listen(function(Data: any)
				const Payload = Data.bodies
				if type(Payload) == "table" and #Payload > 0 then
					core.board = ToBodies(Payload)
				end
			end)
		end)
	end
end

-- // Turn

-- MatchStart says which side we are, TurnStarted says whose turn it is.
-- turnID bumps on every turn so callers can shoot exactly once per turn.
core.mySide = nil
core.turnSide = nil
core.turnID = 0

if Packets.MatchStart ~= nil then
	pcall(function()
		Packets.MatchStart.listen(function(Data: any)
			core.mySide = Data.mySide
		end)
	end)
end

if Packets.TurnStarted ~= nil then
	pcall(function()
		Packets.TurnStarted.listen(function(Data: any)
			core.turnSide = Data.side
			core.turnID += 1
		end)
	end)
end

-- True while the server says it is our turn to shoot. If the script was
-- injected mid-match MatchStart was missed and mySide is unknown, so any turn
-- counts as ours and the server just ignores a shot that wasn't ours.
function core.IsMyTurn(): boolean
	if core.turnSide == nil then
		return false
	end
	if core.mySide == nil then
		return true
	end
	return core.turnSide == core.mySide
end

-- // Simulation

-- Replay a shot on a copy of the board; returns whether it scores for us and
-- how long the ball took to cross the line.
local function Play(Bodies: { any }, Disc: number, DirX: number, DirY: number, Power: number): (boolean, number)
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

-- Sample the cone of directions that actually reach the ball and keep the
-- longest unbroken run of scoring samples: its middle is the safest aim.
local function ScanCone(Bodies: { any }, Disc: number, Ball: any): Shot?
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

	local Best: Shot? = nil

	for _, Power in config.Powers do
		local RunStart: number? = nil
		local RunLength = 0
		local BestStart: number? = nil
		local BestLength = 0
		local BestTime = 0

		for Step = 0, Steps do
			const Angle = Base - Spread + (Step / Steps) * Spread * 2
			const Scored, Time = Play(Bodies, Disc, math.cos(Angle), math.sin(Angle), Power)

			if Scored then
				if RunStart == nil then
					RunStart = Step
				end
				RunLength += 1
				BestTime = Time
				if RunLength > BestLength then
					BestLength = RunLength
				end
			else
				if RunLength > BestLength then
					BestStart, BestLength = RunStart, RunLength
				end
				RunStart, RunLength = nil, 0
			end
		end
		if RunLength > BestLength then
			BestStart, BestLength = RunStart, RunLength
		end

		if BestStart ~= nil and BestLength >= config.MinimumRun then
			const Middle = BestStart + (BestLength - 1) / 2
			const Angle = Base - Spread + (Middle / Steps) * Spread * 2
			const Shot: Shot = {
				Disc = Disc,
				DirX = math.cos(Angle),
				DirY = math.sin(Angle),
				Power = Power,
				Time = BestTime,
				Run = BestLength,
			}
			if not config.Thorough then
				return Shot
			end
			if Best == nil or BestLength > Best.Run then
				Best = Shot
			end
		end
	end

	return Best
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

-- Every shot that scores, widest window first. Bank shots are only searched
-- when no direct hit on the ball can score.
function core.Find(Overrides: SolverConfig?): { Shot }
	if Overrides ~= nil then
		for Key, Value in Overrides do
			if Value ~= nil then
				config[Key] = Value
			end
		end
	end

	const Bodies = core.board
	assert(Bodies ~= nil, "core: no board yet, wait for a TurnOutcome")

	const Ball = Bodies[SoccerSim.BALL]
	const Shots: { Shot } = {}

	for _, Disc in config.MyDiscs do
		if not Bodies[Disc].off then
			const Shot = ScanCone(Bodies, Disc, Ball)
			if Shot ~= nil then
				table.insert(Shots, Shot)
			end
		end
	end

	if #Shots == 0 then
		for _, Disc in config.MyDiscs do
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
		return A.Run > B.Run
	end)

	return Shots
end

-- // Fire

-- The shot packet carries the board we solved against, and the server replays
-- that exact state (x/y only, no velocities).
local function Serialise(Bodies: { any }): { { x: number, y: number } }
	const Payload = table.create(#Bodies)
	for Index, Body in Bodies do
		Payload[Index] = { x = Body.x, y = Body.y }
	end
	return Payload
end

-- Solve and take the shot. Returns the shot it fired, or nil if nothing scores.
function core.Solve(Overrides: SolverConfig?): Shot?
	if core.board == nil then
		return nil
	end

	const Shot = core.Find(Overrides)[1]
	if Shot == nil then
		return nil
	end

	if config.Fire then
		Packets.Shot.send({
			disc = Shot.Disc,
			dirX = Shot.DirX,
			dirY = Shot.DirY,
			power = Shot.Power,
			bodies = Serialise(core.board),
		})
	end

	return Shot
end

return core
