local Knit = shared.Knit
local ui = Knit.ui
local scriptmanager = Knit.scriptmanager

local name = scriptmanager.name

local config = scriptmanager.config.get()
local core = scriptmanager.get("core")
local utils = scriptmanager.get("utils")

local Rayfield = ui.new("Rayfield")()
local Window = Rayfield:CreateWindow({
    Name = name,
    LoadingTitle = "Loading...",
    LoadingSubtitle = "#matpatz",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "voltexconfig",
        FileName = name,
    },
})

local tabs = {
    Draft = Window:CreateTab("Draft"),
    Opponent = Window:CreateTab("Opponent"),
}

tabs.Draft:CreateSection("Auto draft")

tabs.Draft:CreateToggle({
    Name = "Auto Draft",
    CurrentValue = config.AutoDraft.Value,
    Flag = "AutoDraft",
    Callback = function(value)
        config.AutoDraft.Value = value
        ;(value and core.AutoDraft.Enabled or core.AutoDraft.Disable)()
    end,
})

tabs.Draft:CreateSection("What it will pay")

tabs.Draft:CreateToggle({
    Name = "Read real power from the theme",
    CurrentValue = config.UsePower.Value,
    Flag = "UsePower",
    Callback = function(value)
        config.UsePower.Value = value
    end,
})

tabs.Draft:CreateSlider({
    Name = "Top Lot Is Worth X Even Shares",
    Range = { 1, 5 },
    Increment = 0.5,
    Suffix = "x",
    CurrentValue = config.PowerBoost.Value,
    Flag = "PowerBoost",
    Callback = function(value)
        config.PowerBoost.Value = value
    end,
})

tabs.Draft:CreateToggle({
    Name = "Never Overpay (cap at their wallet)",
    CurrentValue = config.NeverOverpay.Value,
    Flag = "NeverOverpay",
    Callback = function(value)
        config.NeverOverpay.Value = value
    end,
})

tabs.Draft:CreateToggle({
    Name = "Always Bid (ignore value)",
    CurrentValue = config.AlwaysBid.Value,
    Flag = "AlwaysBid",
    Callback = function(value)
        config.AlwaysBid.Value = value
    end,
})

tabs.Draft:CreateSlider({
    Name = "Reserve",
    Range = { 0, 20 },
    Increment = 1,
    Suffix = "$",
    CurrentValue = config.Reserve.Value,
    Flag = "Reserve",
    Callback = function(value)
        config.Reserve.Value = value
    end,
})

tabs.Draft:CreateSlider({
    Name = "Max Bid (0 = off)",
    Range = { 0, 20 },
    Increment = 1,
    Suffix = "$",
    CurrentValue = config.MaxBid.Value,
    Flag = "MaxBid",
    Callback = function(value)
        config.MaxBid.Value = value
    end,
})

tabs.Draft:CreateSection("Manual")

tabs.Draft:CreateButton({
    Name = "Raise",
    Callback = function()
        task.spawn(core.AutoDraft.Raise)
    end,
})

tabs.Draft:CreateButton({
    Name = "Pass",
    Callback = function()
        task.spawn(core.AutoDraft.Pass)
    end,
})

--// Opponent

tabs.Opponent:CreateSection("Both wallets")

local status = tabs.Opponent:CreateParagraph({
    Title = "Waiting",
    Content = "No draft in progress.",
})

tabs.Opponent:CreateSection("Manual")

tabs.Opponent:CreateButton({
    Name = "Show what it sees",
    Callback = function()
        local current = core.AutoDraft.State()

        if not current then
            Rayfield:Notify({ Title = name, Content = "No draft in progress." })
            return
        end

        Rayfield:Notify({
            Title = name,
            Content = string.format(
                "power %s  lot %s  price $%s  worth $%s  ceiling $%s",
                tostring(utils.Power(current.object, current.theme) or "?"),
                tostring(current.lot),
                tostring(current.price),
                tostring(utils.Budget(current)),
                tostring(utils.Ceiling(current))
            ),
        })
    end,
})

task.spawn(function()
    while true do
        task.wait(0.25)

        local ok, result = pcall(core.AutoDraft.Status)

        if ok and result then
            status:Set(result)
        end
    end
end)

-- Rayfield only runs a toggle callback once the user touches the toggle, so a
-- config that is already on has to be started here or nothing ever runs
if config.AutoDraft.Value then
    core.AutoDraft.Enabled()
end

return true
