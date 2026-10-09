local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")
local HttpService = game:GetService("HttpService")

local Xyloria = {}
local Window = {}
Window.__index = Window
local Tab = {}
Tab.__index = Tab

Xyloria.Version = "1.1.0"

local TEXT_SIZE = 11

Xyloria.Themes = {
	Teal = {
		Background = Color3.fromRGB(15, 15, 15),
		Panel = Color3.fromRGB(22, 22, 22),
		Element = Color3.fromRGB(33, 33, 33),
		ElementHover = Color3.fromRGB(41, 41, 41),
		Stroke = Color3.fromRGB(46, 46, 46),
		Text = Color3.fromRGB(168, 168, 168),
		TextBright = Color3.fromRGB(232, 232, 232),
		Muted = Color3.fromRGB(105, 105, 105),
		Accent = Color3.fromRGB(20, 184, 200),
		Danger = Color3.fromRGB(226, 84, 84),
	},
	Ocean = { Accent = Color3.fromRGB(58, 134, 255) },
	Mint = { Accent = Color3.fromRGB(52, 211, 153) },
	Violet = { Accent = Color3.fromRGB(139, 112, 255) },
	Rose = { Accent = Color3.fromRGB(244, 94, 134) },
}

local Ease = {
	Quick = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	Fast = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	Medium = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
	Slow = TweenInfo.new(0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
	Pop = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	In = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
}

local function resolveTheme(input)
	local theme = {}
	for key, value in pairs(Xyloria.Themes.Teal) do
		theme[key] = value
	end
	local source = input
	if type(input) == "string" then
		source = Xyloria.Themes[input]
	end
	if type(source) == "table" then
		for key, value in pairs(source) do
			theme[key] = value
		end
	end
	return theme
end

local function create(className, props)
	local object = Instance.new(className)
	local parent = nil
	for key, value in pairs(props) do
		if key == "Parent" then
			parent = value
		else
			object[key] = value
		end
	end
	object.Parent = parent
	return object
end

local function newLabel(props)
	local merged = {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	}
	for key, value in pairs(props) do
		merged[key] = value
	end
	return create("TextLabel", merged)
end

local function newButton(props)
	local merged = {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
	}
	for key, value in pairs(props) do
		merged[key] = value
	end
	return create("TextButton", merged)
end

local function corner(parent, radius)
	return create("UICorner", { CornerRadius = UDim.new(0, radius), Parent = parent })
end

local function stroke(parent, color, thickness)
	return create("UIStroke", {
		Color = color,
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

local function padding(parent, top, right, bottom, left)
	return create("UIPadding", {
		PaddingTop = UDim.new(0, top),
		PaddingRight = UDim.new(0, right),
		PaddingBottom = UDim.new(0, bottom),
		PaddingLeft = UDim.new(0, left),
		Parent = parent,
	})
end

local function apply(object, properties, instant, info)
	if instant then
		for property, value in pairs(properties) do
			object[property] = value
		end
		return nil
	end
	local tween = TweenService:Create(object, info or Ease.Medium, properties)
	tween:Play()
	return tween
end

local function fire(callback, ...)
	if type(callback) == "function" then
		task.spawn(callback, ...)
	end
end

local function parse(first, keys, ...)
	if type(first) == "table" then
		return first
	end
	local config = {}
	config[keys[1]] = first
	local rest = { ... }
	for index = 2, #keys do
		config[keys[index]] = rest[index - 1]
	end
	return config
end

local function isPointer(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

local function decimalsFor(step)
	local places = 0
	while places < 4 do
		local scaled = step * 10 ^ places
		if math.abs(scaled - math.floor(scaled + 0.5)) < 0.000001 then
			break
		end
		places += 1
	end
	return places
end

local function startDrag(input, onMove, onEnd)
	local reference = nil
	local connections = {}
	local finished = false

	local function finish()
		if finished then
			return
		end
		finished = true
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end
		if onEnd then
			onEnd()
		end
	end

	table.insert(connections, UserInputService.InputChanged:Connect(function(changed)
		local isMouse = changed.UserInputType == Enum.UserInputType.MouseMovement
		local isTouch = changed.UserInputType == Enum.UserInputType.Touch and changed == input
		if isMouse or isTouch then
			local position = Vector2.new(changed.Position.X, changed.Position.Y)
			if not reference then
				reference = position
			end
			onMove(position, reference)
		end
	end))

	table.insert(connections, UserInputService.InputEnded:Connect(function(ended)
		local sameTouch = ended == input
		local mouseRelease = input.UserInputType == Enum.UserInputType.MouseButton1
			and ended.UserInputType == Enum.UserInputType.MouseButton1
		if sameTouch or mouseRelease then
			finish()
		end
	end))

	return finish
end

local function toOffset(position, screen)
	return Vector2.new(
		position.X.Scale * screen.X + position.X.Offset,
		position.Y.Scale * screen.Y + position.Y.Offset
	)
end

local function resolveKey(value)
	if typeof(value) == "EnumItem" then
		return value
	end
	if type(value) == "string" then
		local ok, key = pcall(function()
			return Enum.KeyCode[value]
		end)
		if ok then
			return key
		end
	end
	return nil
end

local function measureHeight(text, face, width)
	local ok, result = pcall(function()
		local params = Instance.new("GetTextBoundsParams")
		params.Text = text
		params.Font = face
		params.Size = TEXT_SIZE
		params.Width = width
		return TextService:GetTextBoundsAsync(params)
	end)
	if ok and result then
		return result.Y
	end
	local perLine = math.max(1, math.floor(width / (TEXT_SIZE * 0.6)))
	local length = utf8.len(text) or #text
	return math.ceil(length / perLine) * (TEXT_SIZE + 3)
end

local function getContainer()
	local ok, result = pcall(function()
		if gethui then
			return gethui()
		end
		return nil
	end)
	if ok and result then
		return result
	end
	return Players.LocalPlayer:WaitForChild("PlayerGui")
end

function Window:_connect(signal, callback)
	local connection = signal:Connect(callback)
	table.insert(self._connections, connection)
	return connection
end

function Window:_bind(object, property, key)
	table.insert(self._binds, { object, property, key })
	object[property] = self.Theme[key]
end

function Window:_register(painter)
	table.insert(self._painters, painter)
	painter(true)
end

function Window:SetTheme(input)
	local source = input
	if type(input) == "string" then
		source = Xyloria.Themes[input]
	end
	if type(source) ~= "table" then
		return
	end
	for key, value in pairs(source) do
		self.Theme[key] = value
	end
	for _, entry in ipairs(self._binds) do
		apply(entry[1], { [entry[2]] = self.Theme[entry[3]] }, false, Ease.Medium)
	end
	for _, painter in ipairs(self._painters) do
		painter(false)
	end
end

function Window:SetAccent(color)
	self:SetTheme({ Accent = color })
end

function Window:_flag(object, flag, value)
	if not flag then
		return
	end
	object.Flag = flag
	self._flagObjects[flag] = object
	self.Flags[flag] = value
end

function Window:_updateFlag(object, value)
	if object.Flag then
		self.Flags[object.Flag] = value
	end
end

function Window:SaveConfig(name)
	if not writefile then
		return false
	end
	local ok = pcall(function()
		if makefolder and isfolder and not isfolder(self.ConfigFolder) then
			makefolder(self.ConfigFolder)
		end
		writefile(self.ConfigFolder .. "/" .. name .. ".json", HttpService:JSONEncode(self.Flags))
	end)
	return ok
end

function Window:LoadConfig(name)
	if not readfile then
		return false
	end
	local ok, data = pcall(function()
		return HttpService:JSONDecode(readfile(self.ConfigFolder .. "/" .. name .. ".json"))
	end)
	if not ok or type(data) ~= "table" then
		return false
	end
	for flag, value in pairs(data) do
		local object = self._flagObjects[flag]
		if object then
			object:Set(value)
		end
	end
	return true
end

function Window:SetTitle(text)
	self._titleLabel.MaxVisibleGraphemes = -1
	self._titleLabel.Text = text
	self.Title = text
end

function Window:_showPill()
	self._pill.Visible = true
	self._pillScale.Scale = 0.5
	self._pillBody.GroupTransparency = 1
	apply(self._pillScale, { Scale = 1 }, false, Ease.Pop)
	apply(self._pillBody, { GroupTransparency = 0 }, false, Ease.Medium)
end

function Window:Minimize()
	if self._destroyed or self._closing or self.Minimized then
		return
	end
	self.Minimized = true
	self._token += 1
	local token = self._token
	self._savedPosition = self._root.Position
	self._rootTween = apply(self._root, { Position = self._pill.Position }, false, Ease.In)
	apply(self._introScale, { Scale = 0.2 }, false, Ease.In)
	apply(self._body, { GroupTransparency = 1 }, false, Ease.In)
	task.delay(0.28, function()
		if self._destroyed or self._token ~= token then
			return
		end
		self._root.Visible = false
		self:_showPill()
	end)
end

function Window:Restore()
	if self._destroyed or self._closing or not self.Minimized then
		return
	end
	self.Minimized = false
	self._token += 1
	local token = self._token
	local root = self._root
	apply(self._pillScale, { Scale = 0.5 }, false, Ease.Fast)
	apply(self._pillBody, { GroupTransparency = 1 }, false, Ease.Fast)
	root.Position = self._pill.Position
	self._introScale.Scale = 0.2
	self._body.GroupTransparency = 1
	root.Visible = true
	self._rootTween = apply(root, { Position = self._savedPosition }, false, Ease.Slow)
	apply(self._introScale, { Scale = 1 }, false, Ease.Pop)
	apply(self._body, { GroupTransparency = 0 }, false, Ease.Medium)
	task.delay(0.15, function()
		if self._destroyed or self._token ~= token then
			return
		end
		self._pill.Visible = false
	end)
end

function Window:Toggle()
	if self.Minimized then
		self:Restore()
	else
		self:Minimize()
	end
end

function Window:Close()
	if self._destroyed or self._closing then
		return
	end
	self._closing = true
	self._token += 1
	if self._pill.Visible then
		apply(self._pillBody, { GroupTransparency = 1 }, false, Ease.Fast)
		apply(self._pillScale, { Scale = 0.5 }, false, Ease.Fast)
	end
	if self._root.Visible then
		apply(self._introScale, { Scale = 0.85 }, false, Ease.In)
		apply(self._body, { GroupTransparency = 1 }, false, Ease.In)
	end
	task.delay(0.3, function()
		self:Destroy()
	end)
end

function Window:Destroy()
	if self._destroyed then
		return
	end
	self._destroyed = true
	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	self._connections = {}
	if self.Gui then
		self.Gui:Destroy()
	end
	if self._onClose then
		task.spawn(self._onClose)
	end
end

function Window:SelectTab(target, instant)
	local tab = target
	if type(target) == "string" then
		tab = nil
		for _, candidate in ipairs(self.Tabs) do
			if candidate.Name == target then
				tab = candidate
				break
			end
		end
	end
	if not tab or tab == self._active then
		return
	end
	local previous = self._active
	self._active = tab
	if previous then
		previous.Page.Visible = false
		previous.Page.GroupTransparency = 1
		previous._paint(false)
	end
	tab.Page.Position = UDim2.fromOffset(0, instant and 0 or 12)
	tab.Page.GroupTransparency = instant and 0 or 1
	tab.Page.Visible = true
	apply(tab.Page, { Position = UDim2.fromOffset(0, 0), GroupTransparency = 0 }, instant, Ease.Medium)
	tab._paint(instant)
end

function Window:CreateTab(first)
	local config = type(first) == "table" and first or { Name = first }
	local tab = setmetatable({}, Tab)
	tab.Window = self
	tab.Name = config.Name or "Tab"
	tab._order = 0
	local hovering = false
	local fontFace = self.FontFace

	local button = newButton({
		Name = tab.Name,
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundColor3 = self.Theme.Element,
		BackgroundTransparency = 1,
		Text = tab.Name,
		FontFace = fontFace,
		TextSize = TEXT_SIZE,
		TextColor3 = self.Theme.Text,
		TextTruncate = Enum.TextTruncate.AtEnd,
		LayoutOrder = #self.Tabs + 1,
		Parent = self._tabList,
	})
	corner(button, 4)
	padding(button, 0, 8, 0, 8)
	local buttonStroke = stroke(button, self.Theme.Stroke)
	buttonStroke.Transparency = 1
	local indicator = create("Frame", {
		Name = "Indicator",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, -4, 0.5, 0),
		Size = UDim2.fromOffset(2, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = button,
	})
	corner(indicator, 1)

	local page = create("CanvasGroup", {
		Name = tab.Name,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		GroupTransparency = 1,
		Visible = false,
		Parent = self._content,
	})
	local scroll = create("ScrollingFrame", {
		Name = "Scroll",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		ScrollBarImageTransparency = 0.2,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Parent = page,
	})
	self:_bind(scroll, "ScrollBarImageColor3", "Accent")
	create("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = scroll,
	})
	padding(scroll, 8, 10, 8, 8)

	tab.Button = button
	tab.Page = page
	tab.Scroll = scroll

	local function paint(instant)
		local theme = self.Theme
		local selected = self._active == tab
		local hot = hovering and not selected
		apply(button, {
			BackgroundTransparency = selected and 0 or (hot and 0.5 or 1),
			BackgroundColor3 = theme.Element,
			TextColor3 = selected and theme.Accent or (hot and theme.TextBright or theme.Text),
		}, instant, Ease.Fast)
		apply(buttonStroke, { Transparency = selected and 0 or 1, Color = theme.Stroke }, instant, Ease.Fast)
		apply(indicator, {
			BackgroundTransparency = selected and 0 or 1,
			BackgroundColor3 = theme.Accent,
			Size = UDim2.fromOffset(2, selected and 12 or 0),
		}, instant, Ease.Medium)
	end
	tab._paint = paint
	self:_register(paint)

	table.insert(self.Tabs, tab)

	self:_connect(button.Activated, function()
		self:SelectTab(tab)
	end)
	self:_connect(button.MouseEnter, function()
		hovering = true
		paint(false)
	end)
	self:_connect(button.MouseLeave, function()
		hovering = false
		paint(false)
	end)

	if #self.Tabs == 1 then
		self:SelectTab(tab, true)
	end

	return tab
end

function Window:Notify(first, ...)
	local config = parse(first, { "Title", "Content", "Duration" }, ...)
	local title = tostring(config.Title or "xyloria")
	local content = tostring(config.Content or "")
	local duration = config.Duration or 4
	local theme = self.Theme
	local width = math.clamp(self.Gui.AbsoluteSize.X - 28, 160, 240)
	local textWidth = width - 28
	local contentHeight = 0
	if content ~= "" then
		contentHeight = measureHeight(content, self.FontFace, textWidth)
	end
	local height = 10 + 16 + (contentHeight > 0 and (4 + contentHeight) or 0) + 14

	self._notifyCount += 1
	local wrapper = create("Frame", {
		Name = "Notification",
		Size = UDim2.new(1, 0, 0, height),
		BackgroundTransparency = 1,
		LayoutOrder = self._notifyCount,
		Parent = self._notifyHolder,
	})
	local card = create("CanvasGroup", {
		Name = "Card",
		Position = UDim2.fromOffset(60, 0),
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = theme.Background,
		BorderSizePixel = 0,
		GroupTransparency = 1,
		Parent = wrapper,
	})
	corner(card, 6)
	local border = create("Frame", {
		Size = UDim2.new(1, -2, 1, -2),
		Position = UDim2.fromOffset(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 10,
		Parent = card,
	})
	corner(border, 5)
	stroke(border, theme.Stroke)
	create("Frame", {
		Name = "Bar",
		Size = UDim2.new(0, 3, 1, 0),
		BackgroundColor3 = theme.Accent,
		BorderSizePixel = 0,
		Parent = card,
	})
	newLabel({
		Name = "Title",
		Position = UDim2.fromOffset(14, 10),
		Size = UDim2.new(1, -24, 0, 16),
		Text = title,
		FontFace = self.FontFace,
		TextSize = TEXT_SIZE,
		TextColor3 = theme.TextBright,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = card,
	})
	if content ~= "" then
		newLabel({
			Name = "Content",
			Position = UDim2.fromOffset(14, 30),
			Size = UDim2.new(1, -24, 0, contentHeight),
			Text = content,
			FontFace = self.FontFace,
			TextSize = TEXT_SIZE,
			TextColor3 = theme.Text,
			TextWrapped = true,
			TextYAlignment = Enum.TextYAlignment.Top,
			Parent = card,
		})
	end
	local progress = create("Frame", {
		Name = "Progress",
		Position = UDim2.new(0, 0, 1, -2),
		Size = UDim2.new(1, 0, 0, 2),
		BackgroundColor3 = theme.Accent,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		Parent = card,
	})
	local closeButton = newButton({
		Name = "Dismiss",
		Size = UDim2.fromScale(1, 1),
		ZIndex = 20,
		Parent = card,
	})

	apply(card, { Position = UDim2.fromOffset(0, 0), GroupTransparency = 0 }, false, Ease.Slow)
	apply(progress, { Size = UDim2.new(0, 0, 0, 2) }, false, TweenInfo.new(duration, Enum.EasingStyle.Linear))

	local dismissed = false
	local function dismiss()
		if dismissed then
			return
		end
		dismissed = true
		if not wrapper.Parent then
			return
		end
		apply(card, { Position = UDim2.fromOffset(60, 0), GroupTransparency = 1 }, false, Ease.In)
		task.delay(0.28, function()
			if not wrapper.Parent then
				return
			end
			apply(wrapper, { Size = UDim2.new(1, 0, 0, 0) }, false, Ease.Fast)
			task.delay(0.2, function()
				if wrapper.Parent then
					wrapper:Destroy()
				end
			end)
		end)
	end

	closeButton.Activated:Connect(dismiss)
	task.delay(duration, dismiss)

	return dismiss
end

function Tab:_element(height)
	local window = self.Window
	self._order += 1
	local frame = create("Frame", {
		Size = UDim2.new(1, 0, 0, height),
		BackgroundColor3 = window.Theme.Element,
		BorderSizePixel = 0,
		LayoutOrder = self._order,
		Parent = self.Scroll,
	})
	corner(frame, 5)
	local line = stroke(frame, window.Theme.Stroke)
	window:_bind(line, "Color", "Stroke")
	return frame, line
end

function Tab:_attachHover(frame, hitbox)
	local window = self.Window
	local hovering = false
	local function paint(instant)
		apply(frame, {
			BackgroundColor3 = hovering and window.Theme.ElementHover or window.Theme.Element,
		}, instant, Ease.Fast)
	end
	window:_register(paint)
	window:_connect(hitbox.MouseEnter, function()
		hovering = true
		paint(false)
	end)
	window:_connect(hitbox.MouseLeave, function()
		hovering = false
		paint(false)
	end)
	return function()
		return hovering
	end
end

function Tab:CreateSection(first)
	local window = self.Window
	local config = type(first) == "table" and first or { Name = first }
	self._order += 1
	local frame = create("Frame", {
		Name = "Section",
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundTransparency = 1,
		LayoutOrder = self._order,
		Parent = self.Scroll,
	})
	local label = newLabel({
		Size = UDim2.new(1, -4, 0, 22),
		Position = UDim2.fromOffset(2, 0),
		Text = string.upper(config.Name or "Section"),
		FontFace = window.FontFace,
		TextSize = TEXT_SIZE,
		TextYAlignment = Enum.TextYAlignment.Bottom,
		Parent = frame,
	})
	window:_bind(label, "TextColor3", "Accent")
	local line = create("Frame", {
		Position = UDim2.new(0, 0, 1, -1),
		Size = UDim2.new(1, 0, 0, 1),
		BorderSizePixel = 0,
		Parent = frame,
	})
	window:_bind(line, "BackgroundColor3", "Stroke")
	return { Instance = frame }
end

function Tab:CreateLabel(first)
	local window = self.Window
	local config = type(first) == "table" and first or { Text = first }
	self._order += 1
	local label = newLabel({
		Name = "Label",
		Size = UDim2.new(1, 0, 0, 18),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = config.Text or "",
		FontFace = window.FontFace,
		TextSize = TEXT_SIZE,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		LayoutOrder = self._order,
		Parent = self.Scroll,
	})
	padding(label, 0, 4, 0, 4)
	window:_bind(label, "TextColor3", "Muted")
	local object = { Instance = label }
	function object:Set(text)
		label.Text = tostring(text)
	end
	return object
end

function Tab:CreateButton(first, ...)
	local window = self.Window
	local config = parse(first, { "Name", "Callback" }, ...)
	local frame, line = self:_element(34)
	local label = newLabel({
		Name = "Label",
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -40, 1, 0),
		Text = config.Name or "Button",
		FontFace = window.FontFace,
		TextSize = TEXT_SIZE,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = frame,
	})
	window:_bind(label, "TextColor3", "TextBright")
	local arrow = newLabel({
		Name = "Arrow",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(14, 20),
		Text = ">",
		FontFace = window.FontFace,
		TextSize = TEXT_SIZE,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = frame,
	})
	window:_bind(arrow, "TextColor3", "Accent")
	local hitbox = newButton({ Name = "Hitbox", Size = UDim2.fromScale(1, 1), ZIndex = 5, Parent = frame })
	local isHovering = self:_attachHover(frame, hitbox)

	local object = { Name = config.Name or "Button", Callback = config.Callback, Instance = frame }

	function object:Fire()
		local theme = window.Theme
		line.Color = theme.Accent
		apply(line, { Color = theme.Stroke }, false, Ease.Slow)
		frame.BackgroundColor3 = theme.Accent:Lerp(theme.Element, 0.8)
		apply(frame, { BackgroundColor3 = isHovering() and theme.ElementHover or theme.Element }, false, Ease.Slow)
		fire(self.Callback)
	end

	window:_connect(hitbox.Activated, function()
		object:Fire()
	end)

	return object
end

function Tab:CreateToggle(first, ...)
	local window = self.Window
	local config = parse(first, { "Name", "Default", "Callback" }, ...)
	local frame = self:_element(36)
	local toggle = {
		Name = config.Name or "Toggle",
		Value = config.Default == true,
		Callback = config.Callback,
		Instance = frame,
	}

	local label = newLabel({
		Name = "Label",
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -68, 1, 0),
		Text = toggle.Name,
		FontFace = window.FontFace,
		TextSize = TEXT_SIZE,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = frame,
	})
	local track = create("Frame", {
		Name = "Track",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(40, 20),
		BorderSizePixel = 0,
		Parent = frame,
	})
	window:_bind(track, "BackgroundColor3", "Panel")
	corner(track, 3)
	local trackStroke = stroke(track, window.Theme.Stroke)
	local knob = create("Frame", {
		Name = "Knob",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 3, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		BorderSizePixel = 0,
		Parent = track,
	})
	corner(knob, 3)
	local hitbox = newButton({ Name = "Hitbox", Size = UDim2.fromScale(1, 1), ZIndex = 5, Parent = frame })
	self:_attachHover(frame, hitbox)

	local function paint(instant)
		local theme = window.Theme
		local on = toggle.Value
		apply(knob, {
			AnchorPoint = Vector2.new(on and 1 or 0, 0.5),
			Position = UDim2.new(on and 1 or 0, on and -3 or 3, 0.5, 0),
			BackgroundColor3 = on and theme.Accent or theme.Muted,
		}, instant, Ease.Medium)
		apply(trackStroke, { Color = on and theme.Accent or theme.Stroke }, instant, Ease.Medium)
		apply(label, { TextColor3 = on and theme.TextBright or theme.Text }, instant, Ease.Fast)
	end
	window:_register(paint)
	window:_flag(toggle, config.Flag, toggle.Value)

	function toggle:Set(value, silent)
		value = value == true
		if value == self.Value then
			return
		end
		self.Value = value
		window:_updateFlag(self, value)
		paint(false)
		apply(knob, { Size = UDim2.fromOffset(18, 14) }, false, Ease.Fast)
		task.delay(0.12, function()
			if knob.Parent then
				apply(knob, { Size = UDim2.fromOffset(14, 14) }, false, Ease.Fast)
			end
		end)
		if not silent then
			fire(self.Callback, value)
		end
	end

	function toggle:Get()
		return self.Value
	end

	window:_connect(hitbox.Activated, function()
		toggle:Set(not toggle.Value)
	end)

	return toggle
end

function Tab:CreateSlider(first, ...)
	local window = self.Window
	local config = parse(first, { "Name", "Min", "Max", "Default", "Callback" }, ...)
	local min = config.Min or 0
	local max = config.Max or 100
	if max <= min then
		max = min + 1
	end
	local increment = config.Increment or 1
	if increment <= 0 then
		increment = 1
	end
	local suffix = config.Suffix or ""
	local decimals = decimalsFor(increment)

	local function snap(value)
		value = math.clamp(value, min, max)
		value = min + math.floor((value - min) / increment + 0.5) * increment
		value = math.clamp(value, min, max)
		return math.floor(value * 10000 + 0.5) / 10000
	end

	local frame = self:_element(48)
	local slider = {
		Name = config.Name or "Slider",
		Min = min,
		Max = max,
		Value = snap(config.Default or min),
		Callback = config.Callback,
		Instance = frame,
	}

	local label = newLabel({
		Name = "Label",
		Position = UDim2.fromOffset(12, 6),
		Size = UDim2.new(1, -90, 0, 16),
		Text = slider.Name,
		FontFace = window.FontFace,
		TextSize = TEXT_SIZE,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = frame,
	})
	window:_bind(label, "TextColor3", "Text")
	local valueLabel = newLabel({
		Name = "Value",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 6),
		Size = UDim2.fromOffset(0, 16),
		AutomaticSize = Enum.AutomaticSize.X,
		FontFace = window.FontFace,
		TextSize = TEXT_SIZE,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = frame,
	})
	window:_bind(valueLabel, "TextColor3", "Accent")
	local track = create("Frame", {
		Name = "Track",
		Position = UDim2.fromOffset(12, 32),
		Size = UDim2.new(1, -24, 0, 6),
		BorderSizePixel = 0,
		Parent = frame,
	})
	window:_bind(track, "BackgroundColor3", "Panel")
	corner(track, 3)
	window:_bind(stroke(track, window.Theme.Stroke), "Color", "Stroke")
	local fill = create("Frame", {
		Name = "Fill",
		Size = UDim2.fromScale(0, 1),
		BorderSizePixel = 0,
		Parent = track,
	})
	window:_bind(fill, "BackgroundColor3", "Accent")
	corner(fill, 3)
	local knob = create("Frame", {
		Name = "Knob",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(12, 12),
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = track,
	})
	window:_bind(knob, "BackgroundColor3", "TextBright")
	corner(knob, 3)
	window:_bind(stroke(knob, window.Theme.Accent), "Color", "Accent")
	local hitbox = newButton({
		Name = "Hitbox",
		Position = UDim2.fromOffset(0, 22),
		Size = UDim2.new(1, 0, 0, 26),
		ZIndex = 5,
		Parent = frame,
	})
	self:_attachHover(frame, hitbox)

	local function render(instant)
		local alpha = (slider.Value - min) / (max - min)
		apply(fill, { Size = UDim2.fromScale(alpha, 1) }, instant, Ease.Quick)
		apply(knob, { Position = UDim2.fromScale(alpha, 0.5) }, instant, Ease.Quick)
		valueLabel.Text = string.format("%." .. decimals .. "f", slider.Value) .. suffix
	end
	render(true)
	window:_flag(slider, config.Flag, slider.Value)

	function slider:Set(value, silent)
		value = snap(value)
		if value == self.Value then
			return
		end
		self.Value = value
		window:_updateFlag(self, value)
		render(false)
		if not silent then
			fire(self.Callback, value)
		end
	end

	function slider:Get()
		return self.Value
	end

	local function updateFromX(x)
		local width = track.AbsoluteSize.X
		if width <= 0 then
			return
		end
		local alpha = math.clamp((x - track.AbsolutePosition.X) / width, 0, 1)
		slider:Set(min + (max - min) * alpha)
	end

	window:_connect(hitbox.InputBegan, function(input)
		if not isPointer(input) then
			return
		end
		local scroll = self.Scroll
		scroll.ScrollingEnabled = false
		apply(knob, { Size = UDim2.fromOffset(15, 15) }, false, Ease.Fast)
		updateFromX(input.Position.X)
		startDrag(input, function(position)
			updateFromX(position.X)
		end, function()
			scroll.ScrollingEnabled = true
			apply(knob, { Size = UDim2.fromOffset(12, 12) }, false, Ease.Fast)
		end)
	end)

	return slider
end

function Tab:CreateDropdown(first, ...)
	local window = self.Window
	local config = parse(first, { "Name", "Options", "Default", "Callback" }, ...)
	local frame = self:_element(36)
	frame.ClipsDescendants = true
	local dropdown = {
		Name = config.Name or "Dropdown",
		Options = config.Options or {},
		Value = config.Default,
		Callback = config.Callback,
		Open = false,
		Instance = frame,
	}
	if dropdown.Value == nil then
		dropdown.Value = dropdown.Options[1]
	end

	local label = newLabel({
		Name = "Label",
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -190, 0, 36),
		Text = dropdown.Name,
		FontFace = window.FontFace,
		TextSize = TEXT_SIZE,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = frame,
	})
	window:_bind(label, "TextColor3", "Text")
	local valueLabel = newLabel({
		Name = "Value",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -30, 0, 0),
		Size = UDim2.fromOffset(0, 36),
		AutomaticSize = Enum.AutomaticSize.X,
		FontFace = window.FontFace,
		TextSize = TEXT_SIZE,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = frame,
	})
	window:_bind(valueLabel, "TextColor3", "Accent")
	create("UISizeConstraint", { MaxSize = Vector2.new(140, 36), Parent = valueLabel })
	local arrow = newLabel({
		Name = "Arrow",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 0),
		Size = UDim2.fromOffset(14, 36),
		Text = "v",
		FontFace = window.FontFace,
		TextSize = TEXT_SIZE,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = frame,
	})
	window:_bind(arrow, "TextColor3", "Muted")
	local list = create("ScrollingFrame", {
		Name = "List",
		Position = UDim2.fromOffset(6, 40),
		Size = UDim2.new(1, -12, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		ScrollBarImageTransparency = 0.2,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Parent = frame,
	})
	window:_bind(list, "ScrollBarImageColor3", "Accent")
	create("UIListLayout", {
		Padding = UDim.new(0, 3),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = list,
	})
	local header = newButton({ Name = "Header", Size = UDim2.new(1, 0, 0, 36), ZIndex = 5, Parent = frame })
	self:_attachHover(frame, header)

	local rows = {}

	local function listHeight()
		local visible = math.min(#dropdown.Options, 5)
		if visible <= 0 then
			return 0
		end
		return visible * 26 + (visible - 1) * 3
	end

	local function expandedHeight()
		return 40 + listHeight() + 6
	end

	local function paint(instant)
		local theme = window.Theme
		valueLabel.Text = dropdown.Value ~= nil and tostring(dropdown.Value) or "None"
		for _, row in ipairs(rows) do
			local selected = row.Option == dropdown.Value
			apply(row.Button, {
				BackgroundColor3 = theme.Panel,
				TextColor3 = selected and theme.Accent or theme.Text,
			}, instant, Ease.Fast)
		end
	end

	function dropdown:Toggle(state)
		if state == nil then
			state = not self.Open
		end
		self.Open = state
		apply(frame, { Size = UDim2.new(1, 0, 0, state and expandedHeight() or 36) }, false, Ease.Medium)
		apply(arrow, { Rotation = state and 180 or 0 }, false, Ease.Medium)
	end

	function dropdown:Set(value, silent)
		self.Value = value
		window:_updateFlag(self, value)
		paint(false)
		if not silent then
			fire(self.Callback, value)
		end
	end

	function dropdown:Get()
		return self.Value
	end

	local function rebuild()
		for _, row in ipairs(rows) do
			row.Button:Destroy()
		end
		rows = {}
		for index, option in ipairs(dropdown.Options) do
			local optionButton = newButton({
				Name = tostring(option),
				Size = UDim2.new(1, 0, 0, 26),
				BackgroundTransparency = 0,
				Text = tostring(option),
				FontFace = window.FontFace,
				TextSize = TEXT_SIZE,
				LayoutOrder = index,
				Parent = list,
			})
			corner(optionButton, 4)
			window:_connect(optionButton.Activated, function()
				dropdown:Set(option)
				dropdown:Toggle(false)
			end)
			rows[index] = { Button = optionButton, Option = option }
		end
		list.Size = UDim2.new(1, -12, 0, listHeight())
		paint(true)
		if dropdown.Open then
			apply(frame, { Size = UDim2.new(1, 0, 0, expandedHeight()) }, false, Ease.Fast)
		end
	end

	function dropdown:Refresh(options)
		self.Options = options or {}
		local found = false
		for _, option in ipairs(self.Options) do
			if option == self.Value then
				found = true
				break
			end
		end
		if not found then
			self.Value = self.Options[1]
			window:_updateFlag(self, self.Value)
		end
		rebuild()
	end

	window:_register(paint)
	window:_flag(dropdown, config.Flag, dropdown.Value)
	rebuild()

	window:_connect(header.Activated, function()
		dropdown:Toggle()
	end)

	return dropdown
end

function Tab:CreateTextbox(first, ...)
	local window = self.Window
	local config = parse(first, { "Name", "Default", "Placeholder", "Callback" }, ...)
	local frame = self:_element(36)
	local box = {
		Name = config.Name or "Textbox",
		Value = tostring(config.Default or ""),
		Callback = config.Callback,
		Instance = frame,
	}
	local label = newLabel({
		Name = "Label",
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -150, 1, 0),
		Text = box.Name,
		FontFace = window.FontFace,
		TextSize = TEXT_SIZE,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = frame,
	})
	window:_bind(label, "TextColor3", "Text")
	local input = create("TextBox", {
		Name = "Input",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(120, 22),
		BorderSizePixel = 0,
		Text = box.Value,
		PlaceholderText = config.Placeholder or "type here",
		FontFace = window.FontFace,
		TextSize = TEXT_SIZE,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = config.ClearTextOnFocus == true,
		Parent = frame,
	})
	window:_bind(input, "BackgroundColor3", "Panel")
	window:_bind(input, "TextColor3", "TextBright")
	window:_bind(input, "PlaceholderColor3", "Muted")
	corner(input, 3)
	padding(input, 0, 6, 0, 6)
	local inputStroke = stroke(input, window.Theme.Stroke)
	window:_bind(inputStroke, "Color", "Stroke")
	window:_flag(box, config.Flag, box.Value)

	window:_connect(input.Focused, function()
		apply(inputStroke, { Color = window.Theme.Accent }, false, Ease.Fast)
	end)
	window:_connect(input.FocusLost, function(enterPressed)
		apply(inputStroke, { Color = window.Theme.Stroke }, false, Ease.Fast)
		box.Value = input.Text
		window:_updateFlag(box, box.Value)
		fire(box.Callback, box.Value, enterPressed)
	end)

	function box:Set(value, silent)
		value = tostring(value)
		self.Value = value
		input.Text = value
		window:_updateFlag(self, value)
		if not silent then
			fire(self.Callback, value, false)
		end
	end

	function box:Get()
		return self.Value
	end

	return box
end

function Tab:CreateKeybind(first, ...)
	local window = self.Window
	local config = parse(first, { "Name", "Default", "Callback", "OnChanged" }, ...)
	local frame = self:_element(36)
	local bind = {
		Name = config.Name or "Keybind",
		Value = resolveKey(config.Default),
		Callback = config.Callback,
		OnChanged = config.OnChanged,
		Listening = false,
		Instance = frame,
	}
	local label = newLabel({
		Name = "Label",
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -110, 1, 0),
		Text = bind.Name,
		FontFace = window.FontFace,
		TextSize = TEXT_SIZE,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = frame,
	})
	window:_bind(label, "TextColor3", "Text")
	local button = newButton({
		Name = "Key",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(0, 22),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 0,
		FontFace = window.FontFace,
		TextSize = TEXT_SIZE,
		Parent = frame,
	})
	corner(button, 3)
	padding(button, 0, 8, 0, 8)
	create("UISizeConstraint", { MinSize = Vector2.new(44, 22), MaxSize = Vector2.new(120, 22), Parent = button })
	local buttonStroke = stroke(button, window.Theme.Stroke)
	self:_attachHover(frame, button)

	local function paint(instant)
		local theme = window.Theme
		button.Text = bind.Listening and "..." or (bind.Value and bind.Value.Name or "None")
		apply(button, {
			BackgroundColor3 = theme.Panel,
			TextColor3 = bind.Listening and theme.Accent or theme.Text,
		}, instant, Ease.Fast)
		apply(buttonStroke, { Color = bind.Listening and theme.Accent or theme.Stroke }, instant, Ease.Fast)
	end
	window:_register(paint)
	window:_flag(bind, config.Flag, bind.Value and bind.Value.Name or "None")

	function bind:Set(value, silent)
		self.Value = resolveKey(value)
		window:_updateFlag(self, self.Value and self.Value.Name or "None")
		paint(false)
		if not silent then
			fire(self.OnChanged, self.Value)
		end
	end

	function bind:Get()
		return self.Value
	end

	window:_connect(button.Activated, function()
		bind.Listening = not bind.Listening
		window._listening = bind.Listening
		paint(false)
	end)

	window:_connect(UserInputService.InputBegan, function(input, processed)
		if input.UserInputType ~= Enum.UserInputType.Keyboard then
			return
		end
		if bind.Listening then
			bind.Listening = false
			task.defer(function()
				window._listening = false
			end)
			if input.KeyCode == Enum.KeyCode.Escape then
				paint(false)
			elseif input.KeyCode == Enum.KeyCode.Backspace then
				bind:Set(nil)
			else
				bind:Set(input.KeyCode)
			end
			return
		end
		if processed then
			return
		end
		if bind.Value and input.KeyCode == bind.Value then
			fire(bind.Callback, bind.Value)
		end
	end)

	return bind
end

function Xyloria:CreateWindow(config)
	config = config or {}
	local self = setmetatable({}, Window)
	self.Theme = resolveTheme(config.Theme)
	self.Title = config.Title or "xyloria"
	self.FontFace = config.FontFace or Font.new("rbxasset://fonts/families/RobotoMono.json", Enum.FontWeight.Bold)
	self.ToggleKey = config.ToggleKey
	if self.ToggleKey == nil then
		self.ToggleKey = Enum.KeyCode.RightShift
	end
	self.Minimized = false
	self.Tabs = {}
	self._connections = {}
	self._binds = {}
	self._painters = {}
	self._token = 0
	self._active = nil
	self._destroyed = false
	self._closing = false
	self._notifyCount = 0
	self._onClose = config.OnClose
	self._listening = false
	self._rootTween = nil
	self.Flags = {}
	self._flagObjects = {}
	self.ConfigFolder = config.ConfigFolder or "Xyloria"

	local theme = self.Theme
	local fontFace = self.FontFace
	local size = config.Size or Vector2.new(460, 276)
	local guiName = config.Name or "Xyloria"

	local container = getContainer()
	local existing = container:FindFirstChild(guiName)
	if existing then
		existing:Destroy()
	end

	local gui = create("ScreenGui", {
		Name = guiName,
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 100,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = container,
	})
	self.Gui = gui

	local root = create("Frame", {
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(size.X, size.Y),
		BackgroundTransparency = 1,
		Active = true,
		Parent = gui,
	})
	local fit = create("UIScale", { Parent = root })
	local body = create("CanvasGroup", {
		Name = "Body",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		BorderSizePixel = 0,
		GroupTransparency = 1,
		Parent = root,
	})
	self:_bind(body, "BackgroundColor3", "Background")
	corner(body, 6)
	local introScale = create("UIScale", { Scale = 0.85, Parent = body })
	self._root = root
	self._body = body
	self._introScale = introScale

	local border = create("Frame", {
		Name = "Border",
		Position = UDim2.fromOffset(1, 1),
		Size = UDim2.new(1, -2, 1, -2),
		BackgroundTransparency = 1,
		ZIndex = 100,
		Parent = body,
	})
	corner(border, 5)
	self:_bind(stroke(border, theme.Stroke), "Color", "Stroke")

	local function updateScale()
		local screen = gui.AbsoluteSize
		if screen.X <= 0 or screen.Y <= 0 then
			return
		end
		fit.Scale = math.clamp(math.min((screen.X - 24) / size.X, (screen.Y - 24) / size.Y), 0.5, 1)
	end
	updateScale()
	self:_connect(gui:GetPropertyChangedSignal("AbsoluteSize"), updateScale)

	local topbar = create("Frame", {
		Name = "TopBar",
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundTransparency = 1,
		Active = true,
		Parent = body,
	})
	local mark = create("Frame", {
		Name = "Mark",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(18, 18),
		Size = UDim2.fromOffset(7, 7),
		Rotation = 45,
		BorderSizePixel = 0,
		Parent = topbar,
	})
	self:_bind(mark, "BackgroundColor3", "Accent")
	corner(mark, 1)
	local titleLabel = newLabel({
		Name = "Title",
		Position = UDim2.fromOffset(32, 0),
		Size = UDim2.new(0.6, -32, 1, 0),
		Text = self.Title,
		FontFace = fontFace,
		TextSize = TEXT_SIZE,
		MaxVisibleGraphemes = 0,
		Parent = topbar,
	})
	self:_bind(titleLabel, "TextColor3", "Text")
	self._titleLabel = titleLabel

	local divider = create("Frame", {
		Name = "Divider",
		Position = UDim2.fromOffset(0, 36),
		Size = UDim2.new(1, 0, 0, 1),
		BorderSizePixel = 0,
		Parent = body,
	})
	self:_bind(divider, "BackgroundColor3", "Stroke")
	local sweep = create("Frame", {
		Name = "Sweep",
		Position = UDim2.fromOffset(0, 36),
		Size = UDim2.new(0, 0, 0, 1),
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = body,
	})
	self:_bind(sweep, "BackgroundColor3", "Accent")

	local controls = create("Frame", {
		Name = "Controls",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0, 18),
		Size = UDim2.fromOffset(72, 26),
		BorderSizePixel = 0,
		Parent = body,
	})
	self:_bind(controls, "BackgroundColor3", "Panel")
	corner(controls, 4)
	self:_bind(stroke(controls, theme.Stroke), "Color", "Stroke")

	local minimizeButton = newButton({
		Name = "Minimize",
		Size = UDim2.new(0.5, 0, 1, 0),
		Parent = controls,
	})
	local minimizeIcon = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(10, 2),
		BorderSizePixel = 0,
		Parent = minimizeButton,
	})
	self:_bind(minimizeIcon, "BackgroundColor3", "Text")

	local closeButton = newButton({
		Name = "Close",
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.new(0.5, 0, 1, 0),
		Parent = controls,
	})
	local closeIcons = {}
	for _, rotation in ipairs({ 45, -45 }) do
		local bar = create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(12, 2),
			Rotation = rotation,
			BorderSizePixel = 0,
			Parent = closeButton,
		})
		self:_bind(bar, "BackgroundColor3", "Text")
		table.insert(closeIcons, bar)
	end
	local controlDivider = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0, 1, 0.6, 0),
		BorderSizePixel = 0,
		Parent = controls,
	})
	self:_bind(controlDivider, "BackgroundColor3", "Stroke")

	self:_connect(minimizeButton.MouseEnter, function()
		apply(minimizeIcon, { BackgroundColor3 = self.Theme.Accent }, false, Ease.Fast)
	end)
	self:_connect(minimizeButton.MouseLeave, function()
		apply(minimizeIcon, { BackgroundColor3 = self.Theme.Text }, false, Ease.Fast)
	end)
	self:_connect(closeButton.MouseEnter, function()
		for _, bar in ipairs(closeIcons) do
			apply(bar, { BackgroundColor3 = self.Theme.Danger }, false, Ease.Fast)
		end
	end)
	self:_connect(closeButton.MouseLeave, function()
		for _, bar in ipairs(closeIcons) do
			apply(bar, { BackgroundColor3 = self.Theme.Text }, false, Ease.Fast)
		end
	end)
	self:_connect(minimizeButton.Activated, function()
		self:Minimize()
	end)
	self:_connect(closeButton.Activated, function()
		self:Close()
	end)

	local sidebar = create("Frame", {
		Name = "Sidebar",
		Position = UDim2.fromOffset(-20, 46),
		Size = UDim2.new(0, 104, 1, -58),
		BorderSizePixel = 0,
		Parent = body,
	})
	self:_bind(sidebar, "BackgroundColor3", "Panel")
	corner(sidebar, 4)
	self:_bind(stroke(sidebar, theme.Stroke), "Color", "Stroke")
	local tabList = create("ScrollingFrame", {
		Name = "Tabs",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Parent = sidebar,
	})
	create("UIListLayout", {
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Parent = tabList,
	})
	padding(tabList, 8, 8, 8, 8)
	self._tabList = tabList

	local content = create("Frame", {
		Name = "Content",
		Position = UDim2.fromOffset(154, 46),
		Size = UDim2.new(1, -136, 1, -58),
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = body,
	})
	self:_bind(content, "BackgroundColor3", "Panel")
	corner(content, 4)
	self._content = content
	local contentBorder = create("Frame", {
		Name = "ContentBorder",
		Position = UDim2.fromOffset(154, 46),
		Size = UDim2.new(1, -136, 1, -58),
		BackgroundTransparency = 1,
		ZIndex = 50,
		Parent = body,
	})
	corner(contentBorder, 4)
	self:_bind(stroke(contentBorder, theme.Stroke), "Color", "Stroke")

	local notifyHolder = create("Frame", {
		Name = "Notifications",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -14, 1, -14),
		Size = UDim2.new(0, 240, 1, -28),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	create("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		Parent = notifyHolder,
	})
	self._notifyHolder = notifyHolder

	local pillText = config.MinimizeText or self.Title
	local pillLength = utf8.len(pillText) or #pillText
	local pillWidth = 44 + math.ceil(pillLength * TEXT_SIZE * 0.6) + 18
	local pill = create("Frame", {
		Name = "MinimizedButton",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = config.MinimizePosition or UDim2.new(0.5, 0, 0, 32),
		Size = UDim2.fromOffset(pillWidth, 40),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = gui,
	})
	local pillBody = create("CanvasGroup", {
		Name = "Body",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		GroupTransparency = 1,
		Parent = pill,
	})
	self:_bind(pillBody, "BackgroundColor3", "Background")
	create("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = pillBody })
	local pillScale = create("UIScale", { Scale = 0.5, Parent = pillBody })
	local pillBorder = create("Frame", {
		Position = UDim2.fromOffset(1, 1),
		Size = UDim2.new(1, -2, 1, -2),
		BackgroundTransparency = 1,
		ZIndex = 10,
		Parent = pillBody,
	})
	create("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = pillBorder })
	self:_bind(stroke(pillBorder, theme.Stroke), "Color", "Stroke")
	local logo = create("Frame", {
		Name = "Logo",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 26, 0.5, 0),
		Size = UDim2.fromOffset(15, 15),
		Rotation = 45,
		BorderSizePixel = 0,
		Parent = pillBody,
	})
	self:_bind(logo, "BackgroundColor3", "Accent")
	corner(logo, 4)
	local logoHole = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(5, 5),
		BorderSizePixel = 0,
		Parent = logo,
	})
	self:_bind(logoHole, "BackgroundColor3", "Background")
	corner(logoHole, 1)
	local pillLabel = newLabel({
		Name = "Label",
		Position = UDim2.fromOffset(44, 0),
		Size = UDim2.new(1, -52, 1, 0),
		Text = pillText,
		FontFace = fontFace,
		TextSize = TEXT_SIZE,
		Parent = pillBody,
	})
	self:_bind(pillLabel, "TextColor3", "TextBright")
	local pillButton = newButton({
		Name = "Hitbox",
		Size = UDim2.fromScale(1, 1),
		ZIndex = 20,
		Parent = pillBody,
	})
	self._pill = pill
	self._pillBody = pillBody
	self._pillScale = pillScale

	self:_connect(pillButton.MouseEnter, function()
		apply(pillBody, { BackgroundColor3 = self.Theme.Element }, false, Ease.Fast)
	end)
	self:_connect(pillButton.MouseLeave, function()
		apply(pillBody, { BackgroundColor3 = self.Theme.Background }, false, Ease.Fast)
	end)

	self:_connect(topbar.InputBegan, function(input)
		if not isPointer(input) or self.Minimized or self._closing then
			return
		end
		if self._rootTween then
			self._rootTween:Cancel()
		end
		local half = Vector2.new(size.X, size.Y) * fit.Scale / 2
		local startCenter = toOffset(root.Position, gui.AbsoluteSize)
		startDrag(input, function(position, reference)
			local screen = gui.AbsoluteSize
			local target = startCenter + (position - reference)
			local x = math.clamp(target.X, 60 - half.X, math.max(60 - half.X, screen.X - 60 + half.X))
			local y = math.clamp(target.Y, half.Y, math.max(half.Y, screen.Y - 40 + half.Y))
			root.Position = UDim2.fromOffset(x, y)
		end)
	end)

	self:_connect(pillButton.InputBegan, function(input)
		if not isPointer(input) then
			return
		end
		local half = Vector2.new(pillWidth, 40) / 2
		local startCenter = toOffset(pill.Position, gui.AbsoluteSize)
		local moved = false
		startDrag(input, function(position, reference)
			local delta = position - reference
			if not moved and delta.Magnitude < 6 then
				return
			end
			moved = true
			local screen = gui.AbsoluteSize
			local target = startCenter + delta
			local x = math.clamp(target.X, half.X, math.max(half.X, screen.X - half.X))
			local y = math.clamp(target.Y, half.Y, math.max(half.Y, screen.Y - half.Y))
			pill.Position = UDim2.fromOffset(x, y)
		end, function()
			if not moved then
				self:Restore()
			end
		end)
	end)

	self:_connect(UserInputService.InputBegan, function(input, processed)
		if processed or self._listening or not self.ToggleKey then
			return
		end
		if input.KeyCode == self.ToggleKey then
			self:Toggle()
		end
	end)

	apply(introScale, { Scale = 1 }, false, Ease.Pop)
	apply(body, { GroupTransparency = 0 }, false, Ease.Slow)
	apply(sweep, { Size = UDim2.new(1, 0, 0, 1) }, false, TweenInfo.new(0.9, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut))
	task.delay(0.9, function()
		if self._destroyed then
			return
		end
		apply(sweep, { BackgroundTransparency = 1 }, false, Ease.Slow)
	end)
	task.delay(0.1, function()
		if self._destroyed then
			return
		end
		apply(sidebar, { Position = UDim2.fromOffset(12, 46) }, false, Ease.Slow)
		apply(content, { Position = UDim2.fromOffset(124, 46) }, false, Ease.Slow)
		apply(contentBorder, { Position = UDim2.fromOffset(124, 46) }, false, Ease.Slow)
	end)
	task.spawn(function()
		local total = utf8.len(self.Title) or #self.Title
		for index = 1, total do
			if self._destroyed then
				return
			end
			titleLabel.MaxVisibleGraphemes = index
			task.wait(0.05)
		end
		if not self._destroyed then
			titleLabel.MaxVisibleGraphemes = -1
		end
	end)

	return self
end

return Xyloria
