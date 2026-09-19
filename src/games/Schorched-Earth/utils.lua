local utils = {
	["Aimbot"] = {},
}

local Knit = shared.Knit
local services = Knit.services
local playermanager = Knit.player
local scriptmanager = Knit.scriptmanager

--// services
local Players = services.Players
local LocalPlayer = Players.LocalPlayer

-- // config
local config = {
	SilentAim = {
		Enabled = true,
		Range = 400,
		AimPart = "Head",
		TeamCheck = true,
		WallCheck = true,
	},
}

local Aimbot = loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/Modules/Aimbot/v1/main.lua"))()

-- // Utils

utils["Aimbot"].GetTargets = function(): { Instance }
	local Enemies: { Instance } = {}

	local function IsTeammate(Model: Model): boolean
		local Player = Players:GetPlayerFromCharacter(Model)

		-- a bot owns no player, and a game without teams has nothing to compare
		if not Player or not Player.Team or not LocalPlayer.Team then
			return false
		end

		return Player.Team == LocalPlayer.Team
	end

	local function AddCharacter(Model: Model?)
		if not Model then
			return
		end

		local Humanoid = Model:FindFirstChildOfClass("Humanoid")
		if not Humanoid or Humanoid.Health <= 0 then
			return
		end

		if config.SilentAim.TeamCheck and IsTeammate(Model) then
			return
		end

		table.insert(Enemies, Model)
	end

	for _, Player in Players:GetPlayers() do
		if Player == LocalPlayer then
			continue
		end

		AddCharacter(Player.Character)
	end

	return Enemies
end

local aimconfig = {
    Origin,
    Range = config.SilentAim.Range,
    TeamCheck = false, -- pre filtered in GetTargets
    AimPart = config.SilentAim.AimPart,
    Visible = config.SilentAim.WallCheck,
    EntityLists = {},
}

utils["Aimbot"].GetClosest = function(): BasePart?
    -- playermanager is filled in a moment after the modules load, so the root
    -- is read per shot instead of once at load
    local HumanoidRootPart = playermanager.HumanoidRootPart
    if not HumanoidRootPart then
        return nil
    end

    aimconfig["Origin"] = HumanoidRootPart.Position
    aimconfig["EntityLists"] = {
        utils["Aimbot"].GetTargets()
    }

	local _, AimPart = Aimbot.GetTarget(aimconfig)
	return AimPart
end

    
scriptmanager.set("utils", utils)

return utils