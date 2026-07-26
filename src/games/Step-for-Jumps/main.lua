--[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]
local gname = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))(); --local flags = Rayfield.Flags
local Window = Rayfield:CreateWindow({
	Name = gname,
	LoadingTitle = "fuh you",
	LoadingSubtitle = "subtitle",
})

local main = Window:CreateTab("Main")
main:CreateLabel("Jumps")

local lp = game.Players.LocalPlayer
local function ghrp()
    return lp["Character"]["HumanoidRootPart"]
end

local vim = game:GetService("VirtualInputManager")
local function input(v)
    vim:SendKeyEvent(v, Enum.KeyCode.W, false, game)
end
main:CreateToggle({
	Name = "Auto get Jumps (doesnt work)",
	CurrentValue = false,
	Flag = "aj",
	Callback = function(v)
        input(v)
    end,
})

main:CreateLabel("Rebirth")

local ar
main:CreateToggle({
	Name = "Auto Rebirth",
	CurrentValue = false,
	Flag = "ar",
	Callback = function(v)
        if v then
            lp:SetAttribute("AutoRebirth", true)
        else
            lp:SetAttribute("AutoRebirth", false)
        end
    end,
})

main:CreateLabel("Spins")

local scount = 1
main:CreateSlider({
    Name = "Spins",
    Range = {1, 200},
    Increment = 1,
    Suffix = "Spin",
    CurrentValue = 1,
    Flag = "gs",
    Callback = function(v)
        scount = v
    end,
})

local rep = game:GetService("ReplicatedStorage")
main:CreateButton({
	Name = "Get Spins",
	Callback = function()
        local toget = scount / 2

        for i = 1, toget do
            rep.Remotes.PlaytimeRequest:FireServer(3)
        end
	end,
})

main:CreateButton({
	Name = "Spin",
	Callback = function()
        local toget = scount / 2

        for i = 1, toget do
            rep.Remotes.SpinRequest:InvokeServer()
        end
	end,
})

main:CreateLabel("Misc")

local humanoid = lp["Character"]["Humanoid"]
local schange, jp = false, humanoid.JumpPower
main:CreateToggle({
	Name = "Change Jump",
	CurrentValue = false,
	Flag = "ar",
	Callback = function(v)
        schange = v
    end,
})

main:CreateSlider({
    Name = "Jump Power",
    Range = {1, 2000},
    Increment = 1,
    Suffix = "Power",
    CurrentValue = 1,
    Flag = "gs",
    Callback = function(v)
        humanoid.JumpPower = schange and v or jp
    end,
})

local wins = Window:CreateTab("Wins")
wins:CreateLabel("Main")

local function n(item, ignore, ignore2)
    local hrp = ghrp(); local old = hrp.CFrame
    hrp.CFrame = item.Parent.CFrame; hrp.CFrame = old
end
local fire = firetouchinterest or n

local moon, skylands = workspace.Map.WinPads.Moon_End.Main, workspace.Map.WinPads.Skylands_End.Main
local function win()
	local hrp = ghrp()

    fire(hrp, moon, true); fire(hrp, moon, false)
    fire(hrp, skylands, true) fire(hrp, skylands, false)
end

local aw
wins:CreateToggle({
	Name = "Auto win",
	CurrentValue = false,
    Flag = "aw",
	Callback = function(v)
        if v then
            aw = task.spawn(function()
                while task.wait(1) do
                    win()
                end
            end)
        else
            task.cancel(aw)
            aw = nil
        end
    end,
})

wins:CreateButton({
	Name = "Get 75k wins",
	Callback = function()
        win()
	end,
})

wins:CreateLabel("Obby")

local obby = workspace.Map.WinPads.World1_End.Main
local function win_obby()
    fire(ghrp(), obby, true)
	fire(ghrp(), obby, false)
end

local awo
wins:CreateToggle({
	Name = "Auto win Obby",
	CurrentValue = false,
	Flag = "awn",
	Callback = function(v)
        if v then
            awo = task.spawn(function()
                while task.wait(5) do -- theirs a 5m delay
                    win_obby()
                end
            end)
        else
            task.cancel(awo)
            awo = nil
        end
    end,
})

wins:CreateButton({
	Name = "Win Obby",
	Callback = function()
        win_obby()
	end,
})
