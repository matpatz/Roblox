local Spectate = game.ReplicatedStorage:WaitForChild("SpectateEvent").OnClientEvent

local SpectateFunction

if Spectate then
	for _, Conn in next, getconnections(Spectate) do
		local func = Conn.Function
		if not func then
			continue
		end
		if debug.getinfo(func).currentline == 21 then
			SpectateFunction = func
		end
	end
end

print(SpectateFunction)

local Character = game.Players.LocalPlayer.Character.ChildAdded

local getArmorSpeedReduction
for _, Conn in getconnections(Character) do
	local func = Conn.Function -- EquipWeapon function
	local Script = Conn.Script
	if Script and Script.Name ~= "CharacterClient" then
		-- print("Script", Script)
		continue
	end
	if not func then
		continue
	end
	if debug.getinfo(func).currentline == 1408 then
		local Upvalues = debug.getupvalues(func)

		for _, Upvalue in next, Upvalues do
			if type(Upvalue) ~= "function" then
				continue
			end
			if debug.getinfo(Upvalue).currentline == 39 then
				getArmorSpeedReduction = Upvalue
			end
		end
	else
		-- nothing
		-- print(func)
	end
end

print(getArmorSpeedReduction)

local AnticheatThread = getscriptthread(Character.LocalScript)
print(AnticheatThread)

return {
	SpectateFunction = SpectateFunction,
	getArmorSpeedReduction = getArmorSpeedReduction,
	AnticheatThread = AnticheatThread
}