local Knit = shared.Knit
local SHA2 = Knit.require(`{shared.script}/Modules/crypt`, "SHA2")

repeat task.wait() until SHA2

return function(data, algorithm)
    local hash = SHA2[algorithm]
	return hash(data)
end

--[[
    print(a("uwu", "sha224"))
--]]