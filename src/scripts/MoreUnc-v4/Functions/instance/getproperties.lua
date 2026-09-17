local Knit = shared.Knit
local services = Knit.services

local ReflectionService = services.ReflectionService

AddFunction("getproperties", function(Instance)
    if typeof(Instance) ~= "Instance" then error("expected Instance at argument #1, got " .. typeof(Instance), 2) end
    local ClassName = typeof(Instance)
    local AllCapabilities = SecurityCapabilities.new(table.unpack(Enum.SecurityCapability:GetEnumItems()))
    local Props = ReflectionService:GetPropertiesOfClass(ClassName, { Security = AllCapabilities })
    local Out = {}
    for _, Item in next, Props do
        Out[#Out + 1] = Item.Name
    end
    return Out
end)

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