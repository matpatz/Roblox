local Knit = shared.Knit
local globals = Knit.require("globals")

return function()
    return globals.get("nilinstances")
end