local cache = {}

local cached = {
    keys = {},
    timer = {}
}

local task_delay = task.delay

setmetatable(cached.keys, {
	__newindex = function(t, key, value)
		rawset(t, key, value)

		task_delay(1, function()
			if rawget(t, key) == value then -- ignore if key has been overwritten
				rawset(t, key, nil)
			end
		end)
	end
})

cache.get = function(key)
    return cached["keys"][key]
end

cache.set = function(key, value)
    if cached["keys"][key] == nil then
        cached["keys"][key] = value -- add key to cache
    else
        cached["keys"][key] = nil -- clear cached key
    end
end

return cache