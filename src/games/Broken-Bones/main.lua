local Direction, Velocity = 0, 2000

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

UserInputService.InputChanged:Connect(function(InputType)
    if InputType.UserInputType == Enum.UserInputType.MouseWheel then
        if InputType.Position.Z > 0 then
			print("up")
            Direction = 1
        elseif InputType.Position.Z < 0 then
			print("down")
            Direction = -1
        end
    end
end)

UserInputService.InputBegan:Connect(function(InputType)
    if InputType.UserInputType == Enum.UserInputType.MouseButton3 then
		print("inactive")
        Direction = 0
    end
end)

local function HumanoidRootPart()
	local char = Players.LocalPlayer.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end

RunService.Heartbeat:Connect(function()
    local hrp = HumanoidRootPart()
    if hrp then
        if Direction ~= 0 then
            hrp.AssemblyLinearVelocity = Vector3.new(0, Velocity * Direction, 0)
        else
            hrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
        end
    end
end)
