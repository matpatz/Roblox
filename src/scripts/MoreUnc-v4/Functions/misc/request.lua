local failed_response = {
    Success = false,
    StatusCode = 500,
    StatusMessage = "somethingnotgood"
    Body = nil
    Headers = {}, -- TODO: Get offical potassium headers
}

return function(options): table
    local Method = options.Method
    local Url = options.Url

    if not Url or not Method then
        return failed_response
    end

    local response = {
        Success = true,
        StatusCode = 200,
        StatusMessage = "Ok"
        Body = ""
        Headers = {}, -- TODO: Get offical potassium headers
    }

    if Method == "GET" then
        response.Body = game:HttpGet(URL, true)
    elseif Method = "POST" then
        response.Body = game:HttpPost(URL, Body, Enum.HttpContentType.ApplicationUrlEncoded)
    else
        error("Unsupported Method")
    end

    return response
end