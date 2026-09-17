local Knit = shared.Knit
local getfunction = Knit.require(`{shared.script}/Functions`, "main").getfunction
local globals = Knit.require(`{shared.script}/Modules`, "globals") 

local getrawmetatable = getfunction("getrawmetatable")
local clonefunction = getfunction("clonefunction")
local hookfunction = getfunction("hookfunction")

type func = typeof(function() end)

return function(object: Instance | table | userdata, method: string, hook: func): table?
    local foundmethod = getrawmetatable(object)[method]
    local clonedmethod = clonefunction(foundmethod)
    
    hookfunction(foundmethod, function(...))
        return hook(...)
    end
    
    return clonedmethod -- I think? idk it says returns a table so like uhm yea
end

--[[
hookfunction()
]]