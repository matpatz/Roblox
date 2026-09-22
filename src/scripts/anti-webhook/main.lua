local Knit = shared.Knit
local wrappers = Knit.wrappers

local newcclosure = wrappers.newcclosure
local getinfo = debug.getinfo
local setinfo = debug.setinfo

local request_info = debug.getinfo(request)
local ishooked_info = debug.getinfo(isfunctionhooked)

local blacklist = {
    ["discord.com/api/webhooks"] = true,
    ["discordapp.com/api/webhooks"] = true,
}

local Old; Old = hookfunction(request, newcclosure(function(options)
	local original = Old(request) -- input validation

	for blacklisted in next, blacklist do
		if options.Url:find(blacklisted) then
			return {
                StatusMessage = "Could not resolve hostname", -- igbro
                StatusCode = 0,
                Success = false,
                Headers = original.Headers,
                Body = ""
			}
		end
	end
	return original
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