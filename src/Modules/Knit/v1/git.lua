local git = {}

local HttpService = if cloneref then cloneref(game:GetService("HttpService")) else game:GetService("HttpService")

-- the workspace root maps to the repo root, so everything on github lives under src/
local OWNER, REPO, BRANCH = "matpatz", "Roblox", "main"
local ROOT = "src"
local MIRROR = "voltex" -- same folder Knit.require writes to

local function httpget(url: string): string?
    if request then
        local ok, res = pcall(request, {
            Url = url,
            Method = "GET",
            Headers = {
                ["User-Agent"] = `${OWNER}-{REPO}`,
                ["Accept"] = "application/vnd.github+json"
            }
        })

        if not ok or type(res) ~= "table" then
            return nil
        end

        local body = res.Body or res.body
        local status = res.StatusCode or res.status_code or 200
        if res.Success == false or status >= 400 or type(body) ~= "string" then
            return nil
        end

        return body
    end

    local ok, body = pcall(game.HttpGet, game, url)
    return if ok then body else nil
end

-- contents api, a lone file comes back as an object instead of an array
local function listcontents(path: string): { [number]: any }?
    local body = httpget(`https://api.github.com/repos/{OWNER}/{REPO}/contents/{path}?ref={BRANCH}`)
    if not body then
        return nil
    end

    local ok, decoded = pcall(HttpService.JSONDecode, HttpService, body)
    if not ok or type(decoded) ~= "table" then
        return nil
    end

    return if decoded.type == "file" then { decoded } else decoded
end

local function ensurefolder(dir: string)
    if isfolder and makefolder and not isfolder(dir) then
        makefolder(dir)
    end
end

-- @param1 shared.script ("scripts/MoreUnc-v4")
-- @param2 module name ("Functions"), optional
function git.clonelocal(script: string, module: string)
    return listfiles("src/" .. script .. "/" .. module)
end

-- walks the github tree, writes every .lua to voltex/ and returns { module = loaded }
function git.clone(script: string, module: string?)
    local path = if module then `{script}/{module}` else script
    local entries = listcontents(`{ROOT}/{path}`)
    if not entries then
        return nil
    end

    local dest = `{MIRROR}/{path}`
    local cloned: { [string]: any } = {}

    local function cloneentry(entry: any, dir: string, name: string?)
        if entry.type == "dir" then
            ensurefolder(dir)
            for _, child in next, listcontents(entry.path) or {} do
                cloneentry(child, `{dir}/{child.name}`, if name then `{name}/{child.name}` else child.name)
            end
            return
        end

        if entry.type ~= "file" or entry.name:sub(-4) ~= ".lua" then
            return
        end

        local content = httpget(entry.download_url)
        if not content then
            return
        end

        local rel = if name then `{name}/{entry.name}` else entry.name

        if writefile then
            ensurefolder(dir)
            writefile(`{dir}/{entry.name}`, content) -- voltex/{script}/{module}.lua, same as Knit.require
        end

        local chunk = loadstring(content)
        local ok, result = false, nil
        if chunk then
            ok, result = pcall(chunk)
        end

        cloned[rel] = if ok then result else true
    end

    for _, entry in next, entries do
        cloneentry(entry, dest, nil)
    end

    return cloned
end

return git

-- git.clone("scripts/MoreUnc-v4", "Functions")
-- git.clone("scripts/MoreUnc-v4/Functions") -- same thing