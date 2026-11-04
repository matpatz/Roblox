local Knit = shared.Knit
local globals = Knit.require(`{shared.script}/Modules`, "globals")
local init = Knit.require(`{shared.script}/Functions`, "main")

local hooks = globals.get("hooks")

local clonefunction = init.getfunction("clonefunction", "closures")


type func = typeof(function() end)

--[[
solara:
getgenv().hookfunction = function(func, replacement)
	local proxy = setmetatable({}, {
		__index = func
	})
	return hookmetamethod(proxy, "__index", replacement)
end
]]

return function(func: func, hook: func)
    local entry = hooks[func]

    -- already hooked with this exact replacement, hand the original back
    if entry and entry.hook == hook then
        return entry.original
    end

    -- restorefunction needs the original, so it has to survive a re-hook
    local original = if entry then entry.original else clonefunction(func)

    hooks[func] = {
        hook = hook,
        original = original,
    }

    return original
end