local Knit = shared.Knit
local csprng = Knit.require(`{shared.script}/Modules/crypt`, "csprng")

return function(length)
    return csprng.generateBytes(length)
end