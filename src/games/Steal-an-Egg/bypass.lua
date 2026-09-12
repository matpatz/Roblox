--[[
	Steal an Egg — ContentCatalog / Runtime movement anticheat bypass.

	The game runs a client anticheat suite (Runtime, Impact, ArcModel, AxisDelta,
	Surface, Blend, ...). The loader parents the whole tree to nil and destroys the
	ModuleScripts afterwards — that is why they show up in getnilinstances() and why
	`require(Instance)` fails with
		"Requested module has been destroyed and can no longer be required".

	What it can not hide is the live per-player state record Runtime hands to the
	validator: a plain Lua table (SampleHistory / Evidence / MovementMode / ...) that
	sits in the GC. Every tick the validator samples the root part into it and looks for
	Speed / Teleport / Flight evidence against the sample history.

	Runtime.AdoptTeleportBaseline() is the suite's own "this jump was legitimate" escape
	hatch — the one it uses when the game itself teleports you. It wipes history and
	evidence, re-seeds LastObservedSample / LastValidatedSample / ... from a fresh
	sample and re-opens the Initializing grace window, so the next tick has nothing to
	compare the new position against.

	We can not call it (destroyed module + internal guard token), so we do exactly what
	it does, by hand, on the state table — in the same frame as the teleport, so no
	validator tick can ever observe the old position.

	Usage:
		local Bypass = loadstring(game:HttpGet(".../Steal-an-Egg/bypass.lua"))()
		Bypass.Core.Teleport(workspace.AreaEggSlotsClient.SomeEgg)
		Bypass.Core.Teleport(Vector3.new(0, 50, 0))
]]

-- // Services
const Players = game:GetService("Players")
const Workspace = game:GetService("Workspace")

-- // LocalPlayer
const LocalPlayer = Players.LocalPlayer

-- // config
local config = {
	-- Grace window seeded after a teleport. Runtime derives its real InitializationDuration
	-- from Limits; ours only has to be long enough that the first validated tick is the
	-- re-seeded baseline.
	InitializingGrace = 1,

	-- Surface.IsStrictlySupported casts (ExpectedHipHeight + ExpectedRootHalfHeight +
	-- GroundClearanceTolerance) downwards. The real tolerance lives in Limits, this is
	-- close enough for the support probe.
	SupportTolerance = 0.25
}

-- // cheat
local cheat = {
	Utils = {

	},
	Core = {

	}
}
local Utils = cheat.Utils
local Core = cheat.Core

-- // Utils

-- Does this table look like a Runtime movement state record?
Utils.IsRuntimeState = function(Value)
	if type(Value) ~= "table" then
		return false
	end

	return rawget(Value, "SampleHistory") ~= nil
		and rawget(Value, "Evidence") ~= nil
		and rawget(Value, "MovementMode") ~= nil
		and rawget(Value, "HistoryCapacity") ~= nil
end

-- Scans the GC for the state record of a player (the module that owns it is destroyed).
Utils.FindRuntimeState = function(Player)
	if type(getgc) ~= "function" then
		return nil
	end

	for _, Value in next, getgc(true) do
		if Utils.IsRuntimeState(Value) and Value.Player == Player then
			return Value
		end
	end

	return nil
end

-- Cached lookup, re-scanned when the cache goes stale (respawn / anticheat reload).
Utils.GetRuntimeState = function(Player)
	local Cached = Utils.State

	if Cached ~= nil and Cached.Player == Player and Utils.IsRuntimeState(Cached) then
		return Cached
	end

	Utils.State = Utils.FindRuntimeState(Player)

	return Utils.State
end

Utils.NewVerticalSegmentDecision = function()
	return {
		Timestamp = 0,
		PreviousY = 0,
		CurrentY = 0,
		Displacement = 0,
		Elapsed = 0,
		PreviousVerticalMotion = 0,
		UseJumpPower = true,
		JumpPower = 0,
		JumpHeight = 0,
		JumpLaunchSpeed = 0,
		Gravity = 0,
		AllowedDistance = 0,
		Excess = 0,
		Ratio = 0,
		Reliable = false,
		MovementContext = "None",
		Decision = "NoAdjacentSample",
		CorrectionStarted = false,
		CorrectionTarget = nil,
		CorrectionTargetAge = nil,
		CorrectionFailure = nil
	}
end

Utils.NewVerticalTrajectoryDecision = function()
	return {
		Timestamp = 0,
		Active = false,
		StartedAt = nil,
		StartY = nil,
		CurrentY = 0,
		PeakY = 0,
		AllowedRise = 0,
		AirborneDuration = 0,
		AllowedAirborneDuration = 0,
		RecentYChange = nil,
		MinimumAcceptableDescent = nil,
		MeaningfulDescent = false,
		LandingCandidate = false,
		LandingDuration = 0,
		Evidence = 0,
		EvidenceEventCount = 0,
		ConsecutiveInvalidWindows = 0,
		PrimaryEvidenceSource = "None",
		LatestLegalSampleAge = nil,
		CorrectionStarted = false,
		CorrectionTarget = nil,
		CorrectionTargetAge = nil,
		CorrectionFailure = nil
	}
end

-- Runtime.MakeSample fills these from Limits. We inherit them from the last real sample
-- so the baseline we fake is identical to one the validator made itself.
Utils.GetSampleDefaults = function(State)
	local Base = State.LastObservedSample
		or State.LastSample
		or State.LastValidatedSample
		or State.LastGoodSample
		or (State.GroundContactWitness and State.GroundContactWitness.ContactSample)

	return {
		UseJumpPower = Base and Base.UseJumpPower or true,
		JumpPower = Base and Base.JumpPower or 50,
		JumpHeight = Base and Base.JumpHeight or 7.2
	}
end

-- Surface.IsStrictlySupported: one downward raycast, CanCollide decides.
Utils.IsStrictlySupported = function(State, RootPart)
	local Distance = (State.ExpectedHipHeight or 0) + (State.ExpectedRootHalfHeight or 0) + config.SupportTolerance

	local Ok, Result = pcall(function()
		return Workspace:Raycast(RootPart.Position, Vector3.new(0, -Distance, 0), State.SupportRaycastParams)
	end)

	return Ok and Result ~= nil and Result.Instance.CanCollide == true
end

-- Runtime.MakeSample, rebuilt from the live state/character.
Utils.MakeSample = function(State, RootPart, Humanoid)
	local Character = State.Character

	if Character == nil or LocalPlayer.Character ~= Character then
		return nil
	end

	if not (RootPart:IsDescendantOf(Character) and Humanoid:IsDescendantOf(Character)) then
		return nil
	end

	local Defaults = Utils.GetSampleDefaults(State)

	return {
		Timestamp = os.clock(),
		CFrame = RootPart.CFrame,
		Position = RootPart.Position,
		WalkSpeed = Humanoid.WalkSpeed,
		UseJumpPower = Defaults.UseJumpPower,
		JumpPower = Defaults.JumpPower,
		JumpHeight = Defaults.JumpHeight,
		Gravity = Workspace.Gravity,
		IsSupported = Utils.IsStrictlySupported(State, RootPart),
		HumanoidState = Humanoid:GetState(),
		LinearVelocity = RootPart.AssemblyLinearVelocity,
		AngularVelocity = RootPart.AssemblyAngularVelocity
	}
end

-- Runtime.PushSample (ring buffer).
Utils.PushSample = function(State, Sample)
	local Index

	if State.HistoryCount < State.HistoryCapacity then
		Index = (State.HistoryHead + State.HistoryCount - 1) % State.HistoryCapacity + 1
		State.HistoryCount = State.HistoryCount + 1
	else
		Index = State.HistoryHead
		State.HistoryHead = State.HistoryHead % State.HistoryCapacity + 1
	end

	State.SampleHistory[Index] = Sample
end

-- Runtime.PushSafeGroundCheckpoint (ring buffer).
Utils.PushSafeGroundCheckpoint = function(State, Sample)
	if not Sample.IsSupported then
		return
	end

	local Index

	if State.SafeGroundCheckpointCount < State.SafeGroundCheckpointCapacity then
		Index = (State.SafeGroundCheckpointHead + State.SafeGroundCheckpointCount - 1) % State.SafeGroundCheckpointCapacity + 1
		State.SafeGroundCheckpointCount = State.SafeGroundCheckpointCount + 1
	else
		Index = State.SafeGroundCheckpointHead
		State.SafeGroundCheckpointHead = State.SafeGroundCheckpointHead % State.SafeGroundCheckpointCapacity + 1
	end

	State.SafeGroundCheckpoints[Index] = Sample
end

-- Runtime.AdoptTeleportBaseline, inlined: resetMovementFields + payload.
-- Call this right after moving the character yourself; Core.Teleport does it for you.
Utils.AdoptTeleportBaseline = function(State, RootPart, Humanoid)
	local Sample = Utils.MakeSample(State, RootPart, Humanoid)

	if Sample == nil then
		return false
	end

	-- // resetMovementFields
	for Index = 1, State.HistoryCapacity do
		State.SampleHistory[Index] = nil
	end

	State.HistoryHead = 1
	State.HistoryCount = 0

	for Index = 1, State.SafeGroundCheckpointCapacity do
		State.SafeGroundCheckpoints[Index] = nil
	end

	State.SafeGroundCheckpointHead = 1
	State.SafeGroundCheckpointCount = 0

	State.MovementMode = "Initializing"
	State.AirbornePhase = nil
	State.LastObservedSample = nil
	State.LastGameplayTrustedSample = nil
	State.LastValidatedSample = nil
	State.LastValidatedGroundedSample = nil
	State.LastConfirmedGroundSample = nil
	State.CandidateGroundedSample = nil
	State.CandidateGroundedStartedAt = nil
	State.IsSupportedNow = false
	State.LastSupportedAt = nil
	State.UnsupportedStartedAt = nil
	State.SupportStartedAt = nil
	State.HighestYSinceGround = nil
	State.WasMeaningfullyFalling = false
	State.FirstSuspiciousAt = nil
	State.Evidence = {
		Speed = 0,
		Teleport = 0,
		Flight = 0
	}
	State.HorizontalDebug = {
		Short = nil,
		Main = nil,
		Long = nil
	}
	State.LastVerticalSegmentDecision = Utils.NewVerticalSegmentDecision()
	State.VerticalTrajectory = nil
	State.LastVerticalTrajectoryDecision = Utils.NewVerticalTrajectoryDecision()
	State.ThreatLevel = "Trusted"
	State.LastViolationReason = nil
	State.LastViolationAt = nil
	State.LastCorrectionAt = 0
	State.InitializingUntil = Sample.Timestamp + config.InitializingGrace
	State.UncertainUntil = nil
	State.LastTelemetryAt = 0
	State.LastTelemetryReason = nil
	State.TelemetryRepeatCount = 0
	State.CorrectionContext = nil
	State.ImpulseContext = nil
	State.ValidationLocked = true
	State.ValidationStartedAt = nil
	State.LastSample = nil
	State.LastGoodSample = nil
	State.Allowances = {}
	State.ContinuousAllowances = {}
	State.PendingCommit = nil
	State.GroundContactWitness = nil

	-- // baseline payload
	Utils.PushSample(State, Sample)

	State.LastObservedSample = Sample
	State.LastGameplayTrustedSample = Sample
	State.LastValidatedSample = Sample
	State.LastSample = Sample
	State.LastGoodSample = Sample
	State.ValidationLocked = false
	State.ValidationStartedAt = Sample.Timestamp
	State.IsSupportedNow = Sample.IsSupported
	State.HighestYSinceGround = Sample.Position.Y

	if Sample.IsSupported then
		State.LastValidatedGroundedSample = Sample
		State.LastConfirmedGroundSample = Sample
		State.LastSupportedAt = Sample.Timestamp
		State.SupportStartedAt = Sample.Timestamp
		State.MovementMode = "Grounded"

		Utils.PushSafeGroundCheckpoint(State, Sample)
	else
		State.UnsupportedStartedAt = Sample.Timestamp
		State.MovementMode = "Initializing"
	end

	return true
end

-- CFrame / Vector3 / BasePart / Model / Attachment -> position + rotation
Utils.ResolveTarget = function(Target, RootPart)
	local Kind = typeof(Target)

	if Kind == "CFrame" then
		return Target.Position, Target.Rotation
	end

	if Kind == "Vector3" then
		return Target, RootPart.CFrame.Rotation
	end

	if Kind == "Instance" then
		if Target:IsA("BasePart") then
			return Target.Position, Target.CFrame.Rotation
		end

		if Target:IsA("Attachment") then
			return Target.WorldPosition, RootPart.CFrame.Rotation
		end

		if Target:IsA("Model") then
			local Pivot = Target:GetPivot()

			return Pivot.Position, Pivot.Rotation
		end
	end

	return nil
end

-- // Core

Core.Teleport = function(Target)
	local Character = LocalPlayer.Character

	if Character == nil then
		return false
	end

	local RootPart = Character:FindFirstChild("HumanoidRootPart")
	local Humanoid = Character:FindFirstChildOfClass("Humanoid")

	if RootPart == nil or Humanoid == nil then
		return false
	end

	local Position, Rotation = Utils.ResolveTarget(Target, RootPart)

	if Position == nil then
		return false
	end

	-- Move and re-seed without yielding, so the next validator tick already sees the new
	-- position as the baseline instead of a teleport.
	RootPart.CFrame = CFrame.new(Position) * Rotation

	local State = Utils.GetRuntimeState(LocalPlayer)

	if State ~= nil then
		Utils.AdoptTeleportBaseline(State, RootPart, Humanoid)
	end

	return true
end

return cheat
