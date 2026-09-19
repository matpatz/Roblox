local Knit = {
    services = {},
    cache = {},
    wrappers = {},
    git = {},
    player = {},
    ui = {},
    instances = {},
    bundle = {}
}
shared.Knit = Knit

local script: string = "Modules/Knit/Modules"

if not isfolder("voltex") then
    makefolder("voltex")
end

-- dont check isscript to account for updates
local function writescript(script, module, content)
    if not writefile then
        return nil
    end
    writefile(`voltex/{script}/{module}.lua`, content)

    return true
end

--[[
    local function readscript(script, module)
        return readfile(`voltex/{script}/{module}.lua`)
    end
]]

local function isscript(script, module)
    return isfile(`voltex/{script}/{module}.lua`)
end

local function loadscript(script, module, configurable)
    if configurable and Knit.cache and Knit.cache.set then
        Knit.cache.set(`{module}/configurable`, configurable) -- any temp value, like getgenv().config = {} -- well you get the point
    end

    if not isscript(script, module) then
        return nil
    end

    local chunk = loadstring(readfile(`voltex/{script}/{module}.lua`), `voltex/{script}/{module}.lua`)
    if not chunk then
        return nil
    end

    return chunk()
end

-- executors disagree on newlines when they round-trip a file, compare without \r
local function normalize(content: string): string
    return (content:gsub("\r", ""))
end

-- keeps voltex/{script}/{module}.lua in sync with the website and hands back the fresh
-- chunk. "if the file exists, never look again" meant an edit to an already cached
-- module was invisible forever (a file that loads fine and then errors still gets
-- cached), so the body is always fetched and the cached copy is only reused when it
-- actually matches what the website is serving
local function sync(script, module)
    local path = `voltex/{script}/{module}.lua`
    local ok, script_content = pcall(game.HttpGet, game, `https://voltex.website/src/{script}/{module}.lua`)

    if not ok or type(script_content) ~= "string" then
        return nil -- network died, caller falls back to the cache
    end

    -- a 404 still returns a body, dont cache something that wont compile
    local chunk = loadstring(script_content)
    if not chunk then
        return nil
    end

    local cached = if isfile(path) then readfile(path) else nil

    if cached and normalize(cached) == normalize(script_content) then
        return chunk, true -- already current, leave the file alone
    end

    -- writefile refuses to overwrite on some executors, so clear the old one first
    if cached and delfile then
        delfile(path)
    end

    writescript(script, module, script_content)

    return chunk, isfile(path)
end

local modules = {
    "main",
    "core",
    "utils"
}

local loaded: { [string]: { value: any } } = {}

Knit.require = function(script: string, module: string, configurable: table?)
    -- one instance per module, otherwise every require re-runs it (Modules/globals.lua
    -- rebuilds _G.globals on load, so a second require would wipe it)
    local name = `{script}/{module}`
    if loaded[name] then
        return loaded[name].value
    end

    local chunk, ondisk = sync(script, module)

    if chunk and ondisk then
        -- fresh body landed on disk, load it the normal way
        local value = loadscript(script, module, configurable)
        loaded[name] = { value = value }

        return value
    end

    if chunk then
        -- couldnt write to disk (missing folder, read-only, ...) so run it straight
        local value = chunk()
        loaded[name] = { value = value }

        return value
    end

    -- nothing fresh (offline, 404): a stale cache still beats loading nothing
    local value = loadscript(script, module, configurable)
    loaded[name] = { value = value }

    return value
end

Knit.getdir = function(script: string): string
    return `voltex/{script}`
end

Knit.cache = Knit.require(script, "cache")

Knit.services = Knit.require(script, "services")
-- playermanager blocks on CharacterAdded:Wait(), so it cant hold up this load. fill
-- the table weve already published instead of swapping it, or anything that grabbed
-- Knit.player before this fires (games/*/core.lua) keeps the empty stub forever
task.delay(0.2, function()
    local manager = Knit.require(script, "playermanager")

    for key, value in pairs(manager) do
        Knit.player[key] = value
    end
end)

Knit.git = Knit.require(script, "git")

Knit.wrappers = Knit.require(script, "function_wrappers")

Knit.instances = Knit.require(script, "instances")
Knit.ui = Knit.require(script, "ui")
Knit.conmanager = Knit.require(script, "conmanager")
Knit.scriptmanager = Knit.require(script, "scriptmanager")

Knit.bundle = Knit.require(script, "bundle")

return Knit

