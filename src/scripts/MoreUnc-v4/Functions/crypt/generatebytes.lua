local Knit = shared.Knit
local csprng = Knit.require(`{shared.script}/Modules/crypt`, "csprng")

return function(length: number): string
    return buffer.tostring(csprng.RandomBytes(length)) -- raw bytes, not base64
end