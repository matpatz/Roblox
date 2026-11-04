return function(fake_self, url: string?)
    -- both httpget(url) and httpget(self, url) turn up, so shift when the url is missing
    local target = if url == nil then fake_self else url

    return request({
        Url = target,
        Method = "GET"
    }).Body
end

--[[
httpget(game)
]]