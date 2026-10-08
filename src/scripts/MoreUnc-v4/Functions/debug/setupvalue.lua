type func = typeof(function() end)

local Knit = shared.Knit
local getfunction = Knit.require(`{shared.script}/Functions`, "main").getfunction

local getupvalue = getfunction("getupvalue", "debug")

return function(target: func | number, index: number, replacement: any)
    local upvalue = getupvalue(target, index)
    if type(upvalue) ~= type(replacement) then
        warn("bad boii")    
        return
    end 
end