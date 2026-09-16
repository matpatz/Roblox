local Knit = shared.Knit
local getfunction = Knit.require(`{shared.script}/Functions`, "init")

local firesignal = getfunction("firesignal")

local players = Knit.require(`{shared.script}/Modules`, "players")

return function(prompt: ProximityPrompt)
    firesignal(prompt.Triggered, players.localplayer)
end