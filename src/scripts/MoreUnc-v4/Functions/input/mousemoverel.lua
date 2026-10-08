local Knit = shared.Knit

local UserInputService = Knit.services.UserInputService
local VirtualInputManager = Knit.services.VirtualInputManager

return function(x: number, y: number)
    local Mouse = UserInputService:GetMouseLocation()
    VirtualInputManager:SendMouseMoveEvent(Mouse.X + x, Mouse.Y + y, game)
end
