local conmanager = {
    connections = {}
}

type func = typeof(function() end)

-- connect with a Signal: the callback fires with the signal.
-- connect with a number: the number is an interval, so the callback runs on its own
-- thread in a loop instead of on RunService.Heartbeat (a remote a frame is spam).
conmanager.connect = function(Key: string, Signal: RBXScriptSignal | number, Callback: func)
	conmanager.disconnect(Key)

	if type(Signal) == "number" then
		conmanager.connections[Key] = true

		conmanager.connections[Key] = task.spawn(function()
			while conmanager.connections[Key] do
				Callback()

				task.wait(Signal)
			end
		end)

		return
	end

	conmanager.connections[Key] = Signal:Connect(Callback)
end

conmanager.disconnect = function(Key: string)
	const Connection = conmanager.connections[Key]

	if not Connection then
        return
	end

    conmanager.connections[Key] = nil

	if typeof(Connection) == "RBXScriptConnection" then
		Connection:Disconnect()

		return
	end

	pcall(task.cancel, Connection)
end

return conmanager

--[[
conmanager.connect("this", workspace.ChildAdded, function(a)
	print(a)
end)

conmanager.connect("aura", 0.2, function()
	print("runs 5x a second")
end)
]]