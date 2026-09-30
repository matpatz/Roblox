local clonefunction = clonefunction and clonefunction or function(x)
	return x
end
local hookfunction = hookfunction and hookfunction or function(a,b)
	a = b
end
local isfunctionhooked = isfunctionhooked and isfunctionhooked or function(x)
	return false
end

assert(loadstring, "loadstring funciton required")

local load = clonefunction(loadstring)

if isfunctionhooked(loadstring) then
	restorefunction(loadstring)
end

local Old = load; Old = hookfunction(loadstring, function(script: string, ...)
	if script:find("https://scriptblox.com/ingest/v1") then
		warn("attempted analytics")
		return
	end

	return Old(script, ...)
end)