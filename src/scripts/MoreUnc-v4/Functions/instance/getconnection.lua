local Knit = shared.Knit
local getfunction = Knit.require(`{shared.script}/Functions`, "main").getfunction

local getconnections = getfunction("getconnections")

return function(signal, index)
    local connection = getconnections(signal)[index]
    return connection
end