local Knit = shared.Knit
local AES = Knit.require(`{shared.script}/Modules/crypt`, "AES")
local csprng = Knit.require(`{shared.script}/Modules/crypt`, "csprng")

local EncodingService = Knit.services.EncodingService

local function encode(data: string): string
    return buffer.tostring(EncodingService:Base64Encode(buffer.fromstring(data)))
end

local function decode(data: string): string
    return buffer.tostring(EncodingService:Base64Decode(buffer.fromstring(data)))
end

return function(data: string, key: string, iv: string?, mode: string?): (string, string)
    local keyBuffer = buffer.fromstring(decode(key))
    local ivBuffer = if iv then buffer.fromstring(decode(iv)) else csprng.RandomBytes(12)

    local encrypted, tag = AES.Encrypt(buffer.fromstring(data), keyBuffer, ivBuffer)

    return encode(buffer.tostring(encrypted) .. buffer.tostring(tag)), encode(buffer.tostring(ivBuffer))
end