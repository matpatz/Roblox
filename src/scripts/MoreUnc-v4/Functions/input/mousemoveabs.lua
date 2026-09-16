local Knit = shared.Knit

local VirtualInputManager = Knit.services.VirtualInputManager

return function(x: number, y: number)
    VirtualInputManager:SendMouseMoveEvent(x, y, game)
end
