local Knit = shared.Knit
local globals = Knit.require(`{shared.script}/Modules`, "globals")

local closures = globals.get("c_closures")

return function(func, name: string?)
	local closure = coroutine.wrap(function(...)
		local args = table.pack(...)
		while true do
			local res = table.pack(pcall(func, table.unpack(args, 1, args.n)))
			if res[1] then
				args = table.pack(coroutine.yield(table.unpack(res, 2, res.n)))
			else
				task.spawn(error, res[2]) -- shows in output, wrapper stays alive
				args = table.pack(coroutine.yield())
			end
		end
	end)

	closures[closure] = true

	return closure
end

--[[
local a = newcclosure(function(...)
	return ...
end, "optional_func_name")

print(a(1, 2, 3)) -- 1 2 3
print(a("next", "call")) -- next call
print(isnewcclosure(a)) -- true
]]