local cloneref = cloneref and cloneref or function(X)
	return X
end
local Http = cloneref(game:GetService("HttpService"))
local Parent = gethui and gethui() or cloneref(game:GetService("CoreGui"))

local ScreenGui = Instance.new("ScreenGui", Parent)
ScreenGui.ResetOnSpawn = false

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0.15,0,0.12,0)
Frame.Position = UDim2.new(0.1,0,0.3,0)
Frame.BackgroundColor3 = Color3.fromRGB(50,50,50)
Frame.Active = true
Frame.Draggable = true
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0,12)

local function Close()
	ScreenGui:Destroy()
end

local CloseButton = Instance.new("TextButton", Frame)
CloseButton.Size = UDim2.new(0,24,0,24)
CloseButton.Position = UDim2.new(1,-28,0,2)
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255,80,80)
CloseButton.BackgroundTransparency = 1
CloseButton.MouseButton1Click:Connect(function()
	Close()
end)

local EnterButton = Instance.new("TextButton", Frame)
EnterButton.Size = UDim2.new(0.4,0,0.35,0)
EnterButton.Position = UDim2.new(0.05,0,0.3,0)
EnterButton.Text = "Enter Key"
EnterButton.BackgroundColor3 = Color3.fromRGB(70,70,70)
EnterButton.TextColor3 = Color3.fromRGB(255,255,255)
Instance.new("UICorner", EnterButton)

local GetButton = Instance.new("TextButton", Frame)
GetButton.Size = UDim2.new(0.4,0,0.35,0)
GetButton.Position = UDim2.new(0.55,0,0.3,0)
GetButton.Text = "Get Key"
GetButton.BackgroundColor3 = Color3.fromRGB(70,70,70)
GetButton.TextColor3 = Color3.fromRGB(255,255,255)
Instance.new("UICorner", GetButton)

local BackButton = Instance.new("TextButton", Frame)
BackButton.Size = UDim2.new(0.1,0,0.15,0)
BackButton.Position = UDim2.new(0,0,0,0)
BackButton.Text = "Back"
BackButton.BackgroundColor3 = Color3.fromRGB(60,60,60)
BackButton.TextColor3 = Color3.fromRGB(255,255,255)
BackButton.Visible = false
Instance.new("UICorner", BackButton)

local TextBox = Instance.new("TextBox", Frame)
TextBox.Size = UDim2.new(0.9,0,0.3,0)
TextBox.Position = UDim2.new(0.05,0,0.35,0)
TextBox.PlaceholderText = "Key here"
TextBox.TextColor3 = Color3.fromRGB(255,255,255)
TextBox.Visible = false
Instance.new("UICorner", TextBox)

local Msg = Instance.new("TextLabel", Frame)
Msg.Size = UDim2.new(0.9,0,0.15,0)
Msg.Position = UDim2.new(0.05,0,0.7,0)
Msg.BackgroundTransparency = 1
Msg.TextColor3 = Color3.fromRGB(255,50,50)
Msg.Visible = false

local function Notify(Txt, Ok)
	Msg.Text = Txt
	Msg.TextColor3 = Ok and Color3.fromRGB(50,255,50) or Color3.fromRGB(255,50,50)
	Msg.Visible = true
end

EnterButton.MouseButton1Click:Connect(function()
	EnterButton.Visible = false
	GetButton.Visible = false
	TextBox.Visible = true
	BackButton.Visible = true
	Msg.Visible = false
end)

BackButton.MouseButton1Click:Connect(function()
	TextBox.Visible = false
	BackButton.Visible = false
	EnterButton.Visible = true
	GetButton.Visible = true
	Msg.Visible = false
end)

GetButton.MouseButton1Click:Connect(function()
	if type(getgenv().url) == "string" then
		setclipboard(getgenv().url)
		Notify("Copied.", true)
	end
end)

local Busy = false
TextBox.FocusLost:Connect(function(Enter)
	if not Enter or Busy then return end
	Busy = true

	local Key = TextBox.Text
	if #Key < 4 then
		Notify("Enter a key.", false)
		Busy = false
		return
	end

	Notify("Verifying...", true)

	local Api = "https://voltex.website/api/v1/key-system/generate-key?key=" .. Http:URLEncode(Key)

	local KeySuccess, KeyResult = pcall(function()
		return request({
			Url = Api,
			Method = "GET"
		})
	end)

	if not KeySuccess or not KeyResult then
		Notify("Request failed.", false)
		Busy = false
		return
	end

	local Data
	local ParseOk = pcall(function()
		Data = Http:JSONDecode(KeyResult.Body)
	end)

	if not ParseOk or type(Data) ~= "table" or type(Data.data) ~= "table" then
		Notify("Bad response.", false)
		Busy = false
		return
	end

	local Result = Data.data
	if Result.status ~= "valid" then
		Notify(Result.message or "Invalid key.", false)
		Busy = false
		return
	end

	local SourceUrl = getgenv().source
	if not SourceUrl or #SourceUrl == 0 then
		Notify("No payload.", false)
		Busy = false
		return
	end

	Notify("Key valid, loading...", true)
	getgenv().v = true; loadstring(SourceUrl)()

	Close()
end)