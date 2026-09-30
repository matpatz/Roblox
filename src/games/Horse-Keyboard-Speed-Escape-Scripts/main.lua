local Connection


local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local HumanoidRootPart = LocalPlayer.Character:WaitForChild("HumanoidRootPart");
local cd = 0

Connection = RunService.RenderStepped:Connect(function(dt)
	ReplicatedStorage.Remotes.AddSteps:FireServer()

	cd += dt
	if cd >= 2.5 then
		cd = 0
		task.spawn(function()
			HumanoidRootPart:PivotTo(CFrame.new(-115.409325, 90.7936554, -1331.14722, 1, 0, 0, 0, 1, 0, 0, 0, 1))
            task.wait(0.2)
			HumanoidRootPart:PivotTo(CFrame.new(-230.101059, 1016.67267, -33124.582, 0.999997079, -0, -0.00241701491, 0, 1, -0, 0.00241701491, 0, 0.999997079))
		end)
	end
end)

-- Connection:Disconnect()
