local Knit = shared.Knit
local init = Knit.require(`{shared.script}/Functions`, "main")

local hash = init.getfunction("hash", "crypt")

local function getbytecode(func): string
    if dumpbytecode then
        return dumpbytecode(func)
    end

    return `{debug.info(func, "l")}{#debug.info(func, "s")}`
end

type func = typeof(function() end)

return function(func: func): string
    return hash(getbytecode(func), "sha384")
end
