local aimbot = {}

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
function aimbot.Range(PlayerRoot: BasePart, TargetRoot: BasePart): number
	return (PlayerRoot.Position - TargetRoot.Position).Magnitude
end

function aimbot.GetTargets(PlayerRoot: BasePart, Range: number, EntityList): { Player }
	local Targets = {}

	for _, Object in next, Players:GetPlayers() do
        if Object == Player then
            continue
        end
		local Character = Object.Character
		if not Character then
			continue
		end

		local TargetRoot = Character:WaitForChild("HumanoidRootPart", 2)
		if not TargetRoot then
			continue
		end

		if aimbot.Range(PlayerRoot, TargetRoot) > Range and Range or 200 then
			continue
		end

		table.insert(Targets, Object)
	end
    for _, Object in next, EntityList or {} do
        local TargetRoot = Object:WaitForChild("HumanoidRootPart", 2)
        if not TargetRoot then
            continue
        end

        table.insert(Targets, Object)
    end

	return Targets
end

-- local Camera = workspace.CurrentCamera
-- local Origin = Camera.CFrame.Position

function aimbot.Raycast(Origin: Vector3, Target: Model): Vector3?
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

function aimbot.GetClosest(PlayerRoot: BasePart, Range: number, Targets: { Player }): Player?
	local Closest = nil

	for _, Target in next, Targets do
		local TargetRoot = Target:FindFirstChild("HumanoidRootPart")
		if not TargetRoot then
			continue
		end

		local Distance = aimbot.Range(PlayerRoot, TargetRoot)
		if Distance < Range then
			Range = Distance
			Closest = Target
		end
	end

	return Closest
end

return aimbot