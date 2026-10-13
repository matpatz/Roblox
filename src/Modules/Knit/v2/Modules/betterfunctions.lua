local betterfunctions = {}

local function wrap(func)
    return func
end
local newcclosure = newcclosure or wrap(newcclosure)
local newlclosure = newlclosure or wrap(newlclosure)

betterfunctions.hookfunction = function(func, newfunc)
	pcall(restorefunction, func)

    local _type = debug.info(func, "s")
    local _name = debug.info(func, "n")

    local wrapper = if _type == "[C]" then
        newcclosure
    else
        newlclosure
    --end

    local Old; Old = hookfunction(func, newcclosure(function(...)
        return newfunc(...)
    end), _name)

    return Old
end

return betterfunctions