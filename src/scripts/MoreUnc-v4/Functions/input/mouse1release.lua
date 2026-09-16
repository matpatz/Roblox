local Knit = shared.Knit

local UserInputService = Knit.services.UserInputService
local VirtualInputManager = Knit.services.VirtualInputManager

return function()
    local Mouse = UserInputService:GetMouseLocation()
    
    VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, false, game, 0)
end
