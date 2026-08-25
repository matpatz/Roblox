local aimbot = {}

local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local function GetOrigin(PlayerRoot: BasePart | Vector3): Vector3
	if typeof(PlayerRoot) == "Vector3" then
		return PlayerRoot
	end
	return PlayerRoot.Position
end

function aimbot.Range(PlayerRoot: BasePart | Vector3, TargetRoot: BasePart): number
	return (GetOrigin(PlayerRoot) - TargetRoot.Position).Magnitude
end

function aimbot.GetTargets(PlayerRoot: BasePart | Vector3, Range: number, EntityList: { Instance }): { Instance }
	local Targets = {}

	if EntityList ~= nil then
		for _, Object in next, EntityList do
			local TargetRoot = Object:FindFirstChild("HumanoidRootPart", true)
			if not TargetRoot then
				continue
			end

			table.insert(Targets, Object)
		end

		return Targets
	end

	-- Only used when no entity list is provided (fallback to other players)
	for _, Object in next, Players:GetPlayers() do
		if Object == Player then
			continue
		end
		local Character = Object.Character
		if not Character then
			continue
		end

		local TargetRoot = Character:FindFirstChild("HumanoidRootPart")
		if not TargetRoot then
			continue
		end

		if aimbot.Range(PlayerRoot, TargetRoot) > Range then
			continue
		end

		table.insert(Targets, Object)
	end

	return Targets
end

-- local Camera = workspace.CurrentCamera
-- local Origin = Camera.CFrame.Position

function aimbot.Raycast(Origin: Vector3, Target: Model?): Vector3?
	local Root = Target:FindFirstChild("HumanoidRootPart")
	if not Root then
		return nil
	end

	local Params = RaycastParams.new()
	Params.FilterType = Enum.RaycastFilterType.Exclude
	Params.FilterDescendantsInstances = { Player.Character }

	local Direction = Root.Position - Origin

	local Result = workspace:Raycast(Origin, Direction, Params)

	if Result then
		return Result.Position
	end

	return Origin + Direction
end

function aimbot.GetClosest(PlayerRoot: BasePart | Vector3, Range: number, Targets: { Instance }): (Instance?, BasePart?)
	local Closest = nil
	local ClosestRoot = nil

	for _, Target in next, Targets do
		local Character = nil
		if Target:IsA("Player") then
			Character = Target.Character
		elseif Target:IsA("Model") then
			Character = Target
		elseif Target:IsA("BasePart") and Target.Parent then
			Character = Target.Parent
		else
			continue
		end

		local TargetRoot = nil
		if Character ~= nil then
			TargetRoot = Character:FindFirstChild("HumanoidRootPart")
		end
		if TargetRoot == nil then
			continue
		end

		local Distance = aimbot.Range(PlayerRoot, TargetRoot)
		if Distance < Range then
			Range = Distance
			Closest = Target
			ClosestRoot = TargetRoot
		end
	end

	return Closest, ClosestRoot
end

return aimbot