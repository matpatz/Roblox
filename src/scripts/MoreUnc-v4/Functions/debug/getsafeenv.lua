type func = typeof(function() end)

local Knit = shared.Knit
local globals = Knit.require(`{shared.script}/Modules`, "globals") 

return function(object: func | table | thread)
    return globals.get("safeenv")
end

-- any overwritten object(getfenv) will break safeenv. Not sure why setsafeenv even exists but ya