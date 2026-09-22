local Script = shared.script
	-- "scripts/ascii"
	-- "games/catastrophia"

local API_URL = "https://roblox-alpha-murex.vercel.app/api/v1/executions"

-- scriptmanager captures shared.name while Knit is being required, so it has to
-- exist before the loadstring below
local ok, name = pcall(function()
    return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
end)

shared.name = if ok and name then name else "Unknown"

local Knit = loadstring(game:HttpGet("https://voltex.website/src/Modules/Knit/init.lua"))()
repeat task.wait() until Knit and Knit.wrappers and Knit.services and Knit.git -- and whatever

local wrappers = Knit.wrappers

local Success, Error = pcall(function()
    task.spawn(function()
        Knit.bundle()
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
