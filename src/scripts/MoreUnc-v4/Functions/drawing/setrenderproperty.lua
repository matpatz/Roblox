local Knit = shared.Knit
local drawing = Knit.require(`{shared.script}/Functions/drawing`, "drawing")

return function(object, property, value)
    if not drawing.is_object(object) then
        error(`expected a drawing object, got {typeof(object)}`, 2)
    end

    object[property] = value
end
