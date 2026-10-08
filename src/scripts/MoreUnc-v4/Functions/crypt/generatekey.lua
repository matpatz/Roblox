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
    local characters = table.create(KEY_LENGTH)

    for index = 1, KEY_LENGTH do
        characters[index] = random_character()
    end

    return buffer.tostring(EncodingService:Base64Encode(buffer.fromstring(table.concat(characters))))
end