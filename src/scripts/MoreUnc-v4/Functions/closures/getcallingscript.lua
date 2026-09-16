return function() -- stack1
    return debug.info(3, "s")
end

--[[
local old; old = hookmetamethod(game, "__namecall", function(self, key) -- stack2
    if getcallingscript() == script then
        print("here")
    end
    return old(self, key)
end)
]]