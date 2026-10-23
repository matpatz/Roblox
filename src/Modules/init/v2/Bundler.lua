local Knit = shared.Knit
local script: string = shared.script

return function()
    Knit.require(script, "utils")
    Knit.require(script, "core")
    Knit.require(script, "ui")
end