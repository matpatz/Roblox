local Original = request

local BlockedUrls = {
    ["discord.com/api/webhooks"] = true,
    ["discordapp.com/api/webhooks"] = true,
}

getgenv().request = newcclosure(function(Payload)
    if type(Payload) ~= "table" then
		return Original(Payload)
	end
    if type(Payload.Url) ~= "string" then
		return Original(Payload)
	end
    if type(Payload.Method) ~= "string" then
		return Original(Payload)
	end

    for Domain in next, (BlockedUrls) do
        if Payload.Url:find(Domain, 1, true) then
            warn("Blocked webhook:", Payload.Url)
            return {
                Success = true,
                StatusCode = 203,
                Body = "",
            }
        end
    end

    if Payload.Method == "POST" then
        local Body = Payload.Body
        if Body:match("^[0-9A-Fa-f]+$") and #Body > 100 then
            warn("Blocked POST body")
            return {
                Success = true,
                StatusCode = 203,
                Body = "",
            }
        end
    end

    return Original(Payload)
end)
