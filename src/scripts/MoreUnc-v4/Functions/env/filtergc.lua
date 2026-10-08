type func = typeof(function() end)

local Knit = shared.Knit
local init = Knit.require(`{shared.script}/Functions`, "main")

local getgc = init.getfunction("getgc", "env")
local getfunctionhash = init.getfunction("getfunctionhash", "closures")
local getrawmetatable = init.getfunction("getrawmetatable", "metatable")
local iscclosure = init.getfunction("iscclosure", "closures")
local isexecutorclosure = init.getfunction("isexecutorclosure", "closures")

local function matches_table(value: table, options: { [string]: any }): boolean
    if options.Keys then
        for _, key in next, options.Keys do
            if rawget(value, key) == nil then
                return false
            end
        end
    end

    if options.Values then
        local values = {}

        for _, value in next, value do
            values[#values + 1] = value
        end

        for _, wanted in next, options.Values do
            if not table.find(values, wanted) then
                return false
            end
        end
    end

    if options.KeyValuePairs then
        for key, wanted in next, options.KeyValuePairs do
            if rawget(value, key) ~= wanted then
                return false
            end
        end
    end

    if options.Metatable then
        return options.Metatable == getrawmetatable(value)
    end

    return true
end

local function matches_function(value: func, options: { [string]: any }): boolean
    if options.Name and debug.info(value, "n") ~= options.Name then
        return false
    end

    if options.IgnoreExecutor ~= false and isexecutorclosure(value) then
        return false
    end

    local cclosure = iscclosure(value)

    if not cclosure then
        if options.Hash and getfunctionhash(value) ~= options.Hash then
            return false
        end

        if options.Constants then
            local constants = {}

            for _, constant in next, debug.getconstants(value) do
                if constant ~= nil then
                    constants[#constants + 1] = constant
                end
            end

            for _, wanted in next, options.Constants do
                if not table.find(constants, wanted) then
                    return false
                end
            end
        end
    end

    if options.Upvalues then
        local upvalues = {}

        for _, upvalue in next, debug.getupvalues(value) do
            if upvalue ~= nil then
                upvalues[#upvalues + 1] = upvalue
            end
        end

        for _, wanted in next, options.Upvalues do
            if not table.find(upvalues, wanted) then
                return false
            end
        end
    end

    return true
end

return function(filtertype: string, options: { [string]: any }?, returnone: boolean?)
    options = options or {}
    local matches = {}

    if filtertype == "table" then
        for _, value in next, getgc(true) do
            if typeof(value) ~= "table" or not matches_table(value, options) then
                continue
            end

            if returnone then
                return value
            end

            matches[#matches + 1] = value
        end
    elseif filtertype == "function" then
        for _, value in next, getgc(false) do
            if typeof(value) ~= "function" or not matches_function(value, options) then
                continue
            end

            if returnone then
                return value
            end

            matches[#matches + 1] = value
        end
    else
        error(("expected 'function' or 'table' (got '%s')"):format(filtertype), 2)
    end

    return returnone and nil or matches
end
