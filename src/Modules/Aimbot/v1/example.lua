const Aimbot = loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/Modules/Aimbot/v1/main.lua"))()

local Target, AimPart = Aimbot.GetClosest({
    Origin = v14.StartCFrame,          -- CFrame / Vector3 / BasePart all work
    Range = 200,
    TeamCheck = true,
    AimPart = "Head",
    Visible = true,
    Blacklist = { myFriend, adminPlayer },  -- Player/Instance or list, never targeted
    EntityLists = {
        NPCs    = workspace.Zombies:GetChildren(),
        Players = Players:GetPlayers(),
    },
})