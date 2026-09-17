local player = {}

local Knit = shared.Knit
local services = Knit.services

local LocalPlayer = services.Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

local function update(Character)
    player.Character = Character
    player.Humanoid = Character:FindFirstChildOfClass("Humanoid")
    player.HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
end

player["local"] = LocalPlayer
player.Character = Character
player.Humanoid = Character:FindFirstChildOfClass("Humanoid")
player.HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")

LocalPlayer.CharacterAdded:Connect(update)

return player