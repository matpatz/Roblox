local Knit = shared.Knit
local drawing = Knit.require(`{shared.script}/Functions/Drawing`, "drawing")

return function(object, property)
    if not drawing.is_object(object) then
        error(`expected a drawing object, got {typeof(object)}`, 2)
    end

    return object[property]
end
