--!nonstrict
-- ESP library with Luau type annotations + modern idioms.
-- Modern techniques used:
--   * `next, t` iteration (faster than `pairs`, no iterator closure)
--   * Generalized iteration (`for k, v in t do`) for non-hot paths
--   * String interpolation (backticks)
--   * if-then-else expressions
--   * Compound assignment (+=, -=)
--   * `continue` statement
--   * Typed tables / function signatures

export type DrawingObject = any -- Drawing API is exploit-provided, not in Roblox typings

export type ContainerKind = "Players" | "Workspace"

export type ContainerSelector = ContainerKind | Instance | { Instance }

export type ESP = {
	-- state
	active: boolean,
	maxdist: number,
	container: Instance?,
	containers: { Instance },

	-- 2D options
	showbox: boolean,
	showcorners: boolean,
	showname: boolean,
	showheld: boolean,
	showtracer: boolean,
	showquad: boolean,
	teamcolor: boolean,
	showhealth: boolean,
	showdistance: boolean,
	showchams: boolean,
	showhealthbar: boolean,
	performancemode: boolean,

	-- 3D options
	showskeleton: boolean,
	show3dbox: boolean,

	-- colors
	boxcolor: Color3,
	cornercolor: Color3,
	namecolor: Color3,
	tracercolor: Color3,
	quadcolor: Color3,
	healthtextcolor: Color3,
	distancecolor: Color3,
	chamscolor: Color3,
	healthbarcoloroverride: Color3?,

	tracerThickness: number,
	boxWidthScale: number,
	boxHeightScale: number,

	-- lifecycle
	enable: (self: ESP) -> (),
	disable: (self: ESP) -> (),

	-- container selection
	setContainer: (self: ESP, container: Instance?) -> (),
	setContainers: (self: ESP, containers: { Instance }) -> (),
	selectContainer: (self: ESP, selector: ContainerSelector) -> (),

	-- 2D toggles
	box: (self: ESP, v: boolean) -> (),
	corners: (self: ESP, v: boolean) -> (),
	name: (self: ESP, v: boolean) -> (),
	held: (self: ESP, v: boolean) -> (),
	tracer: (self: ESP, v: boolean) -> (),
	quad: (self: ESP, v: boolean) -> (),
	dist: (self: ESP, d: number) -> (),
	team: (self: ESP, v: boolean) -> (),
	health: (self: ESP, v: boolean) -> (),
	distance: (self: ESP, v: boolean) -> (),
	chams: (self: ESP, v: boolean) -> (),
	healthbar: (self: ESP, v: boolean) -> (),
	performance: (self: ESP, v: boolean) -> (),

	-- 3D toggles
	skeleton: (self: ESP, v: boolean) -> (),
	box3d: (self: ESP, v: boolean) -> (),

	-- color setters
	setBoxColor: (self: ESP, c: Color3) -> (),
	setCornerColor: (self: ESP, c: Color3) -> (),
	setNameColor: (self: ESP, c: Color3) -> (),
	setTracerColor: (self: ESP, c: Color3) -> (),
	setQuadColor: (self: ESP, c: Color3) -> (),
	setHealthTextColor: (self: ESP, c: Color3) -> (),
	setDistanceColor: (self: ESP, c: Color3) -> (),
	setChamsColor: (self: ESP, c: Color3) -> (),
	setHealthbarColor: (self: ESP, c: Color3?) -> (),

	-- sizing setters
	setTracerThickness: (self: ESP, v: number) -> (),
	setBoxSize: (self: ESP, widthScale: number?, heightScale: number?) -> (),

	clear: (self: ESP) -> (),
}

return function(): ESP
	local get: (x: any) -> any = (if typeof(cloneref) == "function" then cloneref else function(x: any): any return x end) :: (any) -> any

	local players: Players = get(game:GetService("Players"))
	local rs: RunService = get(game:GetService("RunService"))
	local core = get(game:GetService("CoreGui"))
	local parent: Folder = Instance.new("Folder")
	parent.Parent = core
	parent.Name = tostring(math.random(1e9, 2e9))
	local ws: Workspace = get(game:GetService("Workspace"))
	local cam: Camera = ws.CurrentCamera
	local lp: Player = players.LocalPlayer

	local esp: ESP = {} :: ESP
	esp.active = false
	esp.maxdist = 2000
	esp.container = players
	esp.containers = { players }

	-- 2D options
	esp.showbox = true
	esp.showcorners = true
	esp.showname = true
	esp.showheld = true
	esp.showtracer = true
	esp.showquad = false
	esp.teamcolor = false
	esp.showhealth = false
	esp.showdistance = false
	esp.showchams = false
	esp.showhealthbar = false
	esp.performancemode = false

	-- 3D options
	esp.showskeleton = false
	esp.show3dbox = false

	esp.boxcolor = Color3.fromRGB(255, 255, 255)
	esp.cornercolor = Color3.fromRGB(255, 255, 255)
	esp.namecolor = Color3.fromRGB(255, 255, 255)
	esp.tracercolor = Color3.fromRGB(255, 255, 255)
	esp.quadcolor = Color3.fromRGB(255, 255, 255)
	esp.healthtextcolor = Color3.fromRGB(0, 255, 0)
	esp.distancecolor = Color3.fromRGB(255, 255, 255)
	esp.chamscolor = Color3.fromRGB(255, 255, 255)
	esp.healthbarcoloroverride = nil

	esp.tracerThickness = 1
	esp.boxWidthScale = 0.6
	esp.boxHeightScale = 1

	-- per-target drawing storage (Instance -> DrawingObject | {DrawingObject})
	local boxes: { [Instance]: DrawingObject } = {}
	local names: { [Instance]: DrawingObject } = {}
	local tracers: { [Instance]: DrawingObject } = {}
	local quads: { [Instance]: DrawingObject } = {}
	local healths: { [Instance]: DrawingObject } = {}
	local distances: { [Instance]: DrawingObject } = {}
	local chams: { [Instance]: Highlight } = {}
	local healthbars: { [Instance]: DrawingObject } = {}
	local corners: { [Instance]: { DrawingObject } } = {}
	local box3dLines: { [Instance]: { DrawingObject } } = {}
	local skeletonLines: { [Instance]: { DrawingObject } } = {}

	local tracked: { [Instance]: boolean } = {}
	local conns: { [Instance]: { RBXScriptConnection } } = {}

	local frameCount: number = 0
	local uInterval: number = 2
	local viewportSize: Vector2 = cam.ViewportSize

	local white: Color3 = Color3.fromRGB(255, 255, 255)
	local red: Color3 = Color3.fromRGB(255, 0, 0)
	local green: Color3 = Color3.fromRGB(0, 255, 0)
	local yellow: Color3 = Color3.fromRGB(255, 255, 0)
	local gray: Color3 = Color3.fromRGB(128, 128, 128)

	local containerAddedConns: { RBXScriptConnection } = {}
	local containerRemovedConns: { RBXScriptConnection } = {}

	-- Helper: is the Players service one of our active containers?
	local function isPlayerContainer(): boolean
		for _, c in esp.containers do
			if c == players then return true end
		end
		return false
	end

	local function isLocalTarget(target: Instance): boolean
		return isPlayerContainer() and target == lp
	end

	local function createDrawing(tp: string, properties: { [string]: any }): DrawingObject
		local d: DrawingObject = Drawing.new(tp)
		for k, v in next, properties do
			d[k] = v
		end
		return d
	end

	local function getColor(health: number, maxhealth: number): Color3
		if maxhealth <= 0 then
			return red
		end
		local percentage: number = health / maxhealth
		return if percentage > 0.7 then green
			elseif percentage > 0.3 then yellow
			else red
	end

	local function getCharacterFromTarget(target: Instance): Model?
		if target == players then
			-- shouldn't happen, but guard anyway
			return nil
		end
		if target:IsA("Player") then
			return target.Character
		end
		if target:IsA("Model") then
			return target
		end
		return nil
	end

	local function getparts(target: Instance): (Model?, BasePart?, BasePart?, Humanoid?)
		local ch: Model? = getCharacterFromTarget(target)
		if not ch then return nil, nil, nil, nil end

		local hrp: BasePart? = ch:FindFirstChild("HumanoidRootPart") :: BasePart?
		local head: BasePart? = (ch:FindFirstChild("Head") or ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("Torso")) :: BasePart?
		local humanoid: Humanoid? = ch:FindFirstChildOfClass("Humanoid")
		if hrp and head then
			return ch, hrp, head, humanoid
		end
		return nil, nil, nil, nil
	end

	local function hideTarget(target: Instance): ()
		if boxes[target] then boxes[target].Visible = false end
		if corners[target] then
			for _, ln in next, corners[target] do ln.Visible = false end
		end
		if names[target] then names[target].Visible = false end
		if tracers[target] then tracers[target].Visible = false end
		if quads[target] then quads[target].Visible = false end
		if healths[target] then healths[target].Visible = false end
		if distances[target] then distances[target].Visible = false end
		if healthbars[target] then healthbars[target].Visible = false end
		if box3dLines[target] then
			for _, ln in next, box3dLines[target] do ln.Visible = false end
		end
		if skeletonLines[target] then
			for _, ln in next, skeletonLines[target] do ln.Visible = false end
		end
		if chams[target] then chams[target].Enabled = false end
	end

	local function cleanupTarget(target: Instance): ()
		local t = conns[target]
		if t then
			for _, c in next, t do
				if c and c.Disconnect then c:Disconnect() end
			end
		end
		conns[target] = nil

		local storages = { boxes, names, tracers, quads, healths, distances, healthbars, corners, box3dLines, skeletonLines }
		for _, storage in next, storages do
			local obj = storage[target]
			if obj then
				if typeof(obj) == "table" then
					for _, v in next, obj :: { DrawingObject } do
						if v and v.Remove then v:Remove() end
					end
				else
					if obj and obj.Remove then (obj :: DrawingObject):Remove() end
				end
			end
			storage[target] = nil
		end

		if chams[target] then
			chams[target]:Destroy()
			chams[target] = nil
		end

		tracked[target] = nil
	end

	local function newbox(target: Instance): ()
		boxes[target] = createDrawing("Square", {
			Thickness = 2, Filled = false, Transparency = 1,
			Color = esp.boxcolor, Visible = false,
		})
	end

	local function newcorners(target: Instance): ()
		local t: { DrawingObject } = table.create(8)
		for i = 1, 8 do
			t[i] = createDrawing("Line", {
				Thickness = 2, Transparency = 1,
				Color = esp.cornercolor, Visible = false,
			})
		end
		corners[target] = t
	end

	local function newname(target: Instance): ()
		names[target] = createDrawing("Text", {
			Size = 16, Center = true, Outline = true, Font = 2,
			Color = esp.namecolor, Visible = false,
		})
	end

	local function newtracer(target: Instance): ()
		tracers[target] = createDrawing("Line", {
			Thickness = esp.tracerThickness, Color = esp.tracercolor, Visible = false,
		})
	end

	local function newquad(target: Instance): ()
		quads[target] = createDrawing("Quad", {
			Color = esp.quadcolor, Visible = false, Thickness = 1,
		})
	end

	local function newhealth(target: Instance): ()
		healths[target] = createDrawing("Text", {
			Size = 14, Center = true, Outline = true, Font = 2,
			Color = esp.healthtextcolor, Visible = false,
		})
	end

	local function newdistance(target: Instance): ()
		distances[target] = createDrawing("Text", {
			Size = 14, Center = true, Outline = true, Font = 2,
			Color = esp.distancecolor, Visible = false,
		})
	end

	local function newchams(target: Instance): ()
		local highlight: Highlight = Instance.new("Highlight")
		highlight.FillTransparency = 0.7
		highlight.OutlineTransparency = 1
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		highlight.Enabled = false
		highlight.Parent = parent
		chams[target] = highlight
	end

	local function newhealthbar(target: Instance): ()
		healthbars[target] = createDrawing("Line", {
			Thickness = 3,
			Color = esp.healthbarcoloroverride or green,
			Visible = false,
		})
	end

	local function new3dbox(target: Instance): ()
		local t: { DrawingObject } = table.create(12)
		for i = 1, 12 do
			t[i] = createDrawing("Line", {
				Thickness = 1, Color = esp.boxcolor, Visible = false,
			})
		end
		box3dLines[target] = t
	end

	local function newskeleton(target: Instance): ()
		local t: { DrawingObject } = table.create(15)
		for i = 1, 15 do
			t[i] = createDrawing("Line", {
				Thickness = 1, Color = esp.boxcolor, Visible = false,
			})
		end
		skeletonLines[target] = t
	end

	local function trackTarget(target: Instance): ()
		if tracked[target] then return end
		if isLocalTarget(target) then return end

		tracked[target] = true

		newbox(target)
		newcorners(target)
		newname(target)
		newtracer(target)
		newquad(target)
		newhealth(target)
		newdistance(target)
		newchams(target)
		newhealthbar(target)
		new3dbox(target)
		newskeleton(target)

		conns[target] = conns[target] or {}

		if target:IsA("Player") and target.CharacterRemoving then
			table.insert(conns[target], target.CharacterRemoving:Connect(function()
				hideTarget(target)
			end))
		end
	end

	local function untrackTarget(target: Instance): ()
		cleanupTarget(target)
	end

	local function detachContainerListeners(): ()
		for _, c in next, containerAddedConns do c:Disconnect() end
		for _, c in next, containerRemovedConns do c:Disconnect() end
		table.clear(containerAddedConns)
		table.clear(containerRemovedConns)
	end

	local function attachContainerListeners(): ()
		detachContainerListeners()

		for _, container in next, esp.containers do
			if container == players then
				table.insert(containerAddedConns, players.PlayerAdded:Connect(trackTarget))
				table.insert(containerRemovedConns, players.PlayerRemoving:Connect(untrackTarget))
			elseif container:IsA("Instance") then
				table.insert(containerAddedConns, container.ChildAdded:Connect(trackTarget))
				table.insert(containerRemovedConns, container.ChildRemoved:Connect(untrackTarget))
			end
		end
	end

	-- Resolve a selector to a deduplicated list of container Instances.
	local function resolveSelector(selector: ContainerSelector): { Instance }
		local resolved: { Instance } = {}

		if typeof(selector) == "string" then
			if selector == "Players" then
				table.insert(resolved, players)
			elseif selector == "Workspace" then
				table.insert(resolved, workspace)
			end
		elseif typeof(selector) == "Instance" then
			table.insert(resolved, selector)
		elseif typeof(selector) == "table" then
			for _, item in selector :: { Instance } do
				if typeof(item) == "Instance" then
					-- dedupe
					local already = false
					for _, r in next, resolved do
						if r == item then already = true break end
					end
					if not already then table.insert(resolved, item) end
				end
			end
		end

		return resolved
	end

	local function seedFromContainers(): ()
		for _, container in next, esp.containers do
			if container == players then
				for _, p in next, players:GetPlayers() do
					trackTarget(p)
				end
			elseif container:IsA("Instance") then
				for _, child in next, container:GetChildren() do
					trackTarget(child)
				end
			end
		end
	end

	local function applyContainers(containers: { Instance }): ()
		-- wipe existing
		for target in next, tracked do
			cleanupTarget(target)
		end

		esp.containers = containers
		esp.container = if #containers > 0 then containers[1] else nil

		seedFromContainers()
		attachContainerListeners()
	end

	-- Public: select what to loop over.
	--   esp:selectContainer("Players")
	--   esp:selectContainer("Workspace")
	--   esp:selectContainer(workspace:FindFirstChild("Enemies"))
	--   esp:selectContainer({ workspace:FindFirstChild("Enemies"), workspace:FindFirstChild("NPCs") })
	-- You can also mix: esp:selectContainer({ "Players", workspace.NPCs })
	function esp:selectContainer(selector: ContainerSelector): ()
		-- Normalize mixed lists (strings + Instances) into Instance list.
		local mixed: { any } = if typeof(selector) == "table" then selector :: { any } else { selector }
		local normalized: { Instance } = {}
		for _, item in next, mixed do
			if typeof(item) == "string" then
				if item == "Players" then table.insert(normalized, players)
				elseif item == "Workspace" then table.insert(normalized, workspace) end
			elseif typeof(item) == "Instance" then
				table.insert(normalized, item)
			end
		end
		applyContainers(normalized)
	end

	function esp:setContainer(container: Instance?): ()
		if container == nil then container = players end
		applyContainers({ container })
	end

	function esp:setContainers(containers: { Instance }): ()
		applyContainers(containers)
	end

	-- initial seed
	applyContainers({ players })

	-- Skeleton joint table keyed by name.
	type JointMap = { [string]: Vector3 }

	local function getJointPositions(ch: Model): JointMap
		local parts: { [string]: BasePart? } = {
			Head = ch:FindFirstChild("Head") :: BasePart?,
			Torso = (ch:FindFirstChild("Torso") or ch:FindFirstChild("UpperTorso")) :: BasePart?,
			LeftArm = (ch:FindFirstChild("Left Arm") or ch:FindFirstChild("LeftUpperArm")) :: BasePart?,
			RightArm = (ch:FindFirstChild("Right Arm") or ch:FindFirstChild("RightUpperArm")) :: BasePart?,
			LeftLeg = (ch:FindFirstChild("Left Leg") or ch:FindFirstChild("LeftUpperLeg")) :: BasePart?,
			RightLeg = (ch:FindFirstChild("Right Leg") or ch:FindFirstChild("RightUpperLeg")) :: BasePart?,
		}

		local pos: JointMap = {}
		for name, part in next, parts do
			if part then pos[name] = part.Position end
		end
		return pos
	end

	rs.RenderStepped:Connect(function()
		if not esp.active then return end

		frameCount += 1
		if esp.performancemode and frameCount % uInterval ~= 0 then return end

		viewportSize = cam.ViewportSize
		local cameraPos: Vector3 = cam.CFrame.Position

		-- Hot loop: use `next` directly to skip the pairs() closure allocation.
		for target, b in next, boxes do
			if not target or not target.Parent then
				cleanupTarget(target)
				continue
			end

			local ch, hrp, head, humanoid = getparts(target)
			if not ch or not hrp or not head then
				hideTarget(target)
				continue
			end

			local hrpPos, hrpOnScreen = cam:WorldToViewportPoint(hrp.Position)
			local headPos, headOnScreen = cam:WorldToViewportPoint(head.Position)
			local dist: number = (cameraPos - hrp.Position).Magnitude

			if dist > esp.maxdist then
				hideTarget(target)
				continue
			end

			local baseCol: Color3 = white
			if target:IsA("Player") and esp.teamcolor and target.Team ~= lp.Team then
				baseCol = red
			end
			if humanoid and humanoid.Health <= 0 then
				baseCol = gray
			end

			local height: number?, width: number?, boxLeft: number?, boxTop: number?
			if (esp.showbox or esp.showcorners) and hrpOnScreen and headOnScreen then
				height = math.abs(hrpPos.Y - headPos.Y) * (esp.boxHeightScale or 1)
				width = height * (esp.boxWidthScale or 0.6)
				boxLeft = hrpPos.X - width / 2
				boxTop = headPos.Y

				if esp.showbox then
					b.Size = Vector2.new(width, height)
					b.Position = Vector2.new(boxLeft, boxTop)
					b.Color = esp.boxcolor or baseCol
					b.Visible = true
				else
					b.Visible = false
				end
			else
				b.Visible = false
			end

			if esp.showcorners and hrpOnScreen and headOnScreen and height and width and boxLeft and boxTop then
				local c = corners[target]
				if c then
					local x1, y1 = boxLeft, boxTop
					local x2, y2 = boxLeft + width, boxTop
					local x3, y3 = boxLeft, boxTop + height
					local x4, y4 = boxLeft + width, boxTop + height

					local cornerLen: number = math.max(3, height * 0.2)
					local col: Color3 = esp.cornercolor or baseCol

					c[1].From = Vector2.new(x1, y1 + cornerLen); c[1].To = Vector2.new(x1, y1); c[1].Color = col; c[1].Visible = true
					c[2].From = Vector2.new(x1, y1); c[2].To = Vector2.new(x1 + cornerLen, y1); c[2].Color = col; c[2].Visible = true

					c[3].From = Vector2.new(x2, y2 + cornerLen); c[3].To = Vector2.new(x2, y2); c[3].Color = col; c[3].Visible = true
					c[4].From = Vector2.new(x2 - cornerLen, y2); c[4].To = Vector2.new(x2, y2); c[4].Color = col; c[4].Visible = true

					c[5].From = Vector2.new(x3, y3 - cornerLen); c[5].To = Vector2.new(x3, y3); c[5].Color = col; c[5].Visible = true
					c[6].From = Vector2.new(x3, y3); c[6].To = Vector2.new(x3 + cornerLen, y3); c[6].Color = col; c[6].Visible = true

					c[7].From = Vector2.new(x4, y4 - cornerLen); c[7].To = Vector2.new(x4, y4); c[7].Color = col; c[7].Visible = true
					c[8].From = Vector2.new(x4 - cornerLen, y4); c[8].To = Vector2.new(x4, y4); c[8].Color = col; c[8].Visible = true
				end
			elseif corners[target] then
				for _, ln in next, corners[target] do ln.Visible = false end
			end

			-- name + distance (string interpolation!)
			if (esp.showname or esp.showdistance) and headOnScreen then
				local nameText: string = ""
				local distanceText: string = ""

				if esp.showname then
					nameText = if typeof(target) == "Instance" then target.Name else "Target"
					if esp.showheld and target:IsA("Player") then
						local tool = ch:FindFirstChildOfClass("Tool") :: Tool?
						if tool then
							nameText = `{nameText} [{tool.Name}]`
						end
					end
				end

				if esp.showdistance then
					distanceText = `{math.floor(dist)} studs`
				end

				local combinedText: string = nameText
				if nameText ~= "" and distanceText ~= "" then
					combinedText = `{nameText} | {distanceText}`
				elseif distanceText ~= "" then
					combinedText = distanceText
				end

				local n = names[target]
				n.Position = Vector2.new(headPos.X, headPos.Y - 15)
				n.Text = combinedText
				n.Color = esp.namecolor or baseCol
				n.Visible = true
			elseif names[target] then
				names[target].Visible = false
			end

			-- tracer
			if esp.showtracer and hrpOnScreen then
				local tr = tracers[target]
				tr.From = Vector2.new(viewportSize.X / 2, viewportSize.Y)
				tr.To = Vector2.new(hrpPos.X, hrpPos.Y)
				tr.Color = esp.tracercolor or baseCol
				tr.Thickness = esp.tracerThickness or 1
				tr.Visible = true
			elseif tracers[target] then
				tracers[target].Visible = false
			end

			-- quad
			if esp.showquad and hrpOnScreen and headOnScreen then
				local q = quads[target]
				local heightQ: number = math.abs(hrpPos.Y - headPos.Y)
				local widthQ: number = heightQ * 0.6
				local halfWidth: number = widthQ / 2

				q.PointA = Vector2.new(hrpPos.X - halfWidth, headPos.Y)
				q.PointB = Vector2.new(hrpPos.X + halfWidth, headPos.Y)
				q.PointC = Vector2.new(hrpPos.X + halfWidth, hrpPos.Y)
				q.PointD = Vector2.new(hrpPos.X - halfWidth, hrpPos.Y)
				q.Color = esp.quadcolor or baseCol
				q.Visible = true
			elseif quads[target] then
				quads[target].Visible = false
			end

			-- health text
			if esp.showhealth and humanoid and headOnScreen then
				local htxt = healths[target]
				local healthText: string = `{math.floor(humanoid.Health)}/{math.floor(humanoid.MaxHealth)}`
				local healthCol: Color3 = esp.healthtextcolor or getColor(humanoid.Health, humanoid.MaxHealth)
				htxt.Position = Vector2.new(headPos.X, headPos.Y + 5)
				htxt.Text = healthText
				htxt.Color = healthCol
				htxt.Visible = true
			elseif healths[target] then
				healths[target].Visible = false
			end

			-- health bar
			if esp.showhealthbar and humanoid and hrpOnScreen and headOnScreen then
				local bar = healthbars[target]
				local heightHB: number = math.abs(hrpPos.Y - headPos.Y)
				local widthHB: number = heightHB * 0.6
				local boxLeftHB: number = hrpPos.X - widthHB / 2
				local boxTopHB: number = headPos.Y

				local maxH: number = humanoid.MaxHealth
				local hp: number = humanoid.Health
				local healthPercentage: number = if maxH > 0 then hp / maxH else 0
				local barHeight: number = heightHB * math.clamp(healthPercentage, 0, 1)
				local barColor: Color3 = esp.healthbarcoloroverride or getColor(hp, maxH)

				bar.From = Vector2.new(boxLeftHB - 6, boxTopHB + heightHB - barHeight)
				bar.To = Vector2.new(boxLeftHB - 6, boxTopHB + heightHB)
				bar.Color = barColor
				bar.Visible = true
			elseif healthbars[target] then
				healthbars[target].Visible = false
			end

			-- chams
			if esp.showchams then
				local cham = chams[target]
				if cham then
					cham.Adornee = ch
					cham.Enabled = true
					cham.FillColor = esp.chamscolor or baseCol
				end
			elseif chams[target] then
				chams[target].Enabled = false
			end

			-- 3D box
			if esp.show3dbox and box3dLines[target] then
				local lines = box3dLines[target]
				local size: Vector3 = hrp.Size * 1.5
				local cf: CFrame = hrp.CFrame

				local offsets: { Vector3 } = {
					Vector3.new(-size.X / 2,  size.Y / 2, -size.Z / 2),
					Vector3.new( size.X / 2,  size.Y / 2, -size.Z / 2),
					Vector3.new( size.X / 2,  size.Y / 2,  size.Z / 2),
					Vector3.new(-size.X / 2,  size.Y / 2,  size.Z / 2),
					Vector3.new(-size.X / 2, -size.Y / 2, -size.Z / 2),
					Vector3.new( size.X / 2, -size.Y / 2, -size.Z / 2),
					Vector3.new( size.X / 2, -size.Y / 2,  size.Z / 2),
					Vector3.new(-size.X / 2, -size.Y / 2,  size.Z / 2),
				}

				local points2d: { [number]: { Vector2, boolean } } = table.create(8)
				local onscreenAny: boolean = false

				for i = 1, 8 do
					local worldPos: Vector3 = (cf * CFrame.new(offsets[i])).Position
					local v2, onScreen = cam:WorldToViewportPoint(worldPos)
					points2d[i] = { Vector2.new(v2.X, v2.Y), onScreen }
					if onScreen then onscreenAny = true end
				end

				if onscreenAny then
					local col: Color3 = esp.boxcolor or baseCol

					local function setLine(idx: number, i1: number, i2: number): ()
						local entry1 = points2d[i1]
						local entry2 = points2d[i2]
						local p1: Vector2 = entry1[1]
						local o1: boolean = entry1[2]
						local p2: Vector2 = entry2[1]
						local o2: boolean = entry2[2]
						local ln = lines[idx]
						if o1 or o2 then
							ln.From = p1
							ln.To = p2
							ln.Color = col
							ln.Visible = true
						else
							ln.Visible = false
						end
					end

					setLine(1, 1, 2); setLine(2, 2, 3); setLine(3, 3, 4); setLine(4, 4, 1)
					setLine(5, 5, 6); setLine(6, 6, 7); setLine(7, 7, 8); setLine(8, 8, 5)
					setLine(9, 1, 5); setLine(10, 2, 6); setLine(11, 3, 7); setLine(12, 4, 8)
				else
					for _, ln in next, lines do ln.Visible = false end
				end
			elseif box3dLines[target] then
				for _, ln in next, box3dLines[target] do ln.Visible = false end
			end

			-- skeleton
			if esp.showskeleton and skeletonLines[target] then
				local lines = skeletonLines[target]
				local joints: JointMap = getJointPositions(ch)

				local function proj(name: string): (Vector2?, boolean)
					local pos = joints[name]
					if not pos then return nil, false end
					local v, onScreen = cam:WorldToViewportPoint(pos)
					return Vector2.new(v.X, v.Y), onScreen
				end

				local pairsDef: { { string } } = {
					{ "Head", "Torso" },
					{ "Torso", "LeftArm" },
					{ "Torso", "RightArm" },
					{ "Torso", "LeftLeg" },
					{ "Torso", "RightLeg" },
				}

				local idx: number = 1
				local col: Color3 = esp.boxcolor or baseCol

				for _, pair in next, pairsDef do
					local p1, o1 = proj(pair[1])
					local p2, o2 = proj(pair[2])
					local ln = lines[idx]
					idx += 1

					if p1 and p2 and (o1 or o2) then
						ln.From = p1 :: Vector2
						ln.To = p2 :: Vector2
						ln.Color = col
						ln.Visible = true
					else
						ln.Visible = false
					end
				end

				for i = idx, #lines do
					lines[i].Visible = false
				end
			elseif skeletonLines[target] then
				for _, ln in next, skeletonLines[target] do ln.Visible = false end
			end
		end
	end)

	function esp:enable(): ()
		self.active = true
	end

	function esp:disable(): ()
		self.active = false
		for target in next, tracked do
			hideTarget(target)
		end
	end

	-- 2D toggles
	function esp:box(v: boolean): () self.showbox = v end
	function esp:corners(v: boolean): () self.showcorners = v end
	function esp:name(v: boolean): () self.showname = v end
	function esp:held(v: boolean): () self.showheld = v end
	function esp:tracer(v: boolean): () self.showtracer = v end
	function esp:quad(v: boolean): () self.showquad = v end
	function esp:dist(d: number): () self.maxdist = d end
	function esp:team(v: boolean): () self.teamcolor = v end
	function esp:health(v: boolean): () self.showhealth = v end
	function esp:distance(v: boolean): () self.showdistance = v end
	function esp:chams(v: boolean): () self.showchams = v end
	function esp:healthbar(v: boolean): () self.showhealthbar = v end
	function esp:performance(v: boolean): () self.performancemode = v end

	-- 3D toggles
	function esp:skeleton(v: boolean): () self.showskeleton = v end
	function esp:box3d(v: boolean): () self.show3dbox = v end

	-- color setters
	function esp:setBoxColor(c: Color3): () self.boxcolor = c end
	function esp:setCornerColor(c: Color3): () self.cornercolor = c end
	function esp:setNameColor(c: Color3): () self.namecolor = c end
	function esp:setTracerColor(c: Color3): () self.tracercolor = c end
	function esp:setQuadColor(c: Color3): () self.quadcolor = c end
	function esp:setHealthTextColor(c: Color3): () self.healthtextcolor = c end
	function esp:setDistanceColor(c: Color3): () self.distancecolor = c end
	function esp:setChamsColor(c: Color3): () self.chamscolor = c end
	function esp:setHealthbarColor(c: Color3?): () self.healthbarcoloroverride = c end

	-- sizing setters
	function esp:setTracerThickness(v: number): () self.tracerThickness = v end
	function esp:setBoxSize(widthScale: number?, heightScale: number?): ()
		if widthScale then self.boxWidthScale = widthScale end
		if heightScale then self.boxHeightScale = heightScale end
	end

	function esp:clear(): ()
		for target in next, tracked do
			cleanupTarget(target)
		end
		table.clear(boxes); table.clear(names); table.clear(tracers); table.clear(quads)
		table.clear(healths); table.clear(distances); table.clear(chams); table.clear(healthbars)
		table.clear(corners); table.clear(box3dLines); table.clear(skeletonLines)
		table.clear(tracked); table.clear(conns)
		self.active = false
	end

	return esp
end
