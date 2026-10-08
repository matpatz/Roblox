local Knit = shared.Knit
local globals = Knit.require(`{shared.script}/Modules`, "globals")

local hooks = globals.get("hooks")

type func = typeof(function() end)

return function(func: func)
    if not isfunctionhooked(func) then
        error("function is not hooked")
    end
    hookfunction(func, hooks[func])
end