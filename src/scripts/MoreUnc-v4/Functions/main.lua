local init = {}

local Knit = shared.Knit

local globals = Knit.require(`{shared.script}/Modules`, "globals")

--[[ {
    ["table"] = { -- crypt, closures, whatever.
        function,
        otherfunction
    }
} --]]

local functions = {}

init.getfunctions = function()
    return functions
end

init.getfunction = function(name: string, tbl: string?) -- function
    if tbl then
        local container = getgenv()[tbl]
        if type(container) ~= "table" then
            container = functions[tbl]
        end
        return type(container) == "table" and container[name] or nil
    end
    return getgenv()[name] ~= nil and getgenv()[name] or functions[name]
end

init.init = function()
    functions = Knit.git.clone(shared.script, "Functions")
    for func in next, functions do
        Knit.require(shared.script, `Functions/{func}`)
    end
end

return init