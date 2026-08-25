-- // Services
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Players = game:GetService("Players")

-- // Workspace
const Zombies = workspace.Zombies

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

-- // Variables
local u1 = {} -- Functions Module (it gets deleted)

const Conn = getconnection(Zombies.ChildAdded, 1)
if (Conn or Conn.Function) == nil then
    error("conn or function missing")
else
    const Function = Conn.Function
    u1 = debug.getupvalue(Function, 1)
end

-- // cheat
local cheat = {
	Utils = {
        ["Aimbot"] = {}
	},
	Core = {

	}
}
local Utils = cheat.Utils
local Core = cheat.Core

-- // config
local config = {
    Origin,
    Range = 400,
    TeamCheck = true,
    AimPart = "Head",
    Visible = true,
    EntityLists = {
        Zombies:GetChildren()
    },
}

const Aimbot = loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/Modules/Aimbot/main.lua"))()

Utils["Aimbot"].GetClosest = function(): (BasePart?)
    const Target, AimPart = Aimbot.GetClosest(config)

    return AimPart
end

local old; old = hookfunction(u1.rcm.Raycast, function(p1, p2, p3, p4, p5)
    config["Origin"] = HumanoidRootPart.Position
    const TargetRoot = Utils["Aimbot"].GetClosest()

    if TargetRoot then
        const Direction = (TargetRoot.Position - p1.Position).Unit
        return old(p1, Direction, p3, p4, p5)
    end

    return old(p1, p2, p3, p4, p5)
end)