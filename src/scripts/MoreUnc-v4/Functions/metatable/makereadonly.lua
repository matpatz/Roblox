local Knit = shared.Knit
local getfunction = Knit.require(`{shared.script}/Functions`, "main").getfunction

local setrawmetatable = getfunction("setrawmetatable", "metatable")

return function(target)
    setrawmetatable(target, {
        __newindex = function(_, __)
            error("attempt to modify readonly table")
        end
    })
end