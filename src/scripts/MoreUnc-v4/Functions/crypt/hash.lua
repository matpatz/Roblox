local Knit = shared.Knit
local SHA2 = Knit.require(`{shared.script}/Modules/crypt`, "SHA2")

return function(data, algorithm)
    return SHA2.hash(data, algorithm) -- TODO: wrong usage of SHA2 Module
end