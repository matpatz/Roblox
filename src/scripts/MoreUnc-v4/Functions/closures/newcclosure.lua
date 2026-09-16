local Knit = shared.Knit
local globals = Knit.require(`{shared.script}/Modules`, "globals")

-- local closures = globals.get("c_closures")

return function(func, name: string?)
    globals.set("c_closures", func)
	return func
end

--[[
local a = newcclosure(function()
	return true
end, "optional_func_name")

print(debug.info(a, "n")) -- optional_func_name
print(isnewcclosure(a)) -- true
]]