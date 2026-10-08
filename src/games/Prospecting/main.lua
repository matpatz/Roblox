--// Knit
local Knit = shared.Knit
const services = Knit.services

--// services
const LocalPlayer = services.Players.LocalPlayer

--// config
local config = {
    AutoFarm = {
        Enabled = true,
    },
    -- where to stand while the pan fills (shaking only fills the pan in range)
    PlayerPosition = nil,
    -- where to stand while panning
    WaterPosition = nil,
    -- seconds between pan calls. lower = faster
    PanSpeed = 0.05,
}

--// cheat
local cheat = {
    Utils = {},
    Core = {
        AutoFarm = {},
    },
}
local Utils = cheat.Utils
local Core = cheat.Core

--// Utils

Utils.Root = function()
    local Character = LocalPlayer.Character

    return Character and Character:FindFirstChild("HumanoidRootPart")
end

-- the pan tool owns the remotes and the fill ui, so nothing below exists
-- while it is unequipped
Utils.Tool = function()
    local Character = LocalPlayer.Character

    return Character and Character:FindFirstChildOfClass("Tool")
end

-- Collect / Pan / Shake live under the tool's Scripts folder
Utils.Remote = function(Name: string)
    local Tool = Utils.Tool()
    local Scripts = Tool and Tool:FindFirstChild("Scripts")

    return Scripts and Scripts:FindFirstChild(Name)
end

-- the fill meter reads "12/40"
Utils.Fill = function()
    local ToolUI = LocalPlayer.PlayerGui:FindFirstChild("ToolUI")
    local FillingPan = ToolUI and ToolUI:FindFirstChild("FillingPan")
    local FillText = FillingPan and FillingPan:FindFirstChild("FillText")

    return tonumber(FillText and FillText.Text:match("^(%d+)") or "0") or 0
end

Utils.Capacity = function()
    local Tool = Utils.Tool()
    local Stats = Tool and Tool:FindFirstChild("Stats")

    return Stats and Stats:GetAttribute("Capacity") or 0
end

--// Core

-- "Collecting" while the pan fills, "Panning" while the dirt is washed out
local action = "Collecting"

Core.AutoFarm.Enabled = function()
    action = "Collecting"

    Core.AutoFarm.Loop = task.spawn(function()
        while true do
            local Root = Utils.Root()
            local Tool = Utils.Tool()

            if Root and Tool then
                if action == "Collecting" then
                    local Shake = Utils.Remote("Shake")
                    if Shake then
                        Shake:FireServer()
                    end

                    -- the pan only fills while it is shaken in range, so hold the spot
                    if config.PlayerPosition then
                        Root.CFrame = config.PlayerPosition
                    end

                    local Collect = Utils.Remote("Collect")
                    if Collect then
                        Collect:InvokeServer(1)
                    end

                    task.wait(0.02)

                    if Utils.Fill() >= Utils.Capacity() then
                        action = "Panning"
                    end
                else
                    if config.WaterPosition then
                        Root.CFrame = config.WaterPosition
                    end

                    local Pan = Utils.Remote("Pan")
                    if Pan then
                        Pan:InvokeServer()
                    end

                    local Shake = Utils.Remote("Shake")
                    if Shake then
                        Shake:FireServer()
                    end

                    task.wait(config.PanSpeed)

                    -- the pan empties itself once the dirt is panned out
                    if Utils.Fill() == 0 then
                        action = "Collecting"
                    end
                end
            end

            task.wait(0.02)
        end
    end)
end

Core.AutoFarm.Disable = function()
    if Core.AutoFarm.Loop then
        task.cancel(Core.AutoFarm.Loop)
        Core.AutoFarm.Loop = nil
    end
end

--// Interface

local Game = shared.game_name or shared.name or "Prospecting"

local Rayfield = Knit.ui.new("Rayfield")()
const Window = Rayfield:CreateWindow({
    Name = Game,
    LoadingTitle = "Loading...",
    LoadingSubtitle = "#matpatz",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "voltexconfig",
        FileName = Game,
    },
})

const tabs = {
    Main = Window:CreateTab("Main"),
    Settings = Window:CreateTab("Settings"),
}

--// Main

tabs.Main:CreateToggle({
    Name = "Auto Collect / Pan / Sell",
    CurrentValue = config.AutoFarm.Enabled,
    Flag = "AutoFarm",
    Callback = function(Value)
        config.AutoFarm.Enabled = Value
        ;(Value and Core.AutoFarm.Enabled or Core.AutoFarm.Disable)()
    end,
})

--// Settings

tabs.Settings:CreateSection("Position saving")

tabs.Settings:CreateButton({
    Name = "Save Player Position",
    Callback = function()
        local Root = Utils.Root()

        if not Root then
            Rayfield:Notify({ Title = Game, Content = "No character" })
            return
        end

        config.PlayerPosition = Root.CFrame

        Rayfield:Notify({ Title = Game, Content = "Player position saved" })
    end,
})

tabs.Settings:CreateButton({
    Name = "Save Water Position",
    Callback = function()
        local Root = Utils.Root()

        if not Root then
            Rayfield:Notify({ Title = Game, Content = "No character" })
            return
        end

        config.WaterPosition = Root.CFrame

        Rayfield:Notify({ Title = Game, Content = "Water position saved" })
    end,
})

tabs.Settings:CreateButton({
    Name = "Clear Saved Positions",
    Callback = function()
        config.PlayerPosition = nil
        config.WaterPosition = nil

        Rayfield:Notify({ Title = Game, Content = "Positions cleared" })
    end,
})

tabs.Settings:CreateSection("Panning")

tabs.Settings:CreateSlider({
    Name = "Pan Speed (lower = faster)",
    Range = { 0.01, 0.2 },
    Increment = 0.01,
    Suffix = "s",
    CurrentValue = config.PanSpeed,
    Flag = "PanSpeed",
    Callback = function(Value)
        config.PanSpeed = Value
    end,
})

-- Rayfield only runs a toggle callback once the user touches the toggle, so a
-- config that is already on has to be started here or nothing ever runs
if config.AutoFarm.Enabled then
    Core.AutoFarm.Enabled()
end
