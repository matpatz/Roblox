local Knit = shared.Knit
local getfunction = Knit.require(`{shared.script}/Functions`, "main").getfunction
local player = Knit.require(`{shared.script}/Modules`, "player")

local firesignal = getfunction("firesignal", "instance")

return function(ClickDetector: Instance, distance: number?, signal: string?)
    if typeof(ClickDetector) ~= "Instance" or not ClickDetector:IsA("ClickDetector") then
        error(`expected ClickDetector, got {typeof(ClickDetector)}`, 2)
    end

    distance = distance or 0
    signal = signal or "MouseClick"

    local HumanoidRootPart = player.HumanoidRootPart
    local OldCFrame = HumanoidRootPart and HumanoidRootPart.CFrame

    if HumanoidRootPart and distance ~= 0 and ClickDetector.Parent then
        HumanoidRootPart.CFrame = ClickDetector.Parent.CFrame
    end

    ClickDetector.MaxActivationDistance = math.huge

    local signal_object = ClickDetector[signal]

    if signal_object then
        firesignal(signal_object, player.LocalPlayer)
    end

    if HumanoidRootPart and OldCFrame then
        HumanoidRootPart.CFrame = OldCFrame
    end
end