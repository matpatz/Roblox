local Knit = shared.Knit
local player = Knit.player

-- localplayer was never set, the manager calls it LocalPlayer
player.localplayer = player.LocalPlayer

return player