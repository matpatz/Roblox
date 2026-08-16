local Rayfield = loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/libraries/Rayfield/main.lua"))()

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

local esp = loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/Libraries/Esp/main.lua"))()

local eSettings = visuals:CreateDropdown({
    Name = "Esp Settings",
    Options = {
        "Box",
        "Corners",
        "Name",
        "Held Item",
        "Tracer",
        "Quad",
        "Health",
        "Distance",
        "Chams",
        "Health Bar",
        "Team Color",
        "Performance Mode",
        "Skeleton",
        "3D Box",
    },
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "ef",

    Callback = function(selectedOptions)
        -- Reset all options
        esp:SetProperty("ShowBox", false)
        esp:SetProperty("ShowCorners", false)
        esp:SetProperty("ShowName", false)
        esp:SetProperty("ShowHeld", false)
        esp:SetProperty("ShowTracer", false)
        esp:SetProperty("ShowQuad", false)
        esp:SetProperty("ShowHealth", false)
        esp:SetProperty("ShowDistance", false)
        esp:SetProperty("ShowChams", false)
        esp:SetProperty("ShowHealthBar", false)
        esp:SetProperty("TeamColor", false)
        esp:SetProperty("PerformanceMode", false)
        esp:SetProperty("ShowSkeleton", false)
        esp:SetProperty("Show3DBox", false)

        -- Enable selected options
        for _, option in ipairs(selectedOptions) do
            if option == "Box" then
                esp:SetProperty("ShowBox", true)
            elseif option == "Corners" then
                esp:SetProperty("ShowCorners", true)
            elseif option == "Name" then
                esp:SetProperty("ShowName", true)
            elseif option == "Held Item" then
                esp:SetProperty("ShowHeld", true)
            elseif option == "Tracer" then
                esp:SetProperty("ShowTracer", true)
            elseif option == "Quad" then
                esp:SetProperty("ShowQuad", true)
            elseif option == "Health" then
                esp:SetProperty("ShowHealth", true)
            elseif option == "Distance" then
                esp:SetProperty("ShowDistance", true)
            elseif option == "Chams" then
                esp:SetProperty("ShowChams", true)
            elseif option == "Health Bar" then
                esp:SetProperty("ShowHealthBar", true)
            elseif option == "Team Color" then
                esp:SetProperty("TeamColor", true)
            elseif option == "Performance Mode" then
                esp:SetProperty("PerformanceMode", true)
            elseif option == "Skeleton" then
                esp:SetProperty("ShowSkeleton", true)
            elseif option == "3D Box" then
                esp:SetProperty("Show3DBox", true)
            end
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