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
    print(services)
    return if gethwid then gethwid() else RbxAnalyticsService:GetClientId()
end



return wrappers