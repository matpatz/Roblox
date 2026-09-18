local Knit = shared.Knit
local services = Knit.services

local PlaceId = game.PlaceId
local script: string = shared.script

local name = services.MarketplaceService:GetProductInfo(PlaceId).Name
shared.game_name = name

local Player = services.Players.LocalPlayer

local Payload = {
    User = Player.Name,
    UserId = Player.UserId,

    Executor = identifyexecutor(),

    Script = script,
    Game = name or "Unknown",
    PlaceId = PlaceId
}

request({
    Url = "https://dtfnhmehvzqcgwwdkmzh.supabase.co/functions/v1/webhook", -- pls dont hurt me

    Method = "POST",

    Headers = {
        ["Content-Type"] = "application/json"
    },

    Body = services.HttpService:JSONEncode(Payload)
})

-- shared.script = nil
    -- used in the Knit system