local Knit = {}
shared.Knit = Knit

local defualts = {
    domains = {
        "https://gitlab.com/voltex-group3/voltex-project/-/raw/main",
        "https://raw.githubusercontent.com/matpatz/Roblox/refs/heads/main",
        "https://www.voltex.website",
    },
    fetch_timeout = 5
}

local defualt_paths = {
    ["web"] = {
        modules = "Modules",
        knit_modules = "Modules/Knit/v2/Modules",
    },
    ["local"] = {
        directory = "voltex",
        configs = "v",
    }
}
Knit.defualt_paths = defualt_paths

local function checklocal(path: string, filename: string)
    local ok, filecontent = pcall(function(...)
		return readfile(`{path}/{filename}`)
	end)
    if ok and filecontent then
        return filecontent
    end

    return error("required file content is missing, Knit.")
end

Knit.require = function(path: string, filename: string, localize: boolean)
    local extension = ".lua"
    filename = `{filename}{extension}`

    local attempts = 0

    local ok, filecontent
    while not filecontent do
        attempts += 1

        local currentdomain = defualts.domains[attempts]
        if not currentdomain then
            break
        end

        ok, filecontent = pcall(function(...)
            return game:HttpGet(`{currentdomain}/src/{path}/{filename}`)
        end)

        if not ok then
            filecontent = nil
        end
    end

    if not filecontent then
        filecontent = checklocal(path, filename)
    end

    if localize then
        makefolder(path)
        writefile(`{path}/{filename}`, filecontent)
    end

    local compiled = loadstring(filecontent)
    if not compiled then
        error("error compiling required script, Knit.")
    end

    return compiled()
end

--@param1 Options: player, conmanager, whatnot
--[[
    Could also be:
    Knit[v] = bundlekey -- but ya
]]
Knit.new = function(desiredmodules)
    local bundle = {}
    for i, v in desiredmodules do
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

return Knit

--[[

local Modules = Knit.new({
    "ui",
    "services"
})

]]