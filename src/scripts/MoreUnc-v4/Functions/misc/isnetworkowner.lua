local Knit = shared.Knit
local getfunction = Knit.require(`{shared.script}/Functions`, "init")

local gethiddenproperty = getfunction("gethiddenproperty")

return function(part: Instance)
    return gethiddenproperty(part, "NetworkOwnerV3") and true or false
end