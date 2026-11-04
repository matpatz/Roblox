local Knit = shared.Knit
local globals = Knit.require(`{shared.script}/Modules`, "globals")

local tracked: { [Instance]: boolean } = {}

for _, descendant in next, game:GetDescendants() do
    tracked[descendant] = true
end

game.DescendantAdded:Connect(function(descendant)
    tracked[descendant] = true

    local nilinstances = globals.get("nilinstances")
    local at = table.find(nilinstances, descendant)

    if at then -- reparented back into the tree, it isnt nil anymore
        table.remove(nilinstances, at)
    end
end)

game.DescendantRemoving:Connect(function(descendant)
    tracked[descendant] = nil

    local nilinstances = globals.get("nilinstances")

    if not table.find(nilinstances, descendant) then
        table.insert(nilinstances, descendant)
    end
end)

return function(): { Instance }
    local instances = {}

    for instance in next, tracked do
        instances[#instances + 1] = instance
    end

    return instances
end