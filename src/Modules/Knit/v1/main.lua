local Knit = {
    services = {},
    cache = {},
    wrappers = {}
}
local script: string = "Modules/Knit/v1"

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

    -- local copy first, only hit the website for what we dont already have
    if not isscript(script, module) then
        local script_content = game:HttpGet(`https://voltex.website/src/{script}/{module}.lua`)

        -- a 404 still returns a body, dont cache something that wont compile
        local chunk = loadstring(script_content)
        if not chunk then
            return nil
        end

        if not writescript(script, module, script_content) then
            local value = chunk()
            loaded[name] = { value = value }

            return value
        end
    end

    local value = loadscript(script, module, configurable)
    loaded[name] = { value = value }

    return value
end

Knit.getdir = function(script: string): string
    return `voltex/{script}`
end

Knit.cache = Knit.require(script, "cache")

Knit.services = Knit.require(script, "services")
Knit.player = Knit.require(script, "player")

Knit.git = Knit.require(script, "git")


-- so this COULD be detected, but is fairly unlikely so whatever -- or well im not actually sure

Knit.cache.make_cache(shared, 20)
task.delay(20, function()
    Knit.cache.reset_cache(shared)
end)

shared.Knit = Knit

Knit.wrappers = Knit.require(script, "function_wrappers")

return Knit