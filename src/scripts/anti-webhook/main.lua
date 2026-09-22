--local Knit = shared.Knit
--local wrappers = Knit.wrappers

--local newcclosure = wrappers.newcclosure
local getinfo = debug.getinfo
local setinfo = debug.setinfo

local request_info = getinfo(request)
local ishooked_info = getinfo(isfunctionhooked)

local blacklist = {
    ["discord.com/api/webhooks"] = true,
    ["discordapp.com/api/webhooks"] = true,
}

local Old; Old = hookfunction(request, newcclosure(function(options)
	local url = options.Url

	options.Url = "https://example.com"
	local original = Old(options) -- input validation
	options.Url = url

	for blacklisted in next, blacklist do
		if url:find(blacklisted) then
			return {
                StatusMessage = "Could not resolve hostname", -- igbro
                StatusCode = 0,
                Success = false,
                Headers = original.Headers,
                Body = ""
			}
		end
	end
	return Old(options)
end))

local Old2; Old2 = hookfunction(isfunctionhooked, function(func)
	if func == request then
		return false
	end
	return Old2(func)
end)

if setinfo then
    setinfo(isfunctionhooked, ishooked_info)
    setinfo(request, request_info)
end