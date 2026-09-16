local Knit = shared.Knit
local instances = Knit.require(`{shared.script}/Modules`, "instances")

return function(): (number, BindableEvent)
    local BindableEvent = instances.new("BindableEvent", false)
    local id = BindableEvent.Name
    
    return id, BindableEvent
end