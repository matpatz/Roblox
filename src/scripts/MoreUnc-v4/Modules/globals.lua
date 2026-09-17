local globals = {}

_G.globals = { -- this could, and probably should be a local
    ["hooks"] = {},

    ["c_closures"] = {},
    ["l_closures"] = {},

    ["actor_threads"] = {},

    ["files"] = {},
    ["folders"] = {},

    ["safeenv"]
}

globals.set = function(key: string, value)
    _G.globals[key] = value
end

globals.get = function(key: string)
    return _G.globals[key]
end

return globals