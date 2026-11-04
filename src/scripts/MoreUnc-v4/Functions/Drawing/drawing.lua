local Knit = shared.Knit
local instances = Knit.require(`{shared.script}/Modules`, "instances")
local ui = Knit.require(`{shared.script}/Modules`, "ui")

local drawing = {
    Fonts = { UI = 0, System = 1, Plex = 2, Monospace = 3 },
    objects = {},
}

local fonts = {
    [drawing.Fonts.UI] = Enum.Font.GothamMedium,
    [drawing.Fonts.System] = Enum.Font.SourceSans,
    [drawing.Fonts.Plex] = Enum.Font.Code,
    [drawing.Fonts.Monospace] = Enum.Font.RobotoMono,
}

local function make_object(class: string): Instance
    local object = instances.new(class)
    object.BorderSizePixel = 0
    object.BackgroundTransparency = 1
    object.ZIndex = 1

    return object
end

local function make_proxy(state, update, readonly)
    readonly = readonly or {}

    local proxy = newproxy(true)
    local mt = getmetatable(proxy)

    mt.__index = function(_, key)
        return state[key]
    end

    mt.__newindex = function(_, key, value)
        if table.find(readonly, key) then
            return
        end

        state[key] = value
        update()
    end

    mt.__tostring = function()
        return "Drawing"
    end

    mt.__metatable = "This metatable is protected."

    return proxy
end

local types = {}

types.Line = function(state, object)
    state.From = Vector2.zero
    state.To = Vector2.zero
    state.Thickness = 1
    state.Color = Color3.new(1, 1, 1)
    state.Visible = true
    state.ZIndex = 1
    state.Transparency = 1

    local function update()
        local from, to = state.From, state.To
        local dx, dy = to.X - from.X, to.Y - from.Y

        object.Size = UDim2.fromOffset(math.sqrt(dx ^ 2 + dy ^ 2), state.Thickness)
        object.Position = UDim2.fromOffset(from.X, from.Y)
        object.Rotation = math.deg(math.atan2(dy, dx))
        object.BackgroundColor3 = state.Color
        object.Visible = state.Visible
        object.ZIndex = state.ZIndex
    end

    update()

    return make_proxy(state, update)
end

types.Square = function(state, object)
    state.Size = Vector2.zero
    state.Position = Vector2.zero
    state.Color = Color3.new(1, 1, 1)
    state.Filled = false
    state.Thickness = 1
    state.Visible = true
    state.ZIndex = 1
    state.Transparency = 1

    local stroke = ui.assign_ui_stroke(object, state.Thickness)

    local function update()
        object.Size = UDim2.fromOffset(state.Size.X, state.Size.Y)
        object.Position = UDim2.fromOffset(state.Position.X, state.Position.Y)
        object.BackgroundColor3 = state.Color
        object.Visible = state.Visible
        object.ZIndex = state.ZIndex

        if state.Filled then
            object.BackgroundTransparency = 0
            stroke.Enabled = false
        else
            object.BackgroundTransparency = 1
            stroke.Enabled = true
            stroke.Color = state.Color
            stroke.Thickness = state.Thickness
        end
    end

    update()

    return make_proxy(state, update)
end

types.Circle = function(state, object)
    state.Radius = 1
    state.Position = Vector2.zero
    state.Color = Color3.new(1, 1, 1)
    state.Filled = false
    state.Thickness = 1
    state.Visible = true
    state.ZIndex = 1
    state.Transparency = 1
    state.NumSides = 0

    ui.assign_ui_corner(object, {1, 0})
    local stroke = ui.assign_ui_stroke(object, state.Thickness)

    local function update()
        local diameter = state.Radius * 2

        object.Size = UDim2.fromOffset(diameter, diameter)
        object.Position = UDim2.fromOffset(state.Position.X - state.Radius, state.Position.Y - state.Radius)
        object.Visible = state.Visible
        object.ZIndex = state.ZIndex

        if state.Filled then
            object.BackgroundTransparency = 1 - state.Transparency
            object.BackgroundColor3 = state.Color
            stroke.Enabled = false
        else
            object.BackgroundTransparency = 1
            stroke.Enabled = true
            stroke.Color = state.Color
            stroke.Thickness = state.Thickness
        end
    end

    update()

    return make_proxy(state, update)
end

types.Text = function(state, object)
    object.TextWrapped = false
    object.RichText = false

    state.Text = ""
    state.Size = 12
    state.Font = drawing.Fonts.Monospace
    state.Color = Color3.new(1, 1, 1)
    state.Center = false
    state.Outline = false
    state.OutlineColor = Color3.new(0, 0, 0)
    state.Position = Vector2.zero
    state.Visible = true
    state.ZIndex = 1
    state.Transparency = 1
    state.TextBounds = Vector2.zero

    local function update()
        object.Text = state.Text
        object.TextSize = state.Size
        object.TextColor3 = state.Color
        object.Position = UDim2.fromOffset(state.Position.X, state.Position.Y)
        object.Size = UDim2.fromOffset(state.Size * #state.Text * 0.6, state.Size)
        object.Font = fonts[state.Font] or Enum.Font.GothamMedium
        object.TextXAlignment = state.Center and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left
        object.TextYAlignment = state.Center and Enum.TextYAlignment.Center or Enum.TextYAlignment.Top
        object.TextStrokeTransparency = state.Outline and 0 or 1
        object.TextStrokeColor3 = state.OutlineColor
        object.Visible = state.Visible
        object.ZIndex = state.ZIndex

        state.TextBounds = object.TextBounds
    end

    update()

    return make_proxy(state, update, {"TextBounds"})
end

drawing.is_object = function(object): boolean
    for _, entry in next, drawing.objects do
        if entry.proxy == object then
            return true
        end
    end

    return false
end

drawing.new = function(class: string)
    local build = types[class]

    if not build then
        error(`invalid drawing type: {class}`, 2)
    end

    local object = make_object(if class == "Text" then "TextLabel" else "Frame")

    local state = {
        Remove = function()
            object:Destroy()
        end,
    }
    state.Destroy = state.Remove

    local proxy = build(state, object)
    drawing.objects[#drawing.objects + 1] = { proxy = proxy, instance = object }

    return proxy
end

if not getgenv().Drawing then
    getgenv().Drawing = drawing
end

return drawing
