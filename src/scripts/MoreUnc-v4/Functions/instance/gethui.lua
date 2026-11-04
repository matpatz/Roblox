local Knit = shared.Knit

local CoreGui = Knit.services.CoreGui

return function(): Instance
    return CoreGui:FindFirstChild("RobloxGui") or CoreGui
end