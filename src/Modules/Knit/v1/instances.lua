local Knit = shared.Knit
local secure_parent = Knit.require(`scripts/MoreUnc-v4/Functions/instance`, "gethui")()

local instances = {}

local Random = Random.new()

local id = 0

local function random_string(length: number): string
    local charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local parts = table.create(length)

    for index = 1, length do
        local at = Random:NextInteger(1, #charset)
        parts[index] = charset:sub(at, at)
    end

    return table.concat(parts)
end

instances.new = function(classname: string, random_name: boolean?): Instance
    local instance = Instance.new(classname)

    if random_name then
        instance.Name = random_string(16)
    else
        id += 1
        instance.Name = tostring(id)
    end

    instance.Parent = secure_parent

    return instance
end

instances.get = function(target: Instance | string): Instance
    local found_instance
    if type(target) == "userdata" then
        found_instance = secure_parent[target]
    else -- string
        found_instance = secure_parent[target]
    end
    return found_instance
end

instances.remove = function(instance: Instance)
    instance:Destroy()
end

instances.query = function(classname: string)
    return game:QueryDescendants(classname)
end

return instances