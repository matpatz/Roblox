local conmanager = {
    connections = {}
}

type func = typeof(function() end)

conmanager.connect = function(Key: string, Signal: RBXScriptSignal, Callback: func)
	conmanager.disconnect(Key)
	conmanager.connections[Key] = Signal:Connect(Callback)
end

conmanager.disconnect = function(Key: string)
	if not conmanager.connections[Key] then
        return
	end

    conmanager.connections[Key]:Disconnect()
    conmanager.connections[Key] = nil
end

return conmanager

--[[
conmanager.connect("this", workspace.ChildAdded, function(a)
	print(a)
end)
]]