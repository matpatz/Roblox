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

local esp = Knit.require("Libraries/Esp", "main")

local Options = {
    { "Box", "ShowBox" },
    { "Corners", "ShowCorners" },
    { "Name", "ShowName" },
    { "Held Item", "ShowHeld" },
    { "Tracer", "ShowTracer" },
    { "Quad", "ShowQuad" },
    { "Health", "ShowHealth" },
    { "Distance", "ShowDistance" },
    { "Chams", "ShowChams" },
    { "Health Bar", "ShowHealthBar" },
    { "Team Color", "TeamColor" },
    { "Performance Mode", "PerformanceMode" },
    { "Skeleton", "ShowSkeleton" },
    { "3D Box", "Show3DBox" },
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
    Flag = "ef",

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

local espToggle = visuals:CreateToggle({
    Name = "Enable",
    CurrentValue = false,
    Flag = "met",

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
    Flag = "ed",

    Callback = function(v)
        esp:SetProperty("MaxDist", v)
    end,
})

local rf = Window:CreateTab("rayfield")