local git = {}

local HttpService = if cloneref then cloneref(game:GetService("HttpService")) else game:GetService("HttpService")

-- the workspace root maps to the repo root, so everything on github lives under src/
local OWNER, REPO, BRANCH = "matpatz", "Roblox", "main"
local ROOT = "src"
local MIRROR = "voltex" -- same folder Knit.require writes to

local function httpget(url: string): string?
    return game:HttpGet(url) -- depends on the executor but can be more performant than request
end

local function ensurefolder(dir: string)
    if isfolder and makefolder and not isfolder(dir) then
        makefolder(dir)
    end
end

local function parent(path: string): string?
    return path:match("^(.*)/[^/]*$")
end

-- @param1 shared.script ("scripts/MoreUnc-v4")
-- @param2 module name ("Functions"), optional
function git.clonelocal(script: string, module: string)
    return listfiles("src/" .. script .. "/" .. module)
end

-- recreates the folders under voltex/{script}/{module}/, writes every .lua there and
-- returns { ["crypt/encrypt"] = true, ... } -- so the caller can Knit.require each key
function git.clone(script: string, module: string?)
    local path = if module then `{script}/{module}` else script
    local prefix = `{ROOT}/{path}/`

    -- one request for the whole repo instead of one per folder,
    -- github only gives us 60 api calls an hour unauthenticated
    local body = httpget(`https://api.github.com/repos/{OWNER}/{REPO}/git/trees/{BRANCH}?recursive=1`)
    if not body then
        return nil
    end

    local ok, decoded = pcall(HttpService.JSONDecode, HttpService, body)
    if not ok then
        return nil
    end

    local dest = `{MIRROR}/{path}`
    local cloned: { [string]: boolean } = {}

    ensurefolder(dest)

    for _, entry in next, decoded.tree do
        if entry.path:sub(1, #prefix) ~= prefix then
            continue
        end

        local name = entry.path:sub(#prefix + 1)

        if entry.type == "tree" then
            -- git returns a folder before its contents, so this builds top down
            ensurefolder(`{dest}/{name}`)
            continue
        end

        if entry.type ~= "blob" or name:sub(-4) ~= ".lua" then
            continue
        end

        local content = httpget(`https://raw.githubusercontent.com/{OWNER}/{REPO}/{BRANCH}/{entry.path}`)
        if not content then
            continue
        end

        local key = name:sub(1, -5) -- strip the .lua
        local file = `{dest}/{key}.lua`

        if writefile then
            ensurefolder(parent(file) or dest)
            writefile(file, content) -- voltex/{script}/{module}.lua, same as Knit.require
        end

        cloned[key] = true
    end

    return cloned
end

return git

-- git.clone("scripts/MoreUnc-v4", "Functions")
-- git.clone("scripts/MoreUnc-v4/Functions") -- same thing