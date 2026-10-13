local Knit = shared.Knit
local instances = Knit.instances
local betterfunctions = Knit.betterfunctions

local getinfo = debug.getinfo
local setinfo = debug.setinfo

local hookfunction = betterfunctions.hookfunction

local blacklist = {
    ["discord.com/api/webhooks"] = true,
    ["discordapp.com/api/webhooks"] = true,
}

local a = false

local function _warn(webhook: string)
	if a then
		return
	end
	a = true

	local ScreenGui = instances.new("ScreenGui", true)

	local Frame = instances.new("Frame", true)
	Frame.Parent = ScreenGui
	Frame.Size = UDim2.fromOffset(300, 120)
	Frame.AnchorPoint = Vector2.new(0.5, 0.5)
	Frame.Position = UDim2.fromScale(0.5, 0.5)
	Frame.BackgroundColor3 = Color3.fromRGB(150, 140, 145) -- eyelid gray

	local TextLabel = instances.new("TextLabel", true)
	TextLabel.Parent = Frame
	TextLabel.Size = UDim2.new(1, 0, 0.5, 0)
	TextLabel.BackgroundTransparency = 1
	TextLabel.TextSize = 14
	TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	TextLabel.Text = `Incoming Webhook, {webhook}`

	local Accept = instances.new("TextButton", true)
	Accept.Parent = Frame
	Accept.Size = UDim2.new(0.4, 0, 0.3, 0)
	Accept.Position = UDim2.new(0.07, 0, 0.6, 0)
	Accept.BackgroundColor3 = Color3.fromRGB(60, 200, 80)
	Accept.TextColor3 = Color3.fromRGB(255, 255, 255)
	Accept.TextScaled = true
	Accept.Text = "Accept"

	local Decline = instances.new("TextButton", true)
	Decline.Parent = Frame
	Decline.Size = UDim2.new(0.4, 0, 0.3, 0)
	Decline.Position = UDim2.new(0.53, 0, 0.6, 0)
	Decline.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
	Decline.TextColor3 = Color3.fromRGB(255, 255, 255)
	Decline.TextScaled = true
	Decline.Text = "Decline"

	Accept.Activated:Connect(function()
		ScreenGui:Destroy()

		return true
	end)

	Decline.Activated:Connect(function()
		ScreenGui:Destroy()

		return false
	end)

	a = false
end

local request_info = getinfo(request)
local Old; Old = hookfunction(request, function(options)
	local url = options.Url

	options.Url = "https://example.com" -- incase it is a webhook dont let it fire
	local original = Old(options) -- input validation
	options.Url = url

	for blacklisted in next, blacklist do
		if not url:find(blacklisted) then
			continue
		end
		
		repeat 
			task.wait()
		until _warn(url) ~= nil

		return {
			StatusMessage = "Could not resolve hostname", -- igbro
			StatusCode = 0,
			Success = false,
			Headers = original.Headers,
			Body = ""
		}
	end
	return Old(options)
end)

local isfunctionhooked_info = getinfo(isfunctionhooked)
local Old2; Old2 = hookfunction(isfunctionhooked, function(func)
	if func == request then
		return true
	end
	return Old2(func)
end)

if setinfo then
    setinfo(isfunctionhooked, isfunctionhooked_info)
    setinfo(request, request_info)
end