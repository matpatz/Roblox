local globals = {}

_G.globals = { -- this could, and probably should be a local
    ["hooks"] = {},

    ["c_closures"] = {},
    ["l_closures"] = {},

    ["actor_threads"] = {},

    ["files"] = {},
    ["folders"] = {},

    ["safeenv"] = false,

    ["nilinstances"] = {},
}

globals.set = function(key: string, value)
    _G.globals[key] = value
end

globals.has = function(key: string)
    return _G.globals[key] ~= nil
end

globals.add = function(key: string, value)
    table.insert(_G.globals[key], value)
end

globals.get = function(key: string)
    return _G.globals[key]
end

return globals