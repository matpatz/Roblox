local Knit = shared.Knit
local getfunction = Knit.require(`{shared.script}/Functions`, "main").getfunction

local firesignal = getfunction("firesignal", "instance")

local player = Knit.require(`{shared.script}/Modules`, "player")

return function(prompt: ProximityPrompt)
    firesignal(prompt.Triggered, player.localplayer)
end