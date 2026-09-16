local init = {}

local Knit = shared.Knit
local globals = Knit.require(`{shared.script}/Modules`, "globals")

--[[ {
    ["table"] = { -- crypt, closures, whatever.
        function,
        otherfunction
    }
} --]]

local functions = {}
local pending = {}

-- these categories also get mirrored onto getgenv() as a namespace,
-- so getgenv().crypt.hash and getgenv().cache.cloneref reach the same tables
local exported = {
    ["cache"] = true,
    ["Drawing"] = true,
    ["debug"] = true,
    ["crypt"] = true,
    ["raknet"] = true,
}

local function register(path: string, value)
    pending[path] = nil

    local category, name = path:match("^(.+)/([^/]+)$")
    if not category then
        functions[path] = value

        return value
    end

    functions[category] = functions[category] or {}
    functions[category][name] = value

    if exported[category] then -- same table, so later functions show up too
        getgenv()[category] = functions[category]
    end

    if type(value) == "function" then -- flat lookup by bare name
        functions[name] = value
    end

    return value
end

init.getfunctions = function()
    return functions
end

init.getfunction = function(name: string, tbl: string?) -- function
    local path = if tbl then `{tbl}/{name}` else name
    local container
    if tbl then
        container = functions[tbl] or getgenv()[tbl]
    end

    local value = if type(container) == "table" then container[name] else nil

    -- not loaded yet? pull it in now so load order dosent matter
    if value == nil and pending[path] then
        value = register(path, Knit.require(`{shared.script}/Functions`, path))
    end

    -- executor natives (getnilinstances, firesignal, gettenv, ...) live in getgenv()
    return value or functions[name] or getgenv()[name]
end

init.init = function()
    for path in next, Knit.git.clone(`{shared.script}/Functions`) or {} do
        pending[path] = true
    end

    -- snapshot, register() clears pending as it goes
    local paths = {}
    for path in next, pending do
        table.insert(paths, path)
    end

    for _, path in next, paths do
        print("Loading function:", path)

        -- one half finished file shouldnt take the whole loader down with it
        local ok, value = pcall(Knit.require, `{shared.script}/Functions`, path)
        if ok then
            register(path, value)
        else
            pending[path] = nil
            warn(`failed to load {path}: {value}`)
        end
    end

    return functions
end

return init