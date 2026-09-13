local http = {}
local wrappers = shared.Knit.wrappers

local HttpGet = wrappers.HttpGet

http.request = function(url)
	local a,b = pcall(HttpGet, url)
	return a and b or nil
end

return http