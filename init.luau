local GameLoader = loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/games/loader.lua"))()
local InGame = GameLoader.InGame() 

if InGame then
	GameLoader.LoadScript()
end

local Script = shared.script
local ScriptLoader = loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/scripts/loader.lua"))()

if Script and not InGame then
	ScriptLoader.LoadScript()
else
	GameLoader.WrongGame()
end
