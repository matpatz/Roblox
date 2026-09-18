type func = typeof(function() end)

local Knit = shared.Knit
local init = Knit.require(`{shared.script}/Functions`, "main")

local getfunctionhash = init.getfunction("getfunctionhash", "closures")
local iscclosure = init.getfunction("iscclosure", "closures")

local function short_source(source: string): string
    local short = source:gsub("^[@=]", "")

    if #short > 60 then
        short = short:sub(1, 57) .. "..."
    end

    return short
end

return function(target: func | number)
    local islevel = typeof(target) == "number"

    local source = debug.info(target, "s")
    if not source then
        return nil -- no such level
    end

    local name = debug.info(target, "n")
    local numparams, isvararg = debug.info(target, "a")
    local func = if islevel then debug.info(target, "f") else target
    local hash = if iscclosure(func) then nil else getfunctionhash(func)

    return {
        name = if name ~= "" then name else nil,
        source = source,
        short_src = short_source(source),
        what = if source == "[C]" then "C" else "Lua",
        currentline = if islevel then debug.info(target, "l") else -1,
        numparams = numparams,
        is_vararg = isvararg,
        hash = hash,
        size = if hash then #hash else 0,
        func = func,
    }
end