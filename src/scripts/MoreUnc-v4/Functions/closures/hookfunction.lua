local Knit = shared.Knit
local globals = Knit.require(`{shared.script}/Modules`, "globals")

local hooks = globals.get("hooks")

return function(func: function, hook: function)
    if hooks[hook] then
        return
    end
    hooks[func] = hook

    return func
end