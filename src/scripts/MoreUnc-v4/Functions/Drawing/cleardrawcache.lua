local Knit = shared.Knit
local drawing = Knit.require(`{shared.script}/Functions/Drawing`, "drawing")

return function()
    for _, entry in next, drawing.objects do
        entry.instance:Destroy()
    end

    table.clear(drawing.objects)
end
