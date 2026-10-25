local Knit = shared.Knit
local betterfunctions = Knit.betterfunctions

local hookfunction = betterfunctions.hookfunction

local keys = {
    ["Potassium"] = "sha512",
    ["Synapse Z"] = "sha512", -- I think this is untrue but idk where any synz docs are
    ["Volt"] = "sha256"
}

local executor, _version = identifyexecutor()
local hashtype = keys[executor]

if not hashtype then
    return
end

local required = {
    gethwid,
    crypt.hash,
    hookfunction
}

for i, v in required do -- whatever bro
    if type(v) ~= "function" then
        error("uwu")
    end
end

local RNG = Random.new()
local charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"

local function RandomString(length)
    local result = {}
    for i = 1, length do
        local randIndex = RNG:NextInteger(1, #charset)
        result[i] = charset:sub(randIndex, randIndex)
    end
    return table.concat(result)
end

local randomstring = RandomString(16)
local hash = crypt.hash(randomstring, hashtype)

local Old; Old = hookfunction(gethwid, function()
    return hash
end)