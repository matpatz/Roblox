local HttpService = game:GetService("HttpService")
local AssetService = game:GetService("AssetService")

local API_URL = "https://website-iota-ivory-12.vercel.app/api/ascii"
local COLUMNS = 80

-- GUI Setup
local gui = Instance.new("ScreenGui")
gui.Name = "e" .. math.random(1e9, 2e9)
gui.ResetOnSpawn = false
gui.Parent = gethui() or game.CoreGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 520, 0, 320)
frame.Position = UDim2.new(0.3, 0, 0.2, 0)
frame.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
frame.Active = true
frame.Draggable = true
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.Text = "Image to ASCII"
title.Size = UDim2.new(1, -40, 0, 30)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

local close = Instance.new("TextButton")
close.Text = "X"
close.Size = UDim2.new(0, 30, 0, 30)
close.Position = UDim2.new(1, -30, 0, 0)
close.BackgroundTransparency = 1
close.TextColor3 = Color3.fromRGB(255, 60, 60)
close.Parent = frame
close.MouseButton1Click:Connect(function()
	gui:Destroy()
end)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(0.94, 0, 0.70, 0)
scroll.Position = UDim2.new(0.03, 0, 0.12, 0)
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.XY
scroll.ScrollBarThickness = 6
scroll.ScrollingDirection = Enum.ScrollingDirection.XY
scroll.BorderSizePixel = 0
scroll.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
scroll.Parent = frame
Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, 6)

local output = Instance.new("TextLabel")
output.RichText = true
output.Size = UDim2.new(0, 0, 0, 0)
output.AutomaticSize = Enum.AutomaticSize.XY
output.Position = UDim2.new(0, 5, 0, 5)
output.TextWrapped = false
output.TextYAlignment = Enum.TextYAlignment.Top
output.TextXAlignment = Enum.TextXAlignment.Left
output.Font = Enum.Font.Code
output.TextSize = 14
output.TextColor3 = Color3.new(1, 1, 1)
output.BackgroundTransparency = 1
output.Text = "-- ASCII output will appear here"
output.Parent = scroll

local input = Instance.new("TextBox")
input.Size = UDim2.new(0.7, 0, 0, 30)
input.Position = UDim2.new(0.03, 0, 0.85, 0)
input.MultiLine = false
input.ClearTextOnFocus = true
input.TextYAlignment = Enum.TextYAlignment.Center
input.TextXAlignment = Enum.TextXAlignment.Left
input.Font = Enum.Font.Code
input.TextSize = 13
input.TextColor3 = Color3.new(1, 1, 1)
input.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
input.Text = "Image in workspace"
input.Parent = frame

local sendBtn = Instance.new("TextButton")
sendBtn.Size = UDim2.new(0, 120, 0, 30)
sendBtn.Position = UDim2.new(0.75, 0, 0.85, 0)
sendBtn.Text = "Send"
sendBtn.Font = Enum.Font.GothamBold
sendBtn.TextSize = 12
sendBtn.TextColor3 = Color3.new(1, 1, 1)
sendBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
sendBtn.Parent = frame
Instance.new("UICorner", sendBtn).CornerRadius = UDim.new(0, 5)

-- PNG Encoding
local function Byte4(n)
	return string.char(
		math.floor(n / 16777216) % 256,
		math.floor(n / 65536) % 256,
		math.floor(n / 256) % 256,
		n % 256
	)
end

local function Adler32(data)
	local s1, s2 = 1, 0
	for i = 1, #data do
		s1 = (s1 + string.byte(data, i)) % 65521
		s2 = (s2 + s1) % 65521
	end
	return s2 * 65536 + s1
end

local CRC_TABLE = {}
for i = 0, 255 do
	local c = i
	for _ = 1, 8 do
		if bit32.band(c, 1) == 1 then
			c = bit32.bxor(bit32.rshift(c, 1), 0xEDB88320)
		else
			c = bit32.rshift(c, 1)
		end
	end
	CRC_TABLE[i] = c
end

local function Crc32(data)
	local crc = 0xFFFFFFFF
	for i = 1, #data do
		local idx = bit32.band(bit32.bxor(crc, string.byte(data, i)), 0xFF)
		crc = bit32.bxor(bit32.rshift(crc, 8), CRC_TABLE[idx])
	end
	return bit32.bxor(crc, 0xFFFFFFFF)
end

local function Chunk(tag, data)
	return Byte4(#data) .. tag .. data .. Byte4(Crc32(tag .. data))
end

local function DeflateStore(data)
	local out = {}
	local i = 1
	while i <= #data do
		local block = string.sub(data, i, i + 65534)
		local blen = #block
		local last = (i + 65534 >= #data) and 1 or 0
		out[#out + 1] = string.char(last)
		out[#out + 1] = string.char(blen % 256, math.floor(blen / 256))
		out[#out + 1] = string.char(
			bit32.band(bit32.bnot(blen), 0xFF),
			bit32.band(bit32.bnot(math.floor(blen / 256)), 0xFF)
		)
		out[#out + 1] = block
		i = i + 65535
	end
	return table.concat(out)
end

local function BuildPNG(buf, w, h)
	local scanlines = {}
	for row = 0, h - 1 do
		local line = { "\0" }
		for col = 0, w - 1 do
			local base = (row * w + col) * 4
			line[#line + 1] = string.char(
				buffer.readu8(buf, base),
				buffer.readu8(buf, base + 1),
				buffer.readu8(buf, base + 2),
				buffer.readu8(buf, base + 3)
			)
		end
		scanlines[#scanlines + 1] = table.concat(line)
	end
	local raw = table.concat(scanlines)
	local compressed = "\120\1" .. DeflateStore(raw) .. Byte4(Adler32(raw))
	local ihdr = Byte4(w) .. Byte4(h) .. "\8\6\0\0\0"
	return "\137PNG\r\n\26\n"
		.. Chunk("IHDR", ihdr)
		.. Chunk("IDAT", compressed)
		.. Chunk("IEND", "")
end

-- Core Logic
local function GetImageBase64()
	local uri = getcustomasset(input.Text)
	local editableImage = AssetService:CreateEditableImageAsync(Content.fromUri(uri))
	local size = editableImage.Size
	local buf = editableImage:ReadPixelsBuffer(Vector2.zero, size)
	return crypt.base64encode(BuildPNG(buf, size.X, size.Y))
end

local function FetchAscii()
	local b64 = GetImageBase64()
	local response = request({
		Url = API_URL,
		Method = "POST",
		Headers = { ["Content-Type"] = "application/json" },
		Body = HttpService:JSONEncode({ image = b64, columns = COLUMNS }),
	})
	local decoded = HttpService:JSONDecode(response.Body)
	return decoded and decoded.ascii or nil
end

sendBtn.MouseButton1Click:Connect(function()
	output.Text = "Loading..."
	output.Text = FetchAscii() or "Failed to load."
end)
