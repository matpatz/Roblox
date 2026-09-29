--[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]
local dir, velocity = 0, 2000

local input = game:GetService("UserInputService")
input.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseWheel then
        if input.Position.Z > 0 then
            dir = 1
        elseif input.Position.Z < 0 then
            dir = -1
        end
    end
end)

input.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton3 then
        dir = 0
    end
end)

local function get() local char = game:GetService("Players").LocalPlayer.Character return char and char:FindFirstChild("HumanoidRootPart") end

game:GetService("RunService").Heartbeat:Connect(function()
    local hrp = get()
    if hrp then
        if dir ~= 0 then
            hrp.AssemblyLinearVelocity = Vector3.new(0, velocity * dir, 0)
        else
            hrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
        end
    end
end)
