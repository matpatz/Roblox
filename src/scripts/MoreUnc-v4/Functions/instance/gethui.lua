local Knit = shared.Knit

local RobloxGui = Knit.services.CoreGui:FindFirstChild("RobloxGui")

return function(): Instance
    return RobloxGui
end