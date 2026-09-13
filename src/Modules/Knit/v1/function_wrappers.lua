local wrappers = {}
local services = shared.Knit.services

wrappers.cloneref = function(x: Instance): Instance
    return services.x
end

local RbxAnalyticsService = services.RbxAnalyticsService

wrappers.gethwid = function()
    print(services)
    return if gethwid then gethwid() else RbxAnalyticsService:GetClientId()
end



return wrappers