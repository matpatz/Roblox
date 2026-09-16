local Knit = shared.Knit
local AES = Knit.require(`{shared.script}/Modules/crypt`, "AES")

return function(data: string, key: string, iv: string?, mode: string?): (string, string)
    local decrypted, used_iv = AES.decrypt(data, key, iv, mode) -- TODO: should input buffers, not strings
    return decrypted, used_iv
end