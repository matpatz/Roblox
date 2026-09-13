-- Im aware this could be detected, but I doubt you would do something like that.

local OurBase = `https://roblox-alpha-murex.vercel.app/src/Modules/sneaky_slop`;
local OurUrl = `{OurBase}/SilentAim.lua`;

-- only their UI has this marker; their request.luau also mentions their own domain
local UIMarker = "HOLD TO DRAG";

local Cached;

local Old; Old = hookfunction(loadstring, newcclosure(function(...)
	local Args = {...};
	local Source = Args[1];

	if type(Source) == "string" and Source:find(UIMarker, 1, true) then
		Cached = Cached or game:HttpGet(OurUrl);
		Args[1] = Cached;
	end;

	return Old(table.unpack(Args));
end));