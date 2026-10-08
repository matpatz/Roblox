local services = {}
local cloneref = cloneref and cloneref or function(x)
	return x -- what exec doesnt have cloneref? idk maybe solara or jjsploit ha-ha
end

local Cache = {}
setmetatable(services, {
	__index = function(_, Index)
		local Cached = Cache[Index]
		if Cached then
			return Cached
		end
		local Service = cloneref(game:GetService(Index))
		Cache[Index] = Service

		return Cache[Index]
	end
})

return services