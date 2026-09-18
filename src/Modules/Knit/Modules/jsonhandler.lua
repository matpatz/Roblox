local jsonhandler = {}

local Knit = shared.Knit
local services = Knit.services
local wrappers = Knit.wrappers

local lz4compress = wrappers.lz4compress

local HttpService = services.HttpService

jsonhandler.encode = function(data)
    HttpService:JSONEncode(data)
end 

jsonhandler.decode = function(data)
    return HttpService:JSONDecode(data)
end

jsonhander.compress(data)
    local datatype = type(data)
    if datatype == "string" then
        return lz4compress(data)
    elseif datatype == "table" the
        local results = {}    
        table.foreach(data, function(a, b)
            results[b] = lz4compress(b)
        end)

        return results
    end
end

return jsonhandler

--[[
local a = [=[
    print(true)
]=]
jsonhandler.compress(a)

local b = {
    a = "bbbbbbb"
    b = "aaaaaaa"
}

jsonhandler.compress(b)
]]