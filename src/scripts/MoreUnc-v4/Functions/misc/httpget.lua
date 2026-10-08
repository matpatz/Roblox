return function(fake_self, url: string)
    if fake_self then
        fake_self = url -- this is yk useless but okkk
    end
    return request({
        Url = url,
        Method = "GET"
    }).Body
end

--[[
httpget(game)
]]