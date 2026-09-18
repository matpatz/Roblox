local Knit = shared.Knit
local services = Knit.services

local ReflectionService = services.ReflectionService

local AllCapabilities = SecurityCapabilities.new(table.unpack(Enum.SecurityCapability:GetEnumItems()))
return function(target: Instance): table
    local class = target.ClassName

    local properties = ReflectionService:GetPropertiesOfClass(class, {
        Security = AllCapabilities
    })
    local result = {}

    for _, Item in next, properties do
        result[#result + 1] = Item.Name
    end
    return result
end