local cache = {}

local cached = {
    keys = {}
}
-- _G.cached = {}

local task_delay = task.delay

local function setcache(cache_table, cache_time)
    setmetatable(cache_table, {
        __newindex = function(t, key, value)
            rawset(t, key, value)

            task_delay(cache_time, function()
                if rawget(t, key) == value then -- ignore if key has been overwritten
                    rawset(t, key, nil)
                end
            end)
        end
    })
end
setcache(cached.keys, 1)

cache.get = function(key)
    return cached["keys"][key]
end

cache.set = function(key, value)
    if cached["keys"][key] == nil then
        cached["keys"][key] = value -- add key to cache
    else
        cached["keys"][key] = nil -- clear cached key
    end
    return cached["keys"][key]
end

cache.make_cache = function(cache_table, cache_time)
    local cache_time = cache_time or 1
    setcache(cache_table, cache_time)
end

cache.reset_cache = function(cache_table)
    setmetatable(cache_table, nil) -- good enough for my use case
end

return cache