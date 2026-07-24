local rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = rayfield:CreateWindow({
    Name = "Lucky Block",
    LoadingTitle = "LuckyBlock",
    LoadingSubtitle = "Subtitle",
    Discord = { Enabled = false },
    KeySystem = false
})

local rep = game:GetService("ReplicatedStorage")
local blocks = {
    Lucky = rep:WaitForChild("SpawnLuckyBlock"),
    Super = rep:WaitForChild("SpawnSuperBlock"),
    Diamond = rep:WaitForChild("SpawnDiamondBlock"),
    Rainbow = rep:WaitForChild("SpawnRainbowBlock")
}

local main = Window:CreateTab("Main")

local selected = blocks["Lucky"]
main:CreateDropdown({
    Name = "Select Block",
    Options = {"Lucky", "Super", "Diamond", "Rainbow"},
    CurrentOption = "Lucky",
    Flag = "bd",
    Callback = function(option)
        selected = blocks[option[1]]
    end
})

main:CreateButton({
    Name = "Open Block",
    Callback = function()
        if selected then
            selected:FireServer()
        end
    end
})
