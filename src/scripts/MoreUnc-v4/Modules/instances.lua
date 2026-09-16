local Knit = shared.Knit
local random_string = Knit.require(`{shared.script}/crypt`, "random_string")
local secure_parent = Knit.require(`{shared.script}/instance`, "gethui")()

local instances = {}

local id = 0
instances.new = function(classname: string, random_name: boolean?): Instance
    local instance = Instance.new(classname)
    if random_name then
        instance.Name = random_string()
    else
        instance.Name = tostring(id += 1)
    end
    instance.Parent = secure_parent

    return instance
end

instances.get = function(target: Instance | string): Instance
    local found_instance
    if type(target) == "userdata" then
        found_instance = secure_parent[instance.Name]
    else -- string
        found_instance = secure_parent[target]
    end
    return found_instance
end

instances.remove = function(instance: Instance)
    instance:Destroy()
end

instances.query = function(classname: string)
    return game:QueryDesendants(classname)
end

instances.assign_ui_corner = function(parent, radius: table)
    local UiCorner = instances.new("UiCorner")
    UiCorner.CornerRadius = radius

    return UiCorner
end

return instances