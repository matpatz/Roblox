local Knit = shared.Knit
local csprng = Knit.require(`{shared.script}/Modules/crypt`, "csprng")

local EncodingService = Knit.services.EncodingService

return function(length: number): string
    return buffer.tostring(EncodingService:Base64Encode(csprng.RandomBytes(length)))
end