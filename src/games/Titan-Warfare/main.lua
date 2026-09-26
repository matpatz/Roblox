-- // Knit
const Knit = shared.Knit
const conmanager = Knit.conmanager

-- // Services
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Players = game:GetService("Players")
const RunService = game:GetService("RunService")
const CollectionService = game:GetService("CollectionService")

-- // Remotes
const Remotes = ReplicatedStorage:WaitForChild("Remotes")
const BladesHit = Remotes.Blades.Hit
const TitansPunch = Remotes.Titans.Punch
const GunsFire = Remotes.Guns.Fire
const GunsBazookaFire = Remotes.Guns.BazookaFire
const RedeemCode = Remotes.General.RedeemCode

--// Workspace
local Titans = workspace.Objects.Titans

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

-- // config
local config = {
	Combat = {
		KillAura = false,
		AutoPunch = false,
		SoldierAura = false
	},
	Visuals = {
		TitanEsp = false,
		PlayerEsp = false
	}
}

-- // cheat
local cheat = {
	Utils = {
        ["Soldier"] = {},
        ["Titan"] = {}
    }
}
local Utils = cheat.Utils

-- // team

-- Sides are the Eldian / Marleyan teams. Players.Team stays nil until a round hands
-- you one, so fall back to the replicated currentTeam value.
function Utils.GetTeam(Player)
	const Team = Player.Team

	if Team then
		return Team.Name
	end

	const Data = Player:FindFirstChild("ReplicatedData")
	const CurrentTeam = Data and Data:FindFirstChild("currentTeam")

	return CurrentTeam and CurrentTeam.Value
end

function Utils.IsEnemy(Player)
	if Player == LocalPlayer then
		return false
	end

	const Team = Utils.GetTeam(Player)
	const LocalTeam = Utils.GetTeam(LocalPlayer)

	return Team ~= nil and LocalTeam ~= nil and Team ~= LocalTeam
end

function Utils.Soldier.GetClosest()
	local Nearest = nil
	local NearestDistance = math.huge

	for _, Player in Players:GetPlayers() do
		const TargetCharacter = Player.Character
        if not TargetCharacter then
            continue
        end

		const TargetHumanoid = TargetCharacter:FindFirstChildOfClass("Humanoid")
        if not TargetHumanoid then
            continue
        end
		const Hitbox = TargetCharacter:FindFirstChild("PlayerHitbox")
        if not Hitbox then
            continue
        end

		if TargetHumanoid.Health > 0 and Utils.IsEnemy(Player) then
			const Distance = (Hitbox.Position - HumanoidRootPart.Position).Magnitude

			if Distance < NearestDistance then
				Nearest = Player
				NearestDistance = Distance
			end
		end
	end

	return Nearest
end

function Utils.Titan.GetClosest()
	local Nearest = nil
	local NearestDistance = math.huge

	for _, Titan in Titans:GetChildren() do
		const TitanHumanoid = Titan:FindFirstChildOfClass("Humanoid")
		const Hitbox = Titan:FindFirstChild("Nape")

		if TitanHumanoid and TitanHumanoid.Health > 0 and Hitbox then
			const Distance = (Hitbox.Position - HumanoidRootPart.Position).Magnitude

			if Distance < NearestDistance then
				Nearest = Titan
				NearestDistance = Distance
			end
		end
	end

	return Nearest
end

-- // Esp

const Esp = loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/Libraries/Esp/main.lua"))()

-- Both containers live in one table, so a toggle only swaps its own Location:
-- emptying a Location hides that container without dropping the other one.
local EspContainers = {
	Titans = { Location = Titans, Color = Color3.fromRGB(255, 60, 60) },
	Players = { Location = Players }
}

-- // Interface

const Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
const Window = Rayfield:CreateWindow({
	Name = "Titan Warfare",
	LoadingTitle = "Titan Warfare",
	KeySystem = false
})

const Combat = Window:CreateTab("Main", 4483362458)
Combat:CreateLabel("Titan", "wind")

Combat:CreateToggle({
	Name = "Kill Aura (Eldian / Pve)",
	CurrentValue = config.Combat.KillAura,
	Flag = "ka",
	Callback = function(Value)
		config.Combat.KillAura = Value

		if not Value then
			conmanager.disconnect("KillAura")

			return
		end

		-- the game's own blade damage scales with swing speed, 401 drops titans fast.
		-- Same gate the game uses for its titan helpers: a Nape part on a live titan.
		conmanager.connect("KillAura", RunService.Heartbeat, function()
            local Titan = Utils["Titan"].GetClosest()
            if not Titan then
                return
            end
            local Nape = Titan:FindFirstChild("Nape")
            --local TitanHumanoid = Titan:FindFirstChildOfClass("Humanoid")

            BladesHit:FireServer(Nape, 401)
		end)
	end
})

Combat:CreateToggle({
	Name = "Auto punch as Titan",
	CurrentValue = config.Combat.AutoPunch,
	Flag = "apt",
	Callback = function(Value)
		config.Combat.AutoPunch = Value

		if not Value then
			conmanager.disconnect("AutoPunch")

			return
		end

		-- Punch takes the same boolean the game passes from attack(false) / attack(true)
		conmanager.connect("AutoPunch", RunService.Heartbeat, function()
			-- the game tags every titan humanoid, so this only punches while actually a titan
			if not CollectionService:HasTag(Humanoid, "TitanShifted") then
				return
			end

			TitansPunch:FireServer(false)
		end)
	end
})

Combat:CreateLabel("Pvp", "wind")

Combat:CreateToggle({
	Name = "Soldier Aura",
	CurrentValue = config.Combat.SoldierAura,
	Flag = "sniper",
	Callback = function(Value)
		config.Combat.SoldierAura = Value

		if not Value then
			conmanager.disconnect("SoldierAura")

			return
		end

		conmanager.connect("SoldierAura", RunService.Heartbeat, function()
			const Target = Utils["Soldier"].GetClosest()

			if not Target then
				return
			end

			const TargetCharacter = Target.Character
			const Head = TargetCharacter.Head
			const RootPart = TargetCharacter.HumanoidRootPart

			-- the game fires these as ("Sniper", impactCFrame, hitInstance, hitNormal)
			-- and (impactCFrame, hitInstance)
			GunsFire:FireServer("Sniper", CFrame.new(Head.Position), Head)
			GunsBazookaFire:FireServer(CFrame.new(RootPart.Position), RootPart)
		end)
	end
})

const Visuals = Window:CreateTab("Visuals")
Visuals:CreateLabel("Titans")

Visuals:CreateToggle({
	Name = "Titan Esp",
	CurrentValue = config.Visuals.TitanEsp,
	Flag = "tesp",
	Callback = function(Value)
		config.Visuals.TitanEsp = Value

		EspContainers.Titans.Location = Value and Titans or {}
		Esp:SetContainer(EspContainers)

		if config.Visuals.TitanEsp or config.Visuals.PlayerEsp then
			Esp:Enable()
		else
			Esp:Disable()
		end
	end
})

Visuals:CreateLabel("Players")

Visuals:CreateToggle({
	Name = "Player Esp",
	CurrentValue = config.Visuals.PlayerEsp,
	Flag = "pesp",
	Callback = function(Value)
		config.Visuals.PlayerEsp = Value

		EspContainers.Players.Location = Value and Players or {}
		Esp:SetContainer(EspContainers)

		if config.Visuals.TitanEsp or config.Visuals.PlayerEsp then
			Esp:Enable()
		else
			Esp:Disable()
		end
	end
})

const Shop = Window:CreateTab("Shop", 4483362458)
Shop:CreateLabel("Codes", "wind")

const codes = { "STOP_EREN", "STOP_THE_RUMBLING", "THIS_IS_FREEDOM", "GIANT_SPINE", "FREEDOM_IS_HERE", "BREAK_FREEEEEE", "TRUE_FREEDOM", "IF_I_LOSE_IT_ALL", "MIKASA_SUKASA", "ILOVETITANWARFARE", "HANG3", "45KLIKESYAY" }

Shop:CreateButton({
	Name = "Redeem all Codes",
	Callback = function()

		for _, code in codes do
			RedeemCode:InvokeServer(code)
		end
	end
})

Rayfield:Notify({
	Title = "Titan Warfare",
	Content = "successfully loaded!",
	Duration = 5,
	Image = 4483362458
})
