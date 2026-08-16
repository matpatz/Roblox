--! slop 100

--[[
	ascii/main.lua — Image → ASCII converter
	-----------------------------------------
	Reads a custom asset, downsamples it, re-encodes a tiny PNG, and asks the
	Voltex backend to turn it into rich-text ASCII. Renders the result in a
	draggable UI with one-click copy to clipboard.

	Pipeline:  custom asset → EditableImage → pixel buffer → downscale
	         → PNG (deflate "stored") → base64 → POST /api/v1/ascii
	         → rich-text ASCII → UI + clipboard
]]

-- Services & config ---------------------------------------------------------
local HttpService = game:GetService("HttpService")
local AssetService = game:GetService("AssetService")

local API_URL = "https://www.voltex.website/api/v1/ascii"
local COLUMNS = 80
local MAX_WIDTH = COLUMNS * 2 -- 2x output width is plenty of detail

-- Helpers -------------------------------------------------------------------
local function Try(fn)
	return pcall(fn)
end

--============================================================================
-- Minimal PNG encoder (uncompressed deflate — just enough for our payload)
--============================================================================

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
		c = if bit32.band(c, 1) == 1
			then bit32.bxor(bit32.rshift(c, 1), 0xEDB88320)
			else bit32.rshift(c, 1)
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

-- DEFLATE "stored" blocks (no compression). Small images = fine.
local function DeflateStore(data)
	local out = {}
	local i = 1
	while i <= #data do
		local block = string.sub(data, i, i + 65534)
		local blen = #block
		local last = if i + 65534 >= #data then 1 else 0
		out[#out + 1] = string.char(last)
		out[#out + 1] = string.char(blen % 256, math.floor(blen / 256))
		out[#out + 1] = string.char(
			bit32.band(bit32.bnot(blen), 0xFF),
			bit32.band(bit32.bnot(math.floor(blen / 256)), 0xFF)
		)
		out[#out + 1] = block
		i += 65535
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

--============================================================================
-- Image pipeline — custom asset → small base64 PNG
--============================================================================

-- Bilinear downscale keeps the payload tiny (Vercel caps ~4.5MB).
local function Downscale(buf, w, h, maxW)
	local scale = maxW / w
	if scale >= 1 then
		return buf, w, h
	end

	local nw = math.max(1, math.floor(w * scale))
	local nh = math.max(1, math.floor(h * scale))
	local out = buffer.create(nw * nh * 4)

	for y = 0, nh - 1 do
		local sy = math.max(0, math.min(h - 1, (y + 0.5) * h / nh - 0.5))
		local y0 = math.floor(sy)
		local y1 = math.min(h - 1, y0 + 1)
		local fy = sy - y0

		for x = 0, nw - 1 do
			local sx = math.max(0, math.min(w - 1, (x + 0.5) * w / nw - 0.5))
			local x0 = math.floor(sx)
			local x1 = math.min(w - 1, x0 + 1)
			local fx = sx - x0

			local b00 = (y0 * w + x0) * 4
			local b01 = (y0 * w + x1) * 4
			local b10 = (y1 * w + x0) * 4
			local b11 = (y1 * w + x1) * 4
			local ob = (y * nw + x) * 4

			-- Bilinear sample RGB
			for c = 0, 2 do
				local top = buffer.readu8(buf, b00 + c) * (1 - fx) + buffer.readu8(buf, b01 + c) * fx
				local bot = buffer.readu8(buf, b10 + c) * (1 - fx) + buffer.readu8(buf, b11 + c) * fx
				buffer.writeu8(out, ob + c, math.floor(top * (1 - fy) + bot * fy + 0.5))
			end
			-- Alpha: keep the max so transparent edges survive
			buffer.writeu8(out, ob + 3, math.max(
				buffer.readu8(buf, b00 + 3),
				buffer.readu8(buf, b01 + 3),
				buffer.readu8(buf, b10 + 3),
				buffer.readu8(buf, b11 + 3)
			))
		end
	end

	return out, nw, nh
end

-- Returns (base64, nil) or (nil, errMessage).
local function EncodeAssetToBase64(assetPath)
	local okUri, uri = Try(function()
		return getcustomasset(assetPath)
	end)
	if not okUri then
		return nil, "Failed to load custom asset: " .. tostring(uri)
	end

	local okImg, editable = Try(function()
		return AssetService:CreateEditableImageAsync(Content.fromUri(uri))
	end)
	if not okImg then
		return nil, "Failed to create editable image: " .. tostring(editable)
	end

	local okBuf, buf = Try(function()
		return editable:ReadPixelsBuffer(Vector2.zero, editable.Size)
	end)
	if not okBuf then
		return nil, "Failed to read pixels: " .. tostring(buf)
	end

	local okB64, b64 = Try(function()
		local small, sw, sh = Downscale(buf, editable.Size.X, editable.Size.Y, MAX_WIDTH)
		return crypt.base64encode(BuildPNG(small, sw, sh))
	end)
	if not okB64 then
		return nil, "Failed to encode base64: " .. tostring(b64)
	end

	return b64, nil
end

--============================================================================
-- HTTP — POST to the backend, return the ASCII string
--============================================================================

local function FetchAscii(assetPath)
	local b64, encodeErr = EncodeAssetToBase64(assetPath)
	if not b64 then
		return nil, encodeErr
	end

	local okReq, response = Try(function()
		return request({
			Url = API_URL,
			Method = "POST",
			Headers = { ["Content-Type"] = "application/json" },
			Body = HttpService:JSONEncode({ image = b64, columns = COLUMNS }),
		})
	end)
	if not okReq then
		return nil, "HTTP request failed: " .. tostring(response)
	end

	-- Normalize response (executors vary: Body/body, StatusCode/status_code)
	local body = response.Body or response.body
	local status = response.StatusCode or response.status_code or 200
	if response.Success == false or status >= 400 then
		return nil, "Server error (" .. tostring(status) .. "): " .. tostring(body)
	end
	if type(body) ~= "string" or body == "" then
		return nil, "Empty response body"
	end

	local okJson, decoded = Try(function()
		return HttpService:JSONDecode(body)
	end)
	if not okJson then
		return nil, "Bad JSON from server: " .. string.sub(body, 1, 120)
	end

	-- Expected: { success = true, data = { ascii = "..." } }
	local ascii = decoded and decoded.data and decoded.data.ascii
		or (decoded and decoded.ascii) -- legacy fallback
	if not ascii then
		return nil, "Unexpected response: " .. HttpService:JSONEncode(decoded)
	end

	return ascii, nil
end

--============================================================================
-- UI
--============================================================================

local function Make(name, class, parent, props)
	local obj = Instance.new(class)
	obj.Name = name
	if props then
		for k, v in props do
			obj[k] = v
		end
	end
	obj.Parent = parent
	return obj
end

local gui = Make("AsciiGui", "ScreenGui", gethui() or game.CoreGui, {
	ResetOnSpawn = false,
})

local frame = Make("Frame", "Frame", gui, {
	Size = UDim2.new(0, 560, 0, 380),
	Position = UDim2.new(0.3, 0, 0.2, 0),
	BackgroundColor3 = Color3.fromRGB(28, 28, 28),
	Active = true,
	Draggable = true,
})
Make("UICorner", "UICorner", frame, { CornerRadius = UDim.new(0, 8) })

Make("TextLabel", "TextLabel", frame, {
	Text = "Image → ASCII",
	Size = UDim2.new(1, -40, 0, 30),
	Position = UDim2.new(0, 10, 0, 6),
	BackgroundTransparency = 1,
	TextColor3 = Color3.new(1, 1, 1),
	Font = Enum.Font.GothamBold,
	TextSize = 18,
	TextXAlignment = Enum.TextXAlignment.Left,
})

local close = Make("CloseBtn", "TextButton", frame, {
	Text = "✕",
	Size = UDim2.new(0, 30, 0, 30),
	Position = UDim2.new(1, -34, 0, 4),
	BackgroundTransparency = 1,
	TextColor3 = Color3.fromRGB(255, 90, 90),
	Font = Enum.Font.GothamBold,
	TextSize = 16,
})
close.MouseButton1Click:Connect(function()
	gui:Destroy()
end)

local scroll = Make("Scroll", "ScrollingFrame", frame, {
	Size = UDim2.new(0.94, 0, 0.68, 0),
	Position = UDim2.new(0.03, 0, 0.11, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.XY,
	ScrollBarThickness = 6,
	ScrollingDirection = Enum.ScrollingDirection.XY,
	BorderSizePixel = 0,
	BackgroundColor3 = Color3.fromRGB(35, 35, 35),
})
Make("UICorner", "UICorner", scroll, { CornerRadius = UDim.new(0, 6) })

local output = Make("Output", "TextLabel", scroll, {
	RichText = true,
	AutomaticSize = Enum.AutomaticSize.XY,
	Position = UDim2.new(0, 6, 0, 6),
	TextWrapped = false,
	TextYAlignment = Enum.TextYAlignment.Top,
	TextXAlignment = Enum.TextXAlignment.Left,
	Font = Enum.Font.Code,
	TextSize = 14,
	TextColor3 = Color3.new(1, 1, 1),
	BackgroundTransparency = 1,
	Text = "-- enter an asset path below and hit Convert --",
})

local input = Make("AssetPath", "TextBox", frame, {
	Size = UDim2.new(0.62, 0, 0, 30),
	Position = UDim2.new(0.03, 0, 0.83, 0),
	ClearTextOnFocus = true,
	Text = "asset://image.png",
	TextYAlignment = Enum.TextYAlignment.Center,
	TextXAlignment = Enum.TextXAlignment.Left,
	Font = Enum.Font.Code,
	TextSize = 13,
	TextColor3 = Color3.new(1, 1, 1),
	BackgroundColor3 = Color3.fromRGB(50, 50, 50),
})

local function SetStatus(text, isError)
	output.Text = text
	output.TextColor3 = if isError then Color3.fromRGB(255, 120, 120) else Color3.new(1, 1, 1)
end

local convert = Make("ConvertBtn", "TextButton", frame, {
	Size = UDim2.new(0.13, 0, 0, 30),
	Position = UDim2.new(0.67, 0, 0.83, 0),
	Text = "Convert",
	Font = Enum.Font.GothamBold,
	TextSize = 13,
	TextColor3 = Color3.new(1, 1, 1),
	BackgroundColor3 = Color3.fromRGB(70, 110, 255),
})
Make("UICorner", "UICorner", convert, { CornerRadius = UDim.new(0, 5) })

local copy = Make("CopyBtn", "TextButton", frame, {
	Size = UDim2.new(0.16, 0, 0, 30),
	Position = UDim2.new(0.81, 0, 0.83, 0),
	Text = "Copy",
	Font = Enum.Font.GothamBold,
	TextSize = 13,
	TextColor3 = Color3.new(1, 1, 1),
	BackgroundColor3 = Color3.fromRGB(60, 60, 60),
})
Make("UICorner", "UICorner", copy, { CornerRadius = UDim.new(0, 5) })

local LastResult = ""

convert.MouseButton1Click:Connect(function()
	SetStatus("Loading...", false)
	convert.Text = "..."
	local ok, result = Try(function()
		return FetchAscii(input.Text)
	end)

	if ok and result then
		LastResult = result
		output.Text = result
		convert.Text = "Convert"
	else
		SetStatus("Error: " .. tostring(result), true)
		convert.Text = "Convert"
	end
end)

copy.MouseButton1Click:Connect(function()
	if LastResult ~= "" then
		setclipboard(LastResult)
		copy.Text = "Copied!"
		task.delay(1.2, function()
			copy.Text = "Copy"
		end)
	end
end)
