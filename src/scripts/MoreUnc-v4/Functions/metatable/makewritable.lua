local Knit = shared.Knit
local getfunction = Knit.require(`{shared.script}/Functions`, "main").getfunction
local globals = Knit.require(`{shared.script}/Modules`, "globals") 

local setrawmetatable = getfunction("setrawmetatable", "metatable")

return function(target)
    setrawmetatable(target, {})
end