local Knit = {}

local defualts = {
    domain = "https://www.voltex.website"
    fetch_timeout = 5
}

local defualt_paths = {
    ["web"] = {
        modules = "Modules",
        knit_modules = "Modules/Knit/v1/Modules",
    },
    ["local"] = {
        directory = "voltex",
        configs = "v",
    }
}

local function checklocal(path: string, filename: string)
    local filecontent = readfile(`{path}/{filename}`)
    if filecontent then
        return filecontent
    end

    return error("required file content is missing, Knit.")
end

Knit.require = function(path: string, filename: string, localize: boolean)
    local extension = ".lua"
    filename = `{filename}{extension}`

    local start = 0

    local filecontent = game:HttpGet(`{defualts.domain}/src/{path}/{filename}`)
    repeat
        start += 1

        task.wait(1)
    until filecontent or (start == defualts.fetch_timeout)

    if not filecontent then
        return checklocal(path, filename)
    end

    if localize then
        makefolder(path)
        writefile(`{path}/{filename}`, filecontent)
    end

    return loadstring(filecontent)()
end

--@param1 Options: player, conmanager, whatnot
Knit.new = function(desiredmodules)
    local bundle = {}
    for i, v in next, desiredmodules do
        local bundlekey = Knit.require(
            defualt_paths["web"].knit_modules,
            v
        )
		repeat task.wait() until bundlekey

        bundle[bundlekey] = bundlekey
    end

    return bundle
end

-- For legacy modules, like git
Knit.v1 = function()
    local request = Knit.require("Modules/Knit/v1", "main")
    return request
end

--[[
local Modules = Knit.new({
    "ui",
    "services"
})
]]  asdd