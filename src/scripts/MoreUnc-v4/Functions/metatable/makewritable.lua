local Knit = shared.Knit
local getfunction = Knit.require(`{shared.script}/Functions`, "init").getfunction
local globals = Knit.require(`{shared.script}/Modules`, "globals") 

local setrawmetatable = getfunction("setrawmetatable")

return function(target)
    setrawmetatable(target, {})
end