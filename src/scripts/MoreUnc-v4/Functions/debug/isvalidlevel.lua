local Knit = shared.Knit
local init = Knit.require(`{shared.script}/Functions`, "main")

local getinfo = init.getfunction("getinfo", "debug")

return function(level: number): boolean
    local a, b = pcall(function()
        local _ = getinfo(level, "n")
    end)
    return a
end