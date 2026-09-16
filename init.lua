local Script = shared.script
	-- "scripts/ascii"
	-- "games/catastrophia"

local API_URL = "https://roblox-alpha-murex.vercel.app/api/v1/executions"

local Knit = loadstring(game:HttpGet("https://voltex.website/src/Modules/Knit/init.lua"))()
local wrappers = Knit.wrappers

local Success, Error = pcall(function()
    task.spawn(function()
        shared.Knit = Knit.cache.set("Knit", Knit) -- Knit will exist for one second, then is deleted.

        loadstring(game:HttpGet(string.format("https://roblox-alpha-murex.vercel.app/src/%s/main.lua", Script)))()
    end)
end); if not Success then
    warn(Error)
end

local cloneref = wrappers.cloneref

local HttpService = cloneref(game:GetService("HttpService"))

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
if shared.Webhook and shared.Webhook.Disabled then
    loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/webhook.lua"))()
end
