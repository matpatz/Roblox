assert(hookfunction and newcclosure, "hookfunction/newcclosure required")

if isfunctionhooked and restorefunction and isfunctionhooked(loadstring) then
	restorefunction(loadstring)
end

local blocked = {
	"https://scriptblox.com/ingest",
	"https://rscripts.net/api/telemetry",
}

local Old
Old = hookfunction(loadstring, newcclosure(function(source, ...)
	if type(source) == "string" then
		for _, url in blocked do
			if source:find(url, 1, true) then
				return function() end
			end
		end
	end

	return Old(source, ...)
end))
