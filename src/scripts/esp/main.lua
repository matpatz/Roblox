--// Knit
local Knit = shared.Knit
local services = Knit.services

local Rayfield = Knit.ui.new("Rayfield")()

local Window = Rayfield:CreateWindow({
    Name = "Voltex ;)",
    LoadingTitle = "fuh you",
    LoadingSubtitle = "Subtitle",
    ConfigurationSaving = {	
        Enabled = false,
    },
    Discord = {
        Enabled = false,
    },
    KeySystem = false,
})

local visuals = Window:CreateTab("Visuals", 4483362458)
local visualsSection = visuals:CreateSection("Player")

local esp = Knit.require("Libraries/Esp/v1", "main")

local Options = {
    { "Box", "ShowBox" },
    { "Name", "ShowName" },
    { "Held Item", "ShowHeld" },
    { "Tracer", "ShowTracer" },
    --{ "Quad", "ShowQuad" },
    { "Health", "ShowHealth" },
    { "Distance", "ShowDistance" },
    { "Chams", "ShowChams" },
    { "Health Bar", "ShowHealthBar" },
    { "Team Color", "TeamColor" },
    { "Skeleton", "ShowSkeleton" },
    { "3D Box", "Show3DBox" },
    { "Performance Mode", "PerformanceMode" },
}

local OptionNames = table.create(#Options)
for Index, Option in ipairs(Options) do
    OptionNames[Index] = Option[1]
end

local eSettings = visuals:CreateDropdown({
    Name = "Esp Settings",
    Options = OptionNames,
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "",

    Callback = function(selected)
        local Enabled = {}
        for _, Option in ipairs(selected) do
            Enabled[Option] = true
        end

        for _, Option in ipairs(Options) do
            esp:SetProperty(Option[2], Enabled[Option[1]] == true)
        end
    end,
})

visuals:CreateToggle({
    Name = "Enable",
    CurrentValue = false,
    Flag = "",

    Callback = function(v)
        if v then
            esp:Enable()
        else
            esp:Disable()
        end
    end,
})

visuals:CreateSlider({
    Name = "Esp Distance",
    Range = {1, 2000},
    Increment = 10,
    Suffix = "studs",
    CurrentValue = 1000,
    Flag = "",

    Callback = function(v)
        esp:SetProperty("MaxDist", v)
    end,
})

visuals:CreateSection("Colors")

-- Element label -> ESP color setting.
local Colors = {
    { "Box", "BoxColor" },
    { "Name", "NameColor" },
    { "Tracer", "TracerColor" },
    { "Chams", "ChamsColor" },
    { "Skeleton", "SkeletonColor" },
    { "3D Box", "Box3DColor" },
    { "Health Text", "HealthTextColor" },
    { "Health Bar", "HealthBarColorOverride" },
}

for _, Entry in ipairs(Colors) do
    local Name, Property = Entry[1], Entry[2]

    visuals:CreateColorPicker({
        Name = Name,
        Color = esp[Property] or Color3.fromRGB(255, 255, 255),

        Callback = function(Value)
            esp:SetProperty(Property, Value)
        end,
    })
end

Window:CreateTab("rayfield")