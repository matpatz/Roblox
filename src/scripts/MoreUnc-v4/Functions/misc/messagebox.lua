local Knit = shared.Knit
local instances = Knit.require(`{shared.script}/Modules`, "instances")
local ui = Knit.require(`{shared.script}/Modules`, "ui")

return function(text: string, caption: string, flag: number)
    local Window = instances.new("Frame")
    Window.Size = UDim2.fromOffset(349, 151)
    Window.Position = UDim2.new(0.5, -174, 0.5, -75)
    Window.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Window.Draggable = true
    Window.BorderSizePixel = 0
    Window.ClipsDescendants = true

    ui.assign_ui_corner(Window, {0, 8})

    local top_strip = Instance.new("Frame")
    top_strip.Size   = UDim2.fromOffset(349, 35)
    top_strip.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
    top_strip.BorderSizePixel = 0
    top_strip.ClipsDescendants = true

    ui.assign_ui_corner(top_strip, {0, 8})

    local title: TextLabel = instances.new("TextLabel")
    title.Size = UDim2.fromOffset(260, 18)
    title.Position = UDim2.fromOffset(14, 10)
    title.BackgroundTransparency = 1
    title.Text = caption
    title.Font = Enum.Font.SourceSans
    title.TextSize = 16
    title.TextColor3 = Color3.fromRGB(0, 0, 0)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = Window

    local close: TextButton = Instance.new("TextButton")
    close.Size = UDim2.fromOffset(20, 20)
    close.Position = UDim2.fromOffset(321, 8)
    close.Text = "X"
    close.Font = Enum.Font.SourceSansBold
    close.TextSize = 16
    close.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    close.BackgroundTransparency = 0.8
    close.TextColor3 = Color3.fromRGB(0, 0, 0)
    close.Parent = Window
    close.MouseButton1Click:Connect(function()
        Window:Destroy()
    end)
    close.MouseEnter:Connect(function()
        close.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    end)
    close.MouseLeave:Connect(function()
        close.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    end)

    local message: TextLabel = instances.new("TextLabel", true, Window)
    message.Size = UDim2.fromOffset(250, 20)
    message.Position = UDim2.fromOffset(54, 58)
    message.BackgroundTransparency = 1
    message.Text = text
    message.Font = Enum.Font.SourceSans
    message.TextSize = 14
    message.TextColor3 = Color3.fromRGB(0, 0, 0)
    message.TextXAlignment = Enum.TextXAlignment.Left

    local bottom_strip: Frame = instances.new("Frame", true, Window)
    bottom_strip.Size = UDim2.fromOffset(349, 38)
    bottom_strip.Position = UDim2.fromOffset(0, Window.Size.Y.Offset - 38)
    bottom_strip.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
    bottom_strip.BorderSizePixel = 0
    bottom_strip.ClipsDescendants = true
    ui.assign_ui_corner(bottom_strip, {0, 8}) -- or something

    local function CreateButton(text: string, Position: number): TextButton
        local button = instances.new("TextButton", true, Window)
        button.Size = UDim2.fromOffset(72, 26)
        button.Position = UDim2.fromOffset(Position, 5.8)
        button.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
        button.Text = text
        button.Font = Enum.Font.SourceSans
        button.TextSize = 14
        button.TextColor3 = Color3.fromRGB(0, 0, 0)
        button.ClipsDescendants = true
        button.Parent = bottom_strip

        local UiCorner = instances.new("UiCorner", {0, 4})
        UiCorner.Parent = button

        local UIStroke = instances.new("UIStroke", true, button)
        UIStroke.Color = Color3.fromRGB(200, 200, 200)
        UIStroke.Thickness = 1
        UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

        return button
    end

    local ok_button = CreateButton("OK", 263)
    ok_button.MouseButton1Click:Connect(function()
        Window:Destroy()
    end)
end