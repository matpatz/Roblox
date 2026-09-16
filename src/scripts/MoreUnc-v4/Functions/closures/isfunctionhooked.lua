local Knit = shared.Knit
local globals = Knit.require(`{shared.script}/Modules`, "globals")

local hooks = globals.get("hooks")

return function(func: function)
    return hooks[func] ~= nil
end