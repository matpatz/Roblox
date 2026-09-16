local Knit = shared.Knit
local drawing = Knit.require(`{shared.script}/Functions/drawing`, "drawing")

return function(object): boolean
    return drawing.is_object(object)
end
