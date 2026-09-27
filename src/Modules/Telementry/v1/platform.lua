local cloneref = cloneref and cloneref or function(x)
	return x
end

local UserInputService = cloneref(game:GetService("UserInputService"))

local function identifyplatform()
	local Platform = tostring(UserInputService:GetPlatform()):split(".")[3]

	if Platform == "Windows" or Platform == "OSX" or Platform == "UWP" then
		return "PC"
	elseif Platform == "Android" or Platform == "IOS" then
		return "Mobile"
	else
		return "Other"
	end
end
local platform = identifyplatform()

return platform