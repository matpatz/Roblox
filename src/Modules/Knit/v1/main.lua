local Knit = {
    services = {},
    cache = {}
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
    getgenv()["configurable"] = configurable

    if isscript(script, module) then
        local compiled = dofile(`voltex/{script}/{module}.lua`)
        getgenv()["configurable"] = nil

        return compiled
    end
    return nil
end

local modules = {
    "main",
    "core",
    "utils"
}

Knit.require = function(script: string, module: string, configurable: table?)
    local script_content = game:HttpGet(`https://voltex.website/src/{script}/{module}.lua`)
    if not writescript(script, module, script_content) then
        return loadstring(script_content)()
    end
    
    repeat
        task.wait()
    until
        isscript(script, module)
    
    return loadscript(script, module, configurable)
end

Knit.services = Knit.require(script, "services", {
    PlayerHelper = false
})
Knit.cache = Knit.require(script, "cache")

Knit.wrappers = Knit.require(script, "function_wrappers", Knit.cache)

return Knit