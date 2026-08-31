-- // Template
-- Generic cheat scaffold. Copy to src/games/<Game>/main.lua, then fill in
-- every <Game> marker (targets / team checks / the shot hook).

-- // Services
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Players = game:GetService("Players")

-- // Modules

-- // LocalPlayer
const LocalPlayer = Players.LocalPlayer

if not LocalPlayer.Character then
	LocalPlayer.CharacterAdded:Wait()
end
local Character = LocalPlayer.Character
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

LocalPlayer.CharacterAdded:Connect(function(NewCharacter)
	Character = NewCharacter
	HumanoidRootPart = NewCharacter:WaitForChild("HumanoidRootPart")
	Humanoid = NewCharacter:WaitForChild("Humanoid")
end)

-- // cheat
local cheat = {
	Utils = {
		["Aimbot"] = {},
	},
	Core = {},
}
local Utils = cheat.Utils
local Core = cheat.Core

-- // config
local config = {
	SilentAim = {
		Enabled = true,
		Range = 400,
		AimPart = "Head",
		TeamCheck = false,
		WallCheck = true,
	},
}

local Aimbot = loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/Modules/Aimbot/main.lua"))()

-- // Utils

-- most times Players:GetPlayers() works fine

-- <Game>: return the valid target list. Default: other players, alive,
-- and (when TeamCheck is on) not on the local player's team.
Utils["Aimbot"].GetTargets = function(): { Instance }
	local Enemies: { Instance } = {}

	for _, Player in Players:GetPlayers() do
		if Player == LocalPlayer then
			continue
		end
		if not Player.Character then
			continue
		end

		-- <Game>: swap for the game's alive / team markers
		if Player:GetAttribute("IsDead") then
			continue
		end
		if config.SilentAim.TeamCheck then
			if Player:GetAttribute("Team") == LocalPlayer:GetAttribute("Team") then
				continue
			end
		end

		table.insert(Enemies, Player)
	end

	return Enemies
end

local aimconfig = {
    Origin, -- <Instance / Position> / camera / muzzle
    Range = config.SilentAim.Range,
    TeamCheck = false, -- if Player.Team is nil, and there are teams. You need to filter it manually with GetTargets
    AimPart = config.SilentAim.AimPart,
    Visible = config.SilentAim.WallCheck,
    EntityLists = {},
}

Utils["Aimbot"].GetClosest = function(): BasePart?
    aimconfig["Origin"] = HumanoidRootPart.Position
    aimconfig["EntityLists"] = {
        Utils["Aimbot"].GetTargets()
    }

	local _, AimPart = Aimbot.GetClosest(aimconfig)
	return AimPart
end

-- // Core

if isfunctionhooked(Raycast) then
    restorefunction(Raycast)
end

local Old; Old = hookfunction(Raycast, function(p1: number, p2: number, p3: number) -- use the parameter names from the original function
    if config.SilentAim.Enabled then
        const AimPart = Utils["Aimbot"].GetClosest()
        if AimPart then
            return {
                {
                    Position = AimPart.Position,
                    Instance = AimPart,
                    Normal = (AimPart.Position - HumanoidRootPart.Position).Unit,
                },
            }
        end
    end
    return Old(p1, p2, p3)
end)