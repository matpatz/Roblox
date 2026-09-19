local Knit = shared.Knit
local script: string = shared.script

return function()
    local utils = Knit.require(script, "utils")
    repeat task.wait() until utils

    local core = Knit.require(script, "core")
    repeat task.wait() until core
    
    local ui = Knit.require(script, "ui")
end