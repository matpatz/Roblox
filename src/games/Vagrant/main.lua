repeat
	task.wait()
until
	getrenv().require and game:GetService("Players").LocalPlayer ~= nil

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local aimbot = loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/Modules/Aimbot.lua"))()

repeat
	task.wait()
until
	aimbot

print(aimbot, "aimbotttt")

local function GetTarget()
	if not LocalPlayer then
		print("no lp", LocalPlayer)
		return nil
	end

	local Character = LocalPlayer.Character
	if not Character then
		print("no character")
		return nil
	end
	
	local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
	if not HumanoidRootPart then
		print("no hrp")
		return nil
	end
	
	local Targets = aimbot.GetTargets(HumanoidRootPart, 250, {})
	if not Targets or #Targets == 0 then
		print("no targets??")
		return nil
	end
	local ClosestTarget = aimbot.GetClosest(HumanoidRootPart, 250, Targets)
	if not ClosestTarget then
		print("no closest target")
	end

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
			print("no target")
			return old_projectile(cfg,cf,ray,hit,pass)
		end
		local Character = Target.Character
		if not Character then
			print("no target character")
			return old_projectile(cfg,cf,ray,hit,pass)
		end
		local HumanoidRootPart = Target.Character:FindFirstChild("HumanoidRootPart")
		if not HumanoidRootPart then
			print("no target hrp")
			return old_projectile(cfg,cf,ray,hit,pass)
		end
		
		cf = CFrame.lookAt(cf.Position, HumanoidRootPart.Position)
		return old_projectile(cfg,cf,ray,hit,pass)
	end

    return result
end)