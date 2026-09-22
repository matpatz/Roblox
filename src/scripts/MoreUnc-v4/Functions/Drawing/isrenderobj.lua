local Knit = shared.Knit
local drawing = Knit.require(`{shared.script}/Functions/Drawing`, "drawing")

return function(object): boolean
    return drawing.is_object(object)
end
