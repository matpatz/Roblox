local Knit = shared.Knit
local globals = Knit.require(`{shared.script}/Modules`, "globals")

-- local closures = globals.get("l_closures")

return function(func, name: string?)
    -- globals.set("l_closures", func)
	return func
end

--[[
local a = newlclosure(function()
	return true
end, "optional_func_name")

print(debug.info(a, "n")) -- optional_func_name
]]