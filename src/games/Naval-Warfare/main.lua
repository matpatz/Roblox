--// Services
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Players = game:GetService("Players")
--[[const TweenService = game:GetService("TweenService")
const RunService = game:GetService("RunService")
const CoreGui = cloneref(game:GetService("CoreGui"))]]

--// Events
local Event = ReplicatedStorage.Event

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

local Tool = Character:FindFirstChildOfClass("Tool")
Character.ChildAdded:Connect(function(Instance)
    if Instance:IsA("Tool") then
        Tool = Instance
    end
end)

-- // cheat
local cheat = {
	Utils = {

	},
	Core = {

	}
}
local Utils = cheat.Utils
local Core = cheat.Core

-- // config
local config = {
	KillAura = {
		Rifle = {
			Enabled = false
		},
		Turret = {
			Enabled = false
		}
	}
}

-- // connections
local Connections = {}

Utils.Connect = function(Key, Signal, Callback)
	Utils.Disconnect(Key)
	if typeof(Signal) == "Instance" and Signal:IsA("RemoteEvent") then
		Signal = Signal.OnClientEvent
	end
	Connections[Key] = Signal:Connect(Callback)
end

Utils.Disconnect = function(Key)
	if Connections[Key] then
		Connections[Key]:Disconnect()
		Connections[Key] = nil
	end
end

-- // targeting

type Enemys = "Player" | "Vehicle"
type ClosestResult = (Model?) & (number)

Utils.GetClosest = function(EnemyType: Enemys): ClosestResult
    local Enemys = {}
    local Closest = nil
    local ClosestDistance = math.huge

    if EnemyType == "Player" then
        Enemys = Players:GetPlayers()
	elseif EnemyType == "Vehicle" then
		Enemys = workspace:QueryDescendants("Model:has(Seat), Model:has(VehicleSeat)")
	end

    for _, Enemy in Enemys do
        if Enemy == LocalPlayer then
			continue
		end
		if Enemy.Team == LocalPlayer.Team then
			continue
		end

        local EnemyCharacter = if EnemyType == "Player" then Enemy.Character else Enemy
        if not EnemyCharacter then
			continue
		end
		if not EnemyCharacter:FindFirstChild("InGame") then
			continue
		end

        local EnemyHumanoidRootPart = EnemyCharacter:FindFirstChild("HumanoidRootPart")
        if not EnemyHumanoidRootPart then
			continue
		end

        local Distance = (EnemyHumanoidRootPart.Position - HumanoidRootPart.Position).Magnitude
        if Distance < ClosestDistance then
            ClosestDistance = Distance
            Closest = EnemyCharacter
        end
    end

    return Closest, ClosestDistance
end

type Weapons = "shootRifle"

Utils.Fire = function(WeaponType: Weapons, Enemy: Instance?)
	if not Enemy then
		return
	end

	local EnemyHumanoid = Enemy:FindFirstChild("Humanoid")
	if not EnemyHumanoid then
		return
	end

	local EnemyHumanoidRootPart = Enemy:FindFirstChild("HumanoidRootPart") or Enemy.PrimaryPart
	if not EnemyHumanoidRootPart then
		warn("lebron broke his humanoidrootpart?? season canceled bro") -- like mostly sure this would never happen
		return
	end
	Event:FireServer(WeaponType, "", { EnemyHumanoidRootPart })
	Event:FireServer(WeaponType, "hit", { EnemyHumanoid })
end

Utils.TimeSince = function(since: number, interval: number): boolean
    return (os.time() - since) >= interval
end

Utils.Kill = function(WeaponType: Weapons, Enemy: Instance?)
	const Start = os.time()
	while Tool and Enemy and task.wait() do
		Utils.Fire(WeaponType, Enemy)

		if Utils.TimeSince(Start, 5) then
			warn("target seems to be unkillable")
			break
		end
	end
end

Utils.Connect("KillAura", Players.PlayerAdded, function(Player)
	if not config.KillAura.Rifle.Enabled then
		return
	end
	Core.Kill("shootRifle", Player)
end)

Core.KillClosest = function(WeaponType: Weapons, EnemyType: Enemys)
	const Enemy = Utils.GetClosest(EnemyType)
	Utils.Kill(WeaponType, Enemy)
end

Core.KillClosest("shootRifle", "Player")