repeat
	task.wait()
until getrenv().require and game

local players = game:GetService("Players")
local lp = players.LocalPlayer

local aimbot = loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/Modules/Aimbot.lua"))()

local function GetTarget()
	local Character = lp.Character
	if not Character then
		print("no Character")
		return
	end
	local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart", 5)
	if not HumanoidRootPart then
		print("no hrp")
		return
	end
	
	local Targets = aimbot.GetTargets(HumanoidRootPart, 250, {})
	local ClosestTarget = aimbot.GetClosest(HumanoidRootPart, Targets)
	
	return ClosestTarget
end

local old
old = hookfunction(getrenv().require, function(Module)
    if Module.Name ~= "CreateProjectile" then
		return old(Module)
	end
	local result = old(Module)
	local old_projectile = result

	result = function(cfg,cf,ray,hit,pass)
		local Target = GetTarget()
		if not Target then
			return old_projectile(cfg,cf,ray,hit,pass)
		end
		cf = CFrame.lookAt(cf.Position, Target.HumanoidRootPart.Position)

		return old_projectile(cfg,cf,ray,hit,pass)
	end

    return result
end)