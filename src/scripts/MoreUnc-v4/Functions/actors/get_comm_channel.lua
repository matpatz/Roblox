local Knit = shared.Knit
local instances = Knit.require(`{shared.script}/Modules`, "instances")

return function(id: number): BindableEvent
    local BindableEvent = instances.get(id)
    return BindableEvent
end