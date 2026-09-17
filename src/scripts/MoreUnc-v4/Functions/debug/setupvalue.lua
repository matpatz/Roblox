local Knit = shared.Knit
local getfunction = Knit.require(`{shared.script}/Functions`, "init").getfunction

local getupvalue = getfunction("getupvalue", "debug")

return function(target: function | number, index: number, replacement: any)
    local upvalue = getupvalue(target, index)
    if type(upvalue) ~= type(replacement) then
        warn("bad boii")    
        return
    end 
end