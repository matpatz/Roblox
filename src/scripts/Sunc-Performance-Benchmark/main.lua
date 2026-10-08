local benchmark = {}
local tests = {}

local pcall = pcall

local function call(func, amount: number)
    local start = os.clock()
    for i = 1, amount do
        pcall(func)
    end

    local elapsed = os.clock() - start
    return elapsed
end

local genv = getgenv()
benchmark.test = function(print, i, v, FUNCTION_CALLS)
    local elapsed = call(v, FUNCTION_CALLS)
    tests[i] = {
        time = elapsed,
        func = v
    }
    print(`Test complete: {i} in {elapsed} for {FUNCTION_CALLS} calls`)
end

benchmark.tests = function(print, FUNCTION_CALLS)
    print("")
    for i, v in genv do
        if type(v) == "table" then
            table.foreach(v, function(a: number, b)
                if type(b) ~= "function" then
                    return
                end
                i, v = a, b
            end)
        end
		if type(v) ~= "function" then
			continue
		end

        benchmark.test(print, i, v, FUNCTION_CALLS)
    end
end

return benchmark