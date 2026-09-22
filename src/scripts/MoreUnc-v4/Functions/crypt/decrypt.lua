local Knit = shared.Knit
local AES = Knit.require(`{shared.script}/Modules/crypt`, "AES")

local EncodingService = Knit.services.EncodingService

local function decode(data: string): string
    return buffer.tostring(EncodingService:Base64Decode(buffer.fromstring(data)))
end

return function(data: string, key: string, iv: string, mode: string?): string
    local payload = decode(data)

    if #payload < 16 then -- no room for the tag, this never came from encrypt
        return ""
    end

    local ciphertext = payload:sub(1, -17)
    local tag = payload:sub(-16)

    local decrypted, plaintext = AES.Decrypt(
        buffer.fromstring(ciphertext),
        buffer.fromstring(decode(key)),
        buffer.fromstring(decode(iv)),
        buffer.fromstring(tag)
    )

    if not decrypted then
        return ""
    end

    return buffer.tostring(plaintext)
end