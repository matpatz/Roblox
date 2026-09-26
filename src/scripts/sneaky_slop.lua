-- shared.Knit.require("scripts", "sneaky_slop")
-- Im aware this could be detected, but I doubt you would do something like that.

local OurBase = `https://raw.githubusercontent.com/matpatz/Roblox/refs/heads/main/src/Modules/sneaky_slop`
local SilentAim = `{OurBase}/SilentAim.lua`

local OurSource = game:HttpGet(SilentAim);

local sneeky_fov_toggle = "sneeky_fov_toggle"
local unrestricted_main = "NOTIFICATION_LIBRARY/unrestricted_main.luau"

if isfunctionhooked(loadstring) then
    restorefunction(loadstring)
end

local Old; Old = hookfunction(loadstring, newcclosure(function(...)
	local Args = {...};
	local Source = Args[1];

	if type(Source) == "string" and Source:find(sneeky_fov_toggle, 1, true) and Source:find(unrestricted_main, 1, true) then
		Args[1] = OurSource;
	end

	return Old(table.unpack(Args));
end));