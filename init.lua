local GameLoader = loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/games/loader.lua"))()
local ValidGame = GameLoader.IsValid

if ValidGame then
	GameLoader.LoadScript()
end

local ScriptLoader = loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/scripts/loader.lua"))()

if ScriptLoader.IsValid and not ValidGame then
	ScriptLoader.LoadScript()
else
	GameLoader.Error()
end

-- loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/init.lua"))()
