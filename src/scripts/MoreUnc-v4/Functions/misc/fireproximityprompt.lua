AddFunction("fireproximityprompt", function(Prompt)
    if not (typeof(Prompt) == "Instance" and Prompt:IsA("ProximityPrompt")) then error("expected ProximityPrompt, got " .. typeof(Prompt), 2) end
    firesignal(Prompt.Triggered, game.Players.LocalPlayer)
end)

local Knit = shared.Knit
local getfunction = Knit.require(`{shared.script}/Functions`, "init")

local firesignal = getfunction("firesignal")

local players = Knit.require(`{shared.script}/Modules`, "players")

return function(prompt: ProximityPrompt)
    firesignal(prompt.Triggered, players.localplayer)
end