local Knit = shared.Knit
local player = Knit.require(`{shared.script}/Modules`, "player")

return function(ClickDetector: Instance, Distance: number, Signal)
    local HumanoidRootPart = player.HumanoidRootPart
    if not HumanoidRootPart then
        return
    end

    local CFrame = HumanoidRootPart.CFrame
    HumanoidRootPart.CFrame = ClickDetector.Parent.CFrame

    -- firesignal whatever here

    task.delay(1, function()
        if HumanoidRootPart then
            HumanoidRootPart.CFrame = CFrame
        end
    end)
end