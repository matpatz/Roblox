local Knit = shared.Knit
local services = Knit.services

local UGCValidation = services.UGCValidationService

return function(target: Instance, property: string)
    return UGCValidation:GetPropertyValue(target, property) ~= nil
end