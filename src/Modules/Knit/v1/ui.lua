local ui = {}

local Knit = shared.Knit
local instances = Knit.require(`{shared.script}/Modules`, "instances")

-- @param1: Obsidian/Rayfield
ui.new = funciton(Library: string)
    local lib = loadstring(game:HttpGet(`https://www.voltex.website/Libraries/{Library}/main.lua`))
    return lib -- client calls the function of which loadstring returns
end

ui.assign_ui_corner = function(parent, radius: { number })
    local UiCorner = instances.new("UICorner")
    UiCorner.CornerRadius = UDim.new(radius[1] or 0, radius[2] or 0)
    UiCorner.Parent = parent

    return UiCorner
end

ui.assign_ui_stroke = function(parent, thickness: number)
    local UiStroke = instances.new("UIStroke")
    UiStroke.Thickness = thickness
    UiStroke.Parent = parent
    
    return UiStroke
end

return ui