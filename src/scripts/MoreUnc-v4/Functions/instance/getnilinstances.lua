local Knit = shared.Knit
local globals = Knit.require(`{shared.script}/Modules`, "globals")

return function()
    return globals.get("nilinstances")
end