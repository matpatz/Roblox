local Services = loadstring(game:HttpGet(
    "https://roblox-alpha-murex.vercel.app/src/Modules/Variables.lua"
))() 

local PlaceId = game.PlaceId
local Script = shared.script
local Game = Services["MarketplaceService"]:GetProductInfo(place).Name

local Player = Services["Players"].LocalPlayer

local Payload = {
    User = Player.Name,
    UserId = Player.UserId,

    Executor = identifyexecutor() or "Unknown",

    Script = Script,
    Game = Game or "Unknown",
    PlaceId = PlaceId
}

request({
    Url = "https://website-iota-ivory-12.vercel.app/api/webhook.js",

    Method = "POST",

    Headers = {
        ["Content-Type"] = "application/json"
    },

    Body = Services["HttpService"]:JSONEncode(Payload)
})
