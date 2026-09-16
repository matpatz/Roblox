type func = typeof(function() end) -- I cant use type() here

return function(func: func) -- not very accurate
	local funcname = debug.info(func, "n")
    return getgenv()[funcname]
end

--[[
local function a()
end

print(isexecutorclosure(a)) -- true
print(isexecutorclosure(getgc)) -- true
]]