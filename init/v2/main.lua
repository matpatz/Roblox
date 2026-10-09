local script: string = shared.script
	-- "scripts/ascii"
	-- "games/catastrophia"

local ok, name = pcall(function() -- used by scriptmanager
    return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
end)

shared.name = ok and name or "Unknown"

local Knit = loadstring(game:HttpGet("https://raw.githubusercontent.com/matpatz/Roblox/refs/heads/main/src/Modules/Knit/v2/main.lua"))()
local Modules = Knit.new({
    "wrappers"
})

local wrappers = Modules.wrappers

local cloneref = wrappers[{
    type = "cache",
    name = "cloneref"
}]

local gethwid = wrappers[{
    type = "misc",
    name = "gethwid"
}]

local Bundler = Knit.require("Modules/Bundler/v1", "main")

local ok1, err = pcall(function()
    task.spawn(function()
        Bundler()
    end)
end); if not ok1 then
    warn(err)
end

local HttpService = cloneref(game:GetService("HttpService"))
local Identifier = gethwid()

local Executor = identifyexecutor and identifyexecutor() or nil

local ok2, err2 = pcall(function()
    error("ur mom")
    local response = request({
        Url = "https://roblox-alpha-murex.vercel.app/api/v1/executions",
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = HttpService:JSONEncode({
            identifier = Identifier,
            game = script,
            executor = Executor
        })
    })
end)

if not ok2 then
    -- warn("Execution log failed:", err2)
end

loadstring(game:HttpGet("https://raw.githubusercontent.com/matpatz/Roblox/refs/heads/main/scriptblox.lua"))()

if not (shared.Webhook and shared.Webhook.Disabled) then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/matpatz/Roblox/refs/heads/main/webhook.lua"))()
end
