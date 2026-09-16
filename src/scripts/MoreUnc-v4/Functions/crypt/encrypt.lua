local Knit = shared.Knit
local AES = Knit.require(`{shared.script}/Modules/crypt`, "AES")

return function(data: string, key: string, iv: string?, mode: string?): (string, string)
    local encrypted, used_iv = AES.encrypt(data, key, iv, mode) -- TODO: should input buffers, not strings
    return encrypted, used_iv
end