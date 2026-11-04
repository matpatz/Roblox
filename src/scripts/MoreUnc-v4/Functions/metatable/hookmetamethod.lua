local Knit = shared.Knit
local getfunction = Knit.require(`{shared.script}/Functions`, "main").getfunction
local globals = Knit.require(`{shared.script}/Modules`, "globals") 

local getrawmetatable = getfunction("getrawmetatable", "metatable")
local clonefunction = getfunction("clonefunction", "closures")
local hookfunction = getfunction("hookfunction", "closures")

type func = typeof(function() end)

return function(object: Instance | table | userdata, method: string, hook: func): func?
    local original = getrawmetatable(object)

    if not original then
        return nil -- protected by __metatable, or not something a metatable hangs off
    end

    local method_fn = original[method]

    if type(method_fn) ~= "function" then
        return nil
    end

    local clonedmethod = clonefunction(method_fn)

    hookfunction(method_fn, function(...)
        return hook(...)
    end)

    return clonedmethod
end

--[[
hookfunction()
]]