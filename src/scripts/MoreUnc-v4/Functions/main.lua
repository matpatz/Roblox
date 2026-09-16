local init = {}

local Knit = shared.Knit

-- { ["table"] = { function, otherfunction } } -- crypt, closures, whatever.
local functions: { [string]: any } = {}
local pending: { [string]: boolean } = {}

-- these categories also get mirrored onto getgenv() as a namespace,
-- so getgenv().crypt.hash and getgenv().cache.cloneref reach the same tables
local exported = {
    ["cache"] = true,
    ["crypt"] = true,
    ["debug"] = true,
    ["drawing"] = true,
    ["raknet"] = true,
}

local env = getgenv()
local cclosure = env.newcclosure -- most executors have it
local setinfo = env.debug and env.debug.setinfo -- not standard, most executors wont have it

local function mask(func, name: string)
    local wrapped = if cclosure then cclosure(func, name) else func

    if setinfo then
        pcall(setinfo, wrapped, {
            name = name,
            source = nil,
            short_src = "[C]",
            currentline = -1,
            what = "C",
        })
    end

    return wrapped
end

local function register(path: string, value: any)
    pending[path] = nil

    local category, name = path:match("^(.+)/([^/]+)$")
    local isfunction = type(value) == "function"

    if isfunction then -- mask first, so every table below holds the same closure
        value = mask(value, name or path)
    end

    if not category then
        functions[path] = value

        return value
    end

    functions[category] = functions[category] or {}
    functions[category][name] = value

    if exported[category] then -- same table, so later functions show up too
        env[category] = functions[category]
    end

    if isfunction then -- flat lookup by bare name
        functions[name] = value
    end

    return value
end

init.getfunctions = function(): { [string]: any }
    return functions
end

init.getfunction = function(name: string, tbl: string?): (...any) -> ...any?
    local path = if tbl then `{tbl}/{name}` else name
    local container = if tbl then functions[tbl] or env[tbl] else nil
    local value = if type(container) == "table" then container[name] else nil

    -- not loaded yet? pull it in now so load order dosent matter
    if value == nil and pending[path] then
        value = register(path, Knit.require(`{shared.script}/Functions`, path))
    end

    -- executor natives (getnilinstances, firesignal, gettenv, ...) live in getgenv()
    return value or functions[name] or env[name]
end

init.init = function()
    for path in pairs(Knit.git.clone(`{shared.script}/Functions`) or {}) do
        pending[path] = true
    end

    -- snapshot, register() clears pending as it goes
    local paths = table.clone(pending)

    for path in pairs(paths) do
        print(`Loading function: {path}`)

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