local GameList = {
    [662417684] = {name = "Lucky-Blocks-Battleground"},
    [129827112113663] = {name = "Prospecting"},
    [11966456877] = {name = "Answer-Or-Die"},
    [88817068170433] = {name = "Guess-The-Flag-Or-Die"},
	  [101759436219635] = {name = "Idle-Blocks"},
	  [3082002798] = {name = "Teen-Titan-Battleground"}

	-- 106931261124996 ?? idk
}

local PlaceId = GameList[game.PlaceId]

return {
	IsCorrectGame = function()
		return PlaceId
	end,
	Warning = function()
		local Names = {}
		for _, Game in next, (GameList) do
			table.insert(Names, Game.name)
		end
		warn("Please join one of our supported games: " .. table.concat(Names, ", "))
	end,
	Load = function()
		loadstring(game:HttpGet("https://roblox-alpha-murex.vercel.app/src/games/" .. PlaceId.name .. "/main.lua"))()
	end
}

--[[
if IsCorrectGame() then
	Load()
else
	Warning()
end
]]
