local Knit = shared.Knit
local services = Knit.services

local RbxAnalyticsService = services.RbxAnalyticsService

return function()
    return RbxAnalyticsService:GetClientId()
end