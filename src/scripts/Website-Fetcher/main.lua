
local Rayfield = loadstring(game:HttpGet(
	"https://roblox-alpha-murex.vercel.app/libraries/Rayfield/main.lua"
))()

local Window = Rayfield:CreateWindow({
    Name = "Website Fetcher",
    LoadingTitle = "LLEEEEbron",
    LoadingSubtitle = "subtitle",
})

local tabs = {
    main = Window:CreateTab("Main"),
    settings = Window:CreateTab("Settings"),
}

local Url
tabs.main:CreateInput({
    Name = "TextBox",
    PlaceholderText = "Enter Url...",
    RemoveTextAfterFocusLost = false,
    Callback = function(Input)
		if not Input:find("http") then
			warn("invalid url")
			return
		end
        Url = Input
    end,
})

local function Request(): string
	local Response = request({
		Url = Url,
		Method = "GET",
	})

	if not Response.Body then
		warn("failed to get Body")
	end

	return Response.Body
end

tabs.main:CreateButton({
    Name = "Print Url",
    Callback = function()
        local Result = Request()
		print(Result)
    end,
})

tabs.main:CreateButton({
    Name = "Copy Url",
    Callback = function()
        local Result = Request()
		setclipboard(Result)
    end,
})
