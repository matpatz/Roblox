local Script = shared.script
	-- "scripts/ascii"
	-- "games/catastrophia"

local API_URL = "https://roblox-alpha-murex.vercel.app/api/v1/executions"

local Knit = loadstring(game:HttpGet("https://voltex.website/src/Modules/Knit/init.lua"))()
repeat task.wait() until Knit and Knit.wrappers and Knit.services and Knit.git -- and whatever

local wrappers = Knit.wrappers

-- the game scripts read shared.game_name for their window title
local GameOk, GameName = pcall(function()
    return Knit.services.MarketplaceService:GetProductInfo(game.PlaceId).Name
end)

shared.game_name = if GameOk and GameName then GameName else "Unknown"

local Success, Error = pcall(function()
    task.spawn(function()
        --shared.Knit = Knit.cache.set("Knit", Knit) -- Knit will exist for one second, then is deleted.

        loadstring(game:HttpGet(string.format("https://roblox-alpha-murex.vercel.app/src/%s/main.lua", Script)))()
    end)
end); if not Success then
    warn(Error)
end

local HttpService = wrappers.cloneref(game:GetService("HttpService"))
local Identifier = wrappers.gethwid()

local success, err = pcall(function()
    local response = request({
        Url = API_URL,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = HttpService:JSONEncode({
            identifier = Identifier 
        })
    })
end)

if not success then
    warn("Execution log failed:", err)
end

if not (shared.Webhook and shared.Webhook.Disabled) and shared.webhook_disabled ~= true then
    loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/webhook.lua"))()
end
