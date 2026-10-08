--[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]
game:GetService("RunService").Stepped:Connect(function()
	local hrp = game.Players.LocalPlayer.Character.HumanoidRootPart
    for _, brainrot in pairs(workspace.Brainrots:GetChildren()) do
        if brainrot:IsA("BasePart") then
			if firetouchinterest then
				firetouchinterest(hrp, brainrot, 0)
				firetouchinterest(hrp, brainrot, 1)
			else
				hrp.CFrame = brainrot.CFrame -- L executor :(((((
			end
        end
    end
end)
