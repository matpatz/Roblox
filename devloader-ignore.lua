shared.script = "games/Schorched-Earth"

local ok, info = pcall(function()
    return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
end)

shared.name = if ok and info then info else "Unknown"

local Knit = loadstring(game:HttpGet("https://voltex.website/src/Modules/Knit/init.lua"))()
repeat task.wait() until Knit and Knit.wrappers and Knit.services and Knit.git

Knit.bundle()