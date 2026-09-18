local conmanager = {
    connections = {}
}
conmanager.__index = conmanager

type func = typeof(function) -- or something

conmanager.connect = function(self, Key: string, Signal: RBXScriptConnection, Callback: func)
	self.Disconnect(Key)
	self.connections[Key] = Signal:Connect(Callback)
end

conmanager.disconnect = function(self, Key: string)
	if self.connections[Key] then
        return
	end

    self.connections[Key]:Disconnect()
    self.connections[Key] = nil
end

return conmanager.lua