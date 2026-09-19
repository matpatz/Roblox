local scriptmanager = {}

local Knit = shared.Knit
local instances = Knit.instances

scriptmanager.name = shared.name

scriptmanager.config = {
    set = function(cfg)
        scriptmanager.scriptconfig = cfg
        return cfg
    end,
    get = function()
        return scriptmanager.scriptconfig
    end
}

scriptmanager.set = function(key, value)
    if not value.Once then
        value.Once = instances.new("BindableEvent", true)
    end
    scriptmanager[key] = value
end

scriptmanager.get = function(key)
    return scriptmanager[key]
end

return scriptmanager