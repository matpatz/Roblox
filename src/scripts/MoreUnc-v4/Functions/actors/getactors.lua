local Knit = shared.Knit
local instances = Knit.require(`{shared.script}/Modules`, "instances")

return function(): { Actors }
    return instances.query("Actors")
end