local Knit = shared.Knit
local EncodingService = Knit.services.EncodingService

return function(data: string): string
    return buffer.tostring(EncodingService:Base64Encode(buffer.fromstring(data)))
end