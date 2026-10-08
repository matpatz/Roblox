local Knit = shared.Knit
local getfunction = Knit.require(`{shared.script}/Functions`, "main").getfunction

local gethiddenproperty = getfunction("gethiddenproperty", "instance")

return function(part: Instance)
    return gethiddenproperty(part, "NetworkOwnerV3") and true or false
end