local uis = cloneref(game:GetService("UserInputService"))

local function device()
	local platform = tostring(uis:GetPlatform()):split(".")[3]

	if platform == "Windows" or platform == "OSX" or platform == "UWP" then
		return "PC"
	elseif platform == "Android" or platform == "IOS" then
		return "Mobile"
	else
		return "Other"
	end
end

getgenv().device = device()

--[[
	local device = getgenv().device or "Mobile"
	print(device)
--]]
