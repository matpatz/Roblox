local clonefunction = clonefunction and clonefunction or function(x)
	return x
end
local hookfunction = hookfunction and hookfunction or function(targetfunction, hookedfunction)
    targetfunction = hookedfunction
    
    return targetfunction
end

local isfunctionhooked = isfunctionhooked and isfunctionhooked or function(x)
	return false
end

assert(loadstring, "loadstring required")

local load = clonefunction(loadstring)

if isfunctionhooked(loadstring) then
	restorefunction(loadstring)
end

local Old; Old = hookfunction(loadstring, function(script: string, ...)
	if script:find("https://scriptblox.com/ingest/v1") then
		error("attempted analytics")
	end

	return load(script, ...)
end)
