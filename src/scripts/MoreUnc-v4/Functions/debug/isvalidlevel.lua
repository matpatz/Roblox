local Knit = shared.Knit
local init = Knit.require(`{shared.script}/Functions`, "main")

local getinfo = init.getfunction("getinfo", "debug")

return function(level: number): boolean
    -- out of range levels hand back nil instead of throwing, so check both
    local ok, source = pcall(getinfo, level)

    return ok and source ~= nil
end