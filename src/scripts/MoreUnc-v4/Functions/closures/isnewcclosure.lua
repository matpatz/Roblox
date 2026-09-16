local Knit = shared.Knit
local globals = Knit.require(`{shared.script}/Modules`, "globals")

local closures = globals.get("c_closures")

return function(func): boolean
    if closures[func] then
        return true
    end
	return false
end

--[[
local a = newcclosure(function()
	return true
end, "optional_func_name")

print(a())
print(isnewcclosure(a))
]]