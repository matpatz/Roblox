local Spectate = game.ReplicatedStorage:WaitForChild("SpectateEvent")

local SpectateFunction

if Spectate then
	for _, Conn in next, getconnections(Spectate.OnClientEvent) do
		local func = Conn.Function
		if not func then
			continue
		end
		if debug.getinfo(func).currentline == 21 then
			SpectateFunction = func
		end
	end
end

local Character = game.Players.LocalPlayer.Character

local getArmorSpeedReduction
for _, Conn in getconnections(Character.ChildAdded) do
	local func = Conn.Function -- EquipWeapon function
	local Script = Conn.Script
	if Script and Script.Name ~= "CharacterClient" then
		-- print("Script", Script)
		continue
	end
	if not func then
		continue
	end
	if debug.getinfo(func).currentline == 1388 then
		local Upvalues = debug.getupvalues(func)

		for _, Upvalue in next, Upvalues do
			if type(Upvalue) ~= "function" then
				continue
			end
			if debug.getinfo(Upvalue).name == "getArmorSpeedReduction" then
				getArmorSpeedReduction = Upvalue
			end
		end
	else
		-- nothing
		-- print(func)
	end
end

local RunService = game:GetService("RunService");

local FootStepHeartbeat
for _, Conn in next, getconnections(RunService.Heartbeat) do
	local func = Conn.Function
	local Script = Conn.Script
	if Script and Script.Name ~= "Footsteps" then
		continue
	end
	if not func then
		continue
	end
	if debug.getinfo(func).currentline == 79 then
		FootStepHeartbeat = func
	end
end

local RecoilHeartbeat
for _, Conn in next, getconnections(RunService.Heartbeat) do
	local func = Conn.Function
	local Script = Conn.Script
	if Script and Script.Name ~= "CharacterClient" then
		continue
	end
	if not func then
		continue
	end
	if debug.getinfo(func).currentline == 1555 then
		RecoilHeartbeat = func
	end
end

local AnticheatThread = getscriptthread(Character.LocalScript)
local LogService = game:GetService("LogService");

local MessageOut
for _, Conn in next, getconnections(LogService.MessageOut) do
	local func = Conn.Function
	if not func then
		continue
	end
	if debug.getinfo(func).currentline == 6 then
		MessageOut = func
	end
end

return {
	SpectateFunction = SpectateFunction,
	getArmorSpeedReduction = getArmorSpeedReduction,
	AnticheatThread = AnticheatThread
	FootStepHeartbeat = FootStepHeartbeat
	MessageOut = MessageOut
}