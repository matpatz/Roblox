local Knit = shared.Knit
local globals = Knit.require(`{shared.script}/Modules`, "globals")

local hooks = globals.get("hooks")

type func = typeof(function() end)

return function(func: func, hook: func)
    if hooks[hook] then
        return
    end
    hooks[func] = hook

    return func
end