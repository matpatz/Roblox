local Knit = shared.Knit

local tests = {}

local func_dir = listfiles(Knit.getdir(shared.script)) -- I think, uhm idk ig figure it out
local functions = {}
local log = {}

for _, file in next, func_dir do
    local func = dofile(file)
    functions[func] = func
end

tests.log = function(func, boolean, string)
    log[func] = {
        pass = boolean
        fail_reason = string
    }
end

tests.test = function(func): (boolean, string?)
    local name = debug.info(func, "n")

    if func then
        tests.log(func, false, "")
        return true, ""
    end


    tests.log(func, false, "")
    return false, ""
end

tests.init = function()
    for func in next, functions do
        print(tests.test(func)) -- all true
    end
    return log
end

return tests