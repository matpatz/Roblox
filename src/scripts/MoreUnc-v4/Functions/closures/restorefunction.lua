local Knit = shared.Knit
local globals = Knit.require(`{shared.script}/Modules`, "globals")

local hooks = globals.get("hooks")

return function(func: function)
    if not isfunctionhooked(func) then
        error("function is not hooked")
    end
    hookfunction(func, hooks[func])
end