local Knit = shared.Knit
local services = Knit.services

local function failed(reason: string)
    return {
        Success = false,
        StatusCode = 500,
        StatusMessage = reason,
        Body = "",
        Headers = {}, -- TODO: Get offical potassium headers
    }
end

return function(options)
    if type(options) ~= "table" or not options.Url or not options.Method then
        return failed("malformed request") -- handlers read Body, so never hand back nil
    end

    local ok, response = pcall(function()
        return services.HttpService:RequestAsync({
            Url = options.Url,
            Method = options.Method,
            Headers = options.Headers,
            Body = options.Body,
            Compress = options.Compress,
        })
    end)

    if not ok then
        return failed(tostring(response))
    end

    return {
        Success = response.Success,
        StatusCode = response.StatusCode,
        StatusMessage = response.StatusMessage,
        Body = response.Body,
        Headers = response.Headers, -- TODO: Get offical potassium headers
    }
end