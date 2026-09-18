local Knit = shared.Knit
local services = Knit.services

local UGCValidation = services.UGCValidationService

return function(target: Instance, property: string, value)
    return UGCValidation:SetPropertyValue(target, property, value)
end