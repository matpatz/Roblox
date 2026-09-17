local Knit = shared.Knit
local services = Knit.services

local UGCValidation = services.UGCValidation

return function(target: Instance, property: string)
    return UGCValidation:GetPropertyValue(target, property)
end