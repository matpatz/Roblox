repeat
    task.wait()
until game:IsLoaded()

local Game = game

local Cache = {}

local Services = {}
setmetatable(Services, {
	__index = function(_, Index)
		local Cached = Cache[Index]
		if Cached then
			return Cached
		end
		local Service = cloneref(game:GetService(Index))
		Cache[Index] = Service

		return Cache[Index]
	end
})

if getgenv().PlayerHelper then
    local Player = Services.Players.LocalPlayer
    local Character = Player.Character or Player.CharacterAdded:Wait()

    Services.Player = Player
    Services.Character = Character
    Services.Humanoid = Character:FindFirstChildOfClass("Humanoid")
    Services.HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
    Services.Camera = Services.Workspace.CurrentCamera
    Services.Mouse = Player:GetMouse()

    Player.CharacterAdded:Connect(function(Character)
        Services.Character = Character
        Services.Humanoid = Character:FindFirstChildOfClass("Humanoid")
        Services.HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
    end)
end

return Services

-- Usage:

-- local Services = loadstring(
--     game:HttpGet("https://roblox-alpha-murex.vercel.app/src/Modules/Variables.lua")
-- )()

-- print(Services.Workspace)
-- print(Services.HumanoidRootPart)
