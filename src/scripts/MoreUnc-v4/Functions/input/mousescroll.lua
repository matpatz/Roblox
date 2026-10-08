local Knit = shared.Knit

local VirtualInputManager = Knit.services.VirtualInputManager

return function(pixels: number)
    VirtualInputManager:SendMouseWheelEvent(0, 0, pixels > 0, game)
end
