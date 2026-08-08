local Services = loadstring(game:HttpGet(
    "https://roblox-alpha-murex.vercel.app/src/Modules/Variables.lua"
))()

local Game = Services["MarketplaceService"]:GetProductInfo(game.PlaceId).Name

local Rayfield = loadstring(game:HttpGet(
    "https://website-iota-ivory-12.vercel.app/code/loader/u/ui/rayfield.lua"
))()

local Window = Rayfield:CreateWindow({
    Name = Game,
    LoadingTitle = "fah you",
    LoadingSubtitle = "subtitle",
})

local tabs = {
    main = Window:CreateTab("Main"),
    shop = Window:CreateTab("shop"),
    teleports = Window:CreateTab("teleports"),
    settings = Window:CreateTab("Settings"),
}

local connections = {
    communication = {},
    table = {},
    gameplay = {},
}

local states = {
    runtime = {},

    values = {
        AutofarmMoney = false,
        UpgradeSpeed = false,

        SelectedEgg = "",
    },
}

local responses = {}

local function SetValue(obj, key, value)
    obj[key] = value
end

local function addConnection(category: table, name: string, connection: RBXScriptConnection)
    if category[name] then
        pcall(function()
            if typeof(category[name]) == "RBXScriptConnection" then
                category[name]:Disconnect()
            else
                task.cancel(category[name])
            end
        end)
    end

    category[name] = connection
    states.runtime[name] = true
end

local function removeConnection(category: table, name: string)
    if not category[name] then return end

    pcall(function()
        if typeof(category[name]) == "RBXScriptConnection" then
            category[name]:Disconnect()
        else
            task.cancel(category[name])
        end
    end)

    category[name] = nil
    states.runtime[name] = false
end

tabs.main:CreateLabel("Autofarm")

local MoneyPickUp = Services["ReplicatedStorage"].RemoteEvents.MoneyPickedUp
local function ObtainMoney(Money)
    MoneyPickUp:FireServer(
        Money and Money or 1e5
    )
end

tabs.main:CreateToggle({
    Name = "Autofarm Money",
    CurrentValue = false,
    Callback = function(value)
        SetValue(states.values, "AutofarmMoney", value)

        if value then
            addConnection(connections.gameplay, "AutofarmMoney", task.spawn(function()
                while task.wait(.2) do
                    ObtainMoney()

                    if not states.values.AutofarmMoney then
                        break
                    end
                end
            end))
        else
            removeConnection(connections.gameplay, "AutofarmMoney")
        end
    end,
})

tabs.main:CreateButton({
    Name = "Get a bazillion dollars",
    Callback = function()
        ObtainMoney(1e32)
    end,
})

local CanBuyUpgrade = Services["ReplicatedStorage"].RemoteFunctions.CanBuyUpgrade
local PlateUpgrade = Services["ReplicatedStorage"].RemoteEvents.PlateUpgrade

local function UpgradeSpeed()
    if not CanBuyUpgrade:InvokeServer() then
        return
    end
    PlateUpgrade:FireServer()
end

tabs.shop:CreateToggle({
    Name = "Auto Upgrade Speed",
    CurrentValue = false,
    Callback = function(value)
        SetValue(states.values, "UpgradeSpeed", value)

        if value then
            addConnection(connections.gameplay, "UpgradeSpeed", task.spawn(function()
                while task.wait(.1) do
                    UpgradeSpeed()

                    if not states.values.UpgradeSpeed then
                        break
                    end
                end
            end))
        else
            removeConnection(connections.gameplay, "UpgradeSpeed")
        end
    end,
})

tabs.shop:CreateLabel("Eggs--you need to leave/rejoin or delete something from your inventory for it to load")

local Eggs = {
	"WinterCapsule",
	"TropicalCapsule",
	"ThirdEggCapsule",
	"TheGoldenSkiesCapsule",
	"SecondWinterCapsule",
	"SecondTropicalCapsule",
	"SecondTheGoldenSkiesCapsule",
	"SecondMagicCapsule",
	"SecondLostJungleCapsule",
	"SecondLavaCapsule",
	"SecondAlienCapsule",
	"RoyalEggCapsule",
	"RoyalEggCapsule",
	"RoyalEggCapsule",
	"RoyalEggCapsule",
	"RoyalEggCapsule",
	"MagicCapsule",
	"LostJungleCapsule",
	"LavaCapsule",
	"EggCapsule",
	"AnimalsCapsule",
	"AlienCapsule",
	"GalacticEggCapsule",
	"GalacticEggCapsule",
	"GalacticEggCapsule"
}

local EggOpened = Services["ReplicatedStorage"].RemoteFunctions.EggOpened

tabs.shop:CreateDropdown({
    Name = "Select Egg",
    Options = Eggs,
    Callback = function(option)
        SetValue(states.values, "SelectedEgg", option[1])
    end,
})

local function BuyEgg()
    EggOpened:InvokeServer(
        states.values.SelectedEgg,
        {} -- idk
    )
end

tabs.shop:CreateButton({
    Name = "Buy Egg",
    Callback = function()
        BuyEgg()
    end,
})

local Worlds = {
	"ForestWorld",
	"TropicalWorld",
	"LavaWorld",
	"WinterWorld",
	"MagicWorld",
	"AstralWorld",
	"TheGoldenSkies",
	"LostJungle"
}

local TeleportToBiome = Services["ReplicatedStorage"].RemoteEvents.TeleportToBiome

tabs.teleports:CreateDropdown({
    Name = "Model",
    Options = Worlds,
    Callback = function(option)
        TeleportToBiome:FireServer(
            option[1]
        )
    end,
})

tabs.settings:CreateLabel("Lebron james!")

Rayfield:Notify({
    Title = Game,
    Content = "Successfully Loaded!",
    Duration = 5,
    Image = 4483362458,
})