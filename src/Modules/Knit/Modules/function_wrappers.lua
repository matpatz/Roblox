local wrappers = {}
local services = shared.Knit.services

wrappers.cloneref = function(x: string | Instance): Instance
    if type(x) == "string" then
        return services[x] -- input real service names ("CoreGui", "ReplicatedStorage", etc.)
    end
    return cloneref and cloneref(x) or x
end

local RbxAnalyticsService = services.RbxAnalyticsService

wrappers.gethwid = function()
    return if gethwid then gethwid() else RbxAnalyticsService:GetClientId()
end

wrappers.getinfo = function(func)
    return if getinfo then getinfo(func) else nil
end

wrappers.setinfo = function(func, info)
    if setinfo then
        setinfo(func, info)
    end
end

return wrappers