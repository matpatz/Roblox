-- this can be detected but thunderpookie wouldnt do that

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
local newcclosure = newcclosure and newcclosure or function(x)
	return x
end

assert(loadstring, "loadstring required")

local load = clonefunction(loadstring)

if isfunctionhooked(loadstring) then
	restorefunction(loadstring)
end

local Old; Old = hookfunction(loadstring, newcclosure(function(script: string, ...)
	if script:find("https://scriptblox.com/ingest/v1") then
		error("attempted analytics")
	end

	return load(script, ...)
end))
