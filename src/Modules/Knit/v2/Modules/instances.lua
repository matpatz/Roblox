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

instances.new = function(classname: string): Instance
    local instance = Instance.new(classname)
    instance.Name = random_string(16)
    
    return instance
end

instances.get = function(target: Instance | string, unique_id: string): Instance
    local Found: Instance?
    if unique_id then
        for i, v in target:GetChildren() do
            Found = if v:GetDebugId() == unique_id then v else nil
        end
    else
        Found = secure_parent[target]
    end
    
    return Found
end

instances.remove = function(instance: Instance)
    instance:Destroy()
end

instances.query = function(parent: Instance, classname: string)
    return parent:QueryDescendants(classname)
end

return instances
