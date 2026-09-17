local Knit = shared.Knit
local globals = Knit.require("globals")

local instances = game:GetDescendants()

game.DescendantAdded:Connect(function(descendant)
    instances[descendant] = descendant
end)

game.DescendantRemoving:Connect(function(descendant)
    instances[descendant] = nil

    local nilinstances = globals.get("nilinstances")
    table.insert(nilinstances, descendant)
end)

return function()
    return instances
end