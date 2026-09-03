local Aimbot = loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/Modules/Aimbot/v1/main.lua"))()
local Players = game:GetService("Players")

local hrp = Players.LocalPlayer.Character.HumanoidRootPart

local Target, AimPart = Aimbot.GetTarget({
    Origin = hrp.Position,
    Range = 200,
    TeamCheck = false,
    AimPart = "Head",
    Visible = true,
    Blacklist = {}, 
    EntityLists = {
        Players = Players:GetPlayers(),
    },
})

print(Target, AimPart)