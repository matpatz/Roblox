--local Knit = shared.Knit
--local path = `{Knit.paths["local"].directory}/assets`

local Molto = loadstring(game:HttpGet("https://molto.pages.dev/source.lua"))()


return function(provider: string, icon: string)
    Molto.SetProvider(provider)

    return Molto.GetAsset(icon)
end

--[[
local Icons = loadstring(game:HttpGet("https://molto.pages.dev/source.lua"))()
Icons.SetProvider("lucide")

local icon = Icons.GetAsset("moon")
]]