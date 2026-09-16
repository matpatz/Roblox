local Knit = shared.Knit
local random_string = Knit.require(`{shared.script}/crypt`, "random_string")
local secure_parent = Knit.require(`{shared.script}/instance`, "gethui")()

local instances = {}

instances.new = function(classname: string): Instance
    local instance = Instance.new(classname)
    instance.Name = random_string()
    instance.Parent = secure_parent

    return instance
end

instances.get = function(instance: Instance): Instance
    local instance = secure_parent[instance.Name]
    return instance
end

instances.remove = function(instance: Instance)
    instance:Destroy()
end

return instances