local Knit = shared.Knit

local UserInputService = Knit.services.UserInputService

local isrbxactive = false

UserInputService.WindowFocused:Connect(function()
    isrbxactive = true
end)

UserInputService.WindowFocusReleased:Connect(function()
    isrbxactive = false
end)

return function(): boolean
    return isrbxactive
end
