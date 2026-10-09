local playermanager = {}

local Knit = shared.Knit
local services = Knit.services

local LocalPlayer = services.Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

local function update(NewCharacter)
    playermanager.Character = NewCharacter
    playermanager.Humanoid = NewCharacter:FindFirstChildOfClass("Humanoid")
    playermanager.HumanoidRootPart = NewCharacter:FindFirstChild("HumanoidRootPart")
end

playermanager.LocalPlayer = LocalPlayer

LocalPlayer.CharacterAdded:Connect(update)
update(Character)

return playermanager