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
    ["Drawing"] = true,
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

-- luau locks a good chunk of the executor stdlib (debug especially) with
-- table.isfrozen, and rawset into one of those errors outright
local function isreadonly(t: any): boolean
    local ok, frozen = pcall(table.isfrozen, t)

    if ok then
        return frozen == true
    end

    if type(env.isreadonly) == "function" then
        local read, res = pcall(env.isreadonly, t)

        if read then
            return res == true
        end
    end

    return false
end

-- executor tables are usually proxies: the real functions hang off __index, so
-- pairs() enumerates nothing and rawget() answers nil. a "copy then swap" reads
-- those as empty and that is exactly how debug.info disappears, so every
-- existence check goes through normal indexing, never rawget
local function has(t: any, key: any): boolean
    local ok, value = pcall(function()
        return t[key]
    end)

    return ok and value ~= nil
end

-- not every executor ships an unfreeze primitive, and the ones that do sometimes
-- hand back a proxy instead of thawing in place
local function unfreeze(t: any): any
    for _, name in ipairs({ "makewriteable", "make_writeable", "setreadonly" }) do
        local thaw = env[name]

        if type(thaw) == "function" then
            local ok, result = pcall(thaw, t, false)

            if ok and type(result) == "table" then
                return result
            end
        end
    end

    return nil -- everything refused, caller falls back to a wrapper
end

local function write(t, entries): boolean
    return pcall(function()
        for key, value in pairs(entries) do
            rawset(t, key, value)
        end
    end)
end

-- exported categories ride ON the executor table when one already exists, so
-- debug.info, drawing.new, ... stay put. nothing is written unless the key is
-- actually missing, and the executor table is never dropped
local function merge(existing, ours)
    local missing = {}

    for key, value in pairs(ours) do
        if not has(existing, key) then
            missing[key] = value
        end
    end

    if next(missing) == nil then
        return existing -- executor already ships all of it, leave it alone
    end

    if not isreadonly(existing) and write(existing, missing) then
        return existing -- writable: add in place, identity and metatables intact
    end

    local thawed = unfreeze(existing)

    if thawed == existing and write(existing, missing) then
        return existing -- thawed in place, still no swap
    end

    if type(thawed) == "table" and write(thawed, missing) then
        return thawed -- executor handed back a guard proxy, use it
    end

    -- last resort: a wrapper. enumerable keys are copied over and __index keeps
    -- the original reachable, so a table we couldnt fully enumerate still
    -- answers every lookup the executor used to answer
    local wrapper = {}

    for key, value in pairs(existing) do
        wrapper[key] = value
    end

    for key, value in pairs(missing) do
        wrapper[key] = value
    end

    return setmetatable(wrapper, { __index = existing })
end

local function container(category: string)
    local ours = functions[category]

    if not exported[category] then
        return ours or {}
    end

    local existing = env[category]

    if existing == nil then -- nothing to protect, mirror the namespace
        local fresh = ours or {}
        pcall(function()
            env[category] = fresh
        end)

        return fresh
    end

    if type(existing) ~= "table" then -- some other kind of object, leave it be
        return ours or {}
    end

    local target = merge(existing, ours or {})

    if target ~= existing then
        local assigned = pcall(function()
            env[category] = target
        end)

        if not assigned then
            return ours or {} -- env itself is locked, dont lose the executor table
        end
    end

    return target
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

    local key = name or path
    local tbl = container(category)
    functions[category] = tbl

    if tbl[key] ~= nil then -- executor already has it, theirs wins
        value = tbl[key]
    else
        tbl[key] = value
    end

    if isfunction then -- flat lookup by bare name
        functions[key] = value

        if env[key] == nil then -- never clobber an executor native
            env[key] = value
        end
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
    local cloned = Knit.git.clone(`{shared.script}/Functions`) or {}

    for path in pairs(cloned) do
        pending[path] = true
    end

    -- snapshot, register() clears pending as it goes
    local paths = table.clone(pending)
    local total, loaded = 0, 0

    for path in pairs(paths) do
        total += 1
        print(`Loading function: {path}`)

        -- one half finished file shouldnt take the whole loader down with it
        local ok, value = pcall(Knit.require, `{shared.script}/Functions`, path)

        if ok and value then
            local registered, err = pcall(register, path, value)

            if registered then
                loaded += 1
            else
                pending[path] = nil
                warn(`failed to register {path}: {err}`)
            end
        else
            pending[path] = nil
            warn(`failed to load {path}: {if ok then "module returned nil" else value}`)
        end
    end

    print(`loaded {loaded}/{total} functions`)

    return functions
end

return init