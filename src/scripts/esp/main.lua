if getgenv().v then -- oh no its open source
    local Rayfield = loadstring(game:HttpGet("https://website-iota-ivory-12.vercel.app/code/loader/u/ui/rayfield.lua"))()
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

    local cesp = loadstring(game:HttpGet("https://website-iota-ivory-12.vercel.app/code/loader/u/esp.lua"))(); local esp = cesp()
    
    local eSettings = visuals:CreateDropdown({
        Name = "Esp Settings",
        Options = {
            "Box",
            "Corners",
            "Name",
            "Held Item",
            "Tracer",
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
            esp:box(false)
            esp:corners(false)
            esp:name(false)
            esp:held(false)
            esp:tracer(false)
            esp:quad(false)
            esp:health(false)
            esp:distance(false)
            esp:chams(false)
            esp:healthbar(false)
            esp:team(false)
            esp:performance(false)
            esp:skeleton(false)
            esp:box3d(false)

            for _, option in ipairs(selectedOptions) do
                if option == "Box" then
                    esp:box(true)
                elseif option == "Corners" then
                    esp:corners(true)
                elseif option == "Name" then
                    esp:name(true)
                elseif option == "Held Item" then
                    esp:held(true)
                elseif option == "Tracer" then
                    esp:tracer(true)
                elseif option == "Quad" then
                    esp:quad(true)
                elseif option == "Health" then
                    esp:health(true)
                elseif option == "Distance" then
                    esp:distance(true)
                elseif option == "Chams" then
                    esp:chams(true)
                elseif option == "Health Bar" then
                    esp:healthbar(true)
                elseif option == "Team Color" then
                    esp:team(true)
                elseif option == "Performance Mode" then
                    esp:performance(true)
                elseif option == "Skeleton" then
                    esp:skeleton(true)
                elseif option == "3D Box" then
                    esp:box3d(true)
                end
            end
        end,
    })

    local espToggle = visuals:CreateToggle({
        Name = "Enable",
        CurrentValue = false,
        Flag = "met",
        Callback = function(v)
            if v then esp:enable() else esp:disable() end
        end,
    })

    visuals:CreateSlider({
    Name = "Esp Distance",
    Range = {1, 2000},
    Increment = 10,
    Suffix = "studs",
    CurrentValue = 1000,
    Flag = "ed",
    Callback = function(v) esp:dist(v) end,
    })
end
