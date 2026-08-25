-- // Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- // Workspace
local Zombies = workspace.Zombies

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

local Conn = getconnection(Zombies.ChildAdded, 1)
if (Conn or Conn.Function) == nil then
    error("conn or function missing")
else
    local Function = Conn.Function
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

local Aimbot = loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/Modules/Aimbot.lua"))()

Utils["Aimbot"].GetClosest = function(): (Instance?, BasePart?)
    local Targets = Aimbot.GetTargets(HumanoidRootPart, 200, Zombies:QueryDescendants("Model:has(#Head)"))
    return Aimbot.GetClosest(HumanoidRootPart, 200, Targets)
end

local old; old = hookfunction(u1.rcm.Raycast, function(p1, p2, p3, p4, p5)
    local Target, TargetRoot = Utils["Aimbot"].GetClosest()

    if Target and TargetRoot then
        local Direction = (TargetRoot.Position - p1.Position).Unit
        return old(p1, Direction, p3, p4, p5)
    end

    return old(p1, p2, p3, p4, p5)
end)