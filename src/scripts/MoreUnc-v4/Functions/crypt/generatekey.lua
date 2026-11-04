local Knit = shared.Knit
local csprng = Knit.require(`{shared.script}/Modules/crypt`, "csprng")

local EncodingService = Knit.services.EncodingService

local ALPHABET = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
local ALPHABET_SIZE = #ALPHABET
local KEY_LENGTH = 32

local function random_character(): string
    local position = csprng.RandomInt(1, ALPHABET_SIZE)

    return ALPHABET:sub(position, position)
end

return function(keylength: number?): string
    local length = keylength or KEY_LENGTH
    local characters = table.create(length)

    for index = 1, length do
        characters[index] = random_character()
    end

    return buffer.tostring(EncodingService:Base64Encode(buffer.fromstring(table.concat(characters))))
end