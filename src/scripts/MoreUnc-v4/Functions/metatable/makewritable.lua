local Knit = shared.Knit
local getfunction = Knit.require(`{shared.script}/Functions`, "main").getfunction
local globals = Knit.require(`{shared.script}/Modules`, "globals") 

local setrawmetatable = getfunction("setrawmetatable", "metatable")

return function(target) -- this only workks for tables locked with makereadonly, not table.freeze
    local ok, err = pcall(function()
        setrawmetatable(target, {})
    end)

    if not ok then
        error(err)
    end
end