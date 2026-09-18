local Library = { Flags = {}, Version = "1.0.0" }

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

----------------------------------------------------------------------
-- Theme
----------------------------------------------------------------------
local WHITE = Color3.new(1, 1, 1)
local Theme = {
	Font = Enum.Font.SourceSans,
	FontBold = Enum.Font.SourceSansBold,
	Text = Color3.fromRGB(16, 62, 96),
	Aqua = Color3.fromRGB(0, 190, 235),
	AquaDark = Color3.fromRGB(0, 125, 175),
	Green = Color3.fromRGB(110, 214, 70),
	Off = Color3.fromRGB(150, 185, 205),
	Danger = Color3.fromRGB(240, 90, 80),
	Outline = Color3.fromRGB(0, 90, 140),
}
Library.Theme = Theme

----------------------------------------------------------------------
-- Helpers
----------------------------------------------------------------------
local function tween(obj, props, t, style, dir)
	local tw = TweenService:Create(obj, TweenInfo.new(t or 0.2, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local function new(class, props, children)
	local o = Instance.new(class)
	local parent
	for k, v in pairs(props or {}) do
		if k == "Parent" then parent = v else o[k] = v end
	end
	for _, c in ipairs(children or {}) do c.Parent = o end
	if parent then o.Parent = parent end
	return o
end

local function corner(r) return new("UICorner", { CornerRadius = UDim.new(0, r) }) end

local function stroke(color, transparency, thickness)
	return new("UIStroke", {
		Color = color or WHITE, Transparency = transparency or 0.3, Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

local function gradient(c0, c1, rotation)
	return new("UIGradient", { Color = ColorSequence.new(c0, c1), Rotation = rotation or 90 })
end

-- glossy highlight on the upper half (the signature Aero look)
local function gloss(parent, radius, t0, t1)
	return new("Frame", {
		Name = "Gloss", BackgroundColor3 = WHITE, BorderSizePixel = 0, Active = false,
		Position = UDim2.fromOffset(2, 2), Size = UDim2.new(1, -4, 0.5, -2), Parent = parent,
	}, {
		corner(math.max(radius - 2, 0)),
		new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(t0 or 0.45, t1 or 0.9) }),
	})
end

local function textStroke(transparency)
	return new("UIStroke", { Color = Theme.Outline, Transparency = transparency or 0.55, Thickness = 1.2 })
end

local function safe(fn, ...)
	if type(fn) ~= "function" then return end
	local args = table.pack(...)
	task.spawn(function()
		local ok, err = pcall(fn, table.unpack(args, 1, args.n))
		if not ok then warn("[FrutigerAero] callback error: " .. tostring(err)) end
	end)
end

local function setFlag(cfg, value)
	if cfg and cfg.Flag then Library.Flags[cfg.Flag] = value end
end

local function mount(gui)
	if gethui then
		local ok, h = pcall(gethui)
		if ok and h then gui.Parent = h return end
	end
	local ok = pcall(function() gui.Parent = game:GetService("CoreGui") end)
	if ok and gui.Parent then return end
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

----------------------------------------------------------------------
-- Element builders (methods of a Category)
----------------------------------------------------------------------
local Elements = {}
Elements.__index = Elements

local function order(self, inst)
	self._n += 1
	inst.LayoutOrder = self._n
	return inst
end

local function row(self, height, name)
	local r = order(self, new("Frame", {
		Name = name or "Row", Size = UDim2.new(1, 0, 0, height), BackgroundColor3 = WHITE,
		BackgroundTransparency = 0.35, BorderSizePixel = 0, Parent = self.Page,
	}, { corner(10), stroke(WHITE, 0.2, 1) }))
	gloss(r, 10, 0.55, 1)
	return r
end

local function rowLabel(r, str, reserve)
	return new("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -(12 + (reserve or 60)), 0, 38), Text = str, Font = Theme.Font,
		TextSize = 19, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd, Parent = r,
	})
end

function Elements:AddSection(name)
	local f = order(self, new("Frame", { Name = "Section", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 28), Parent = self.Page }))
	new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 22), Text = name or "Section", Font = Theme.FontBold,
		TextSize = 17, TextColor3 = Theme.AquaDark, TextXAlignment = Enum.TextXAlignment.Left, Parent = f,
	})
	new("Frame", {
		AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 2),
		BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = f,
	}, { corner(2), new("UIGradient", { Color = ColorSequence.new(Theme.Aqua, Theme.Green), Transparency = NumberSequence.new(0, 1) }) })
end

function Elements:AddLabel(str)
	local l = order(self, new("TextLabel", {
		Name = "Label", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		TextWrapped = true, Text = str or "", Font = Theme.Font, TextSize = 18, TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Parent = self.Page,
	}))
	local obj = { Instance = l }
	function obj:Set(t) l.Text = t end
	return obj
end

function Elements:AddButton(cfg)
	cfg = cfg or {}
	local b = order(self, new("TextButton", {
		Name = "Button", Text = "", AutoButtonColor = false, Size = UDim2.new(1, 0, 0, 38),
		BackgroundColor3 = Theme.Aqua, BackgroundTransparency = 0.1, BorderSizePixel = 0, Parent = self.Page,
	}, { corner(10), stroke(WHITE, 0.15, 1.5), gradient(WHITE, Color3.fromRGB(200, 215, 225), 90) }))
	gloss(b, 10, 0.4, 0.85)
	local label = new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Text = cfg.Name or "Button",
		Font = Theme.FontBold, TextSize = 19, TextColor3 = WHITE, Parent = b,
	}, { textStroke() })
	b.MouseEnter:Connect(function() tween(b, { BackgroundColor3 = Theme.Green }, 0.15) end)
	b.MouseLeave:Connect(function() tween(b, { BackgroundColor3 = Theme.Aqua }, 0.15) end)
	b.MouseButton1Click:Connect(function()
		b.BackgroundTransparency = 0.4
		tween(b, { BackgroundTransparency = 0.1 }, 0.25)
		safe(cfg.Callback)
	end)
	local obj = { Instance = b }
	function obj:SetText(t) label.Text = t end
	return obj
end

function Elements:AddToggle(cfg)
	cfg = cfg or {}
	local state = cfg.Default == true
	local r = row(self, 38, "Toggle")
	rowLabel(r, cfg.Name or "Toggle", 70)
	local track = new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(46, 24),
		BackgroundColor3 = Theme.Off, BorderSizePixel = 0, Parent = r,
	}, { corner(999), stroke(WHITE, 0.2, 1.5), gradient(Color3.fromRGB(225, 235, 245), WHITE, 90) })
	local knob = new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0), Size = UDim2.fromOffset(18, 18),
		BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = track,
	}, { corner(999), stroke(Theme.Aqua, 0.5, 1) })

	local function set(v, silent)
		state = v and true or false
		tween(track, { BackgroundColor3 = state and Theme.Green or Theme.Off }, 0.2)
		tween(knob, { Position = state and UDim2.new(0, 25, 0.5, 0) or UDim2.new(0, 3, 0.5, 0) }, 0.2, Enum.EasingStyle.Back)
		setFlag(cfg, state)
		if not silent then safe(cfg.Callback, state) end
	end
	set(state, true)

	local hit = new("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = r })
	hit.MouseButton1Click:Connect(function() set(not state) end)

	local obj = { Instance = r }
	function obj:Set(v) set(v) end
	function obj:Get() return state end
	return obj
end

function Elements:AddSlider(cfg)
	cfg = cfg or {}
	local min, max = cfg.Min or 0, cfg.Max or 100
	local inc = cfg.Increment or 1
	local value = math.clamp(cfg.Default or min, min, max)
	local r = row(self, 56, "Slider")
	new("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 4), Size = UDim2.new(1, -110, 0, 24), Text = cfg.Name or "Slider",
		Font = Theme.Font, TextSize = 19, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = r,
	})
	local valLabel = new("TextLabel", {
		BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 4), Size = UDim2.fromOffset(90, 24),
		Text = "", Font = Theme.FontBold, TextSize = 18, TextColor3 = Theme.AquaDark, TextXAlignment = Enum.TextXAlignment.Right, Parent = r,
	})
	local bar = new("Frame", {
		Position = UDim2.new(0, 14, 0, 38), Size = UDim2.new(1, -28, 0, 8), BackgroundColor3 = Theme.Off,
		BackgroundTransparency = 0.4, BorderSizePixel = 0, Parent = r,
	}, { corner(999), stroke(WHITE, 0.3, 1) })
	local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = bar },
		{ corner(999), new("UIGradient", { Color = ColorSequence.new(Theme.Aqua, Theme.Green), Rotation = 0 }) })
	local knob = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(18, 18),
		BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = bar,
	}, { corner(999), stroke(Theme.Aqua, 0.2, 2), gradient(WHITE, Color3.fromRGB(205, 225, 240), 90) })

	local function set(v, silent)
		v = math.clamp(math.floor((v - min) / inc + 0.5) * inc + min, min, max)
		value = math.floor(v * 1e6 + 0.5) / 1e6
		local a = (max - min) == 0 and 0 or (value - min) / (max - min)
		fill.Size = UDim2.new(a, 0, 1, 0)
		knob.Position = UDim2.new(a, 0, 0.5, 0)
		valLabel.Text = tostring(value) .. (cfg.Suffix or "")
		setFlag(cfg, value)
		if not silent then safe(cfg.Callback, value) end
	end
	set(value, true)

	local dragging = false
	local function fromX(x)
		local a = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
		set(min + (max - min) * a)
	end
	local hit = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 28), Size = UDim2.new(1, 0, 0, 28), Parent = r })
	hit.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			fromX(i.Position.X)
		end
	end)
	table.insert(self.Window._conns, UserInputService.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			fromX(i.Position.X)
		end
	end))
	table.insert(self.Window._conns, UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
	end))

	local obj = { Instance = r }
	function obj:Set(v) set(v) end
	function obj:Get() return value end
	return obj
end

function Elements:AddDropdown(cfg)
	cfg = cfg or {}
	local options = cfg.Options or {}
	local selected = cfg.Default
	local open = false
	local r = row(self, 38, "Dropdown")
	r.ClipsDescendants = true
	r.Gloss.Size = UDim2.new(1, -4, 0, 17)
	rowLabel(r, cfg.Name or "Dropdown", 170)
	local valueLabel = new("TextLabel", {
		BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -30, 0, 0), Size = UDim2.fromOffset(140, 38),
		Font = Theme.FontBold, TextSize = 18, TextColor3 = Theme.AquaDark, TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd, Text = "", Parent = r,
	})
	local arrow = new("TextLabel", {
		BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 0), Size = UDim2.fromOffset(20, 38),
		Text = "▼", Font = Theme.FontBold, TextSize = 12, TextColor3 = Theme.AquaDark, Parent = r,
	})
	local list = new("ScrollingFrame", {
		Position = UDim2.fromOffset(8, 42), Size = UDim2.new(1, -16, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Aqua, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = r,
	}, { new("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }) })
	local head = new("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 38), Parent = r })

	local buttons = {}
	local function paint()
		for opt, b in pairs(buttons) do
			local on = opt == selected
			b.BackgroundColor3 = on and Theme.Green or WHITE
			b.BackgroundTransparency = on and 0.15 or 0.5
			b.TextColor3 = on and WHITE or Theme.Text
		end
	end
	local function setOpen(v)
		open = v
		local h = math.min(#options * 31, 155)
		list.Size = UDim2.new(1, -16, 0, h)
		tween(r, { Size = UDim2.new(1, 0, 0, v and (38 + h + 12) or 38) }, 0.2)
		tween(arrow, { Rotation = v and 180 or 0 }, 0.2)
	end
	local function set(v, silent)
		selected = v
		valueLabel.Text = v ~= nil and tostring(v) or "Select..."
		paint()
		setFlag(cfg, v)
		if not silent then safe(cfg.Callback, v) end
	end
	local function build()
		for _, b in pairs(buttons) do b:Destroy() end
		buttons = {}
		for i, opt in ipairs(options) do
			local b = new("TextButton", {
				LayoutOrder = i, Size = UDim2.new(1, 0, 0, 28), AutoButtonColor = false, Text = tostring(opt),
				Font = Theme.Font, TextSize = 17, BorderSizePixel = 0, BackgroundColor3 = WHITE, Parent = list,
			}, { corner(8) })
			b.MouseButton1Click:Connect(function() set(opt); setOpen(false) end)
			buttons[opt] = b
		end
		paint()
	end
	build()
	set(selected, true)
	head.MouseButton1Click:Connect(function() setOpen(not open) end)

	local obj = { Instance = r }
	function obj:Set(v) set(v) end
	function obj:Get() return selected end
	function obj:Refresh(newOptions)
		options = newOptions or {}
		build()
		if open then setOpen(true) end
	end
	return obj
end

function Elements:AddTextbox(cfg)
	cfg = cfg or {}
	local r = row(self, 38, "Textbox")
	rowLabel(r, cfg.Name or "Textbox", 170)
	local box = new("TextBox", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(150, 26),
		BackgroundColor3 = WHITE, BackgroundTransparency = 0.2, BorderSizePixel = 0, ClearTextOnFocus = false,
		Text = cfg.Default or "", PlaceholderText = cfg.Placeholder or "Type here...", PlaceholderColor3 = Theme.Off,
		Font = Theme.Font, TextSize = 17, TextColor3 = Theme.Text, TextTruncate = Enum.TextTruncate.AtEnd, Parent = r,
	}, { corner(8), stroke(Theme.Aqua, 0.4, 1.2) })
	setFlag(cfg, box.Text)
	box.FocusLost:Connect(function(enter)
		setFlag(cfg, box.Text)
		safe(cfg.Callback, box.Text, enter)
	end)
	local obj = { Instance = r }
	function obj:Set(t) box.Text = t; setFlag(cfg, t) end
	function obj:Get() return box.Text end
	return obj
end

function Elements:AddKeybind(cfg)
	cfg = cfg or {}
	local key = cfg.Default
	local binding = false
	local r = row(self, 38, "Keybind")
	rowLabel(r, cfg.Name or "Keybind", 120)
	local btn = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(96, 26), AutoButtonColor = false,
		BackgroundColor3 = WHITE, BackgroundTransparency = 0.2, BorderSizePixel = 0, Font = Theme.FontBold, TextSize = 16,
		TextColor3 = Theme.AquaDark, Text = "", Parent = r,
	}, { corner(8), stroke(Theme.Aqua, 0.4, 1.2) })
	local function refresh() btn.Text = binding and "..." or (key and key.Name or "None") end
	refresh()
	setFlag(cfg, key)
	btn.MouseButton1Click:Connect(function() binding = true; refresh() end)
	table.insert(self.Window._conns, UserInputService.InputBegan:Connect(function(i, gp)
		if binding then
			if i.UserInputType == Enum.UserInputType.Keyboard then
				binding = false
				if i.KeyCode ~= Enum.KeyCode.Escape then
					key = i.KeyCode
					setFlag(cfg, key)
					safe(cfg.Changed, key)
				end
				refresh()
			end
		elseif not gp and key and i.KeyCode == key then
			safe(cfg.Callback, key)
		end
	end))
	local obj = { Instance = r }
	function obj:Set(k) key = k; setFlag(cfg, k); refresh() end
	function obj:Get() return key end
	return obj
end

----------------------------------------------------------------------
-- Window
----------------------------------------------------------------------
function Library:CreateWindow(cfg)
	cfg = cfg or {}
	local Window = { Categories = {}, _conns = {}, ToggleKey = cfg.ToggleKey or Enum.KeyCode.RightShift }
	local size = cfg.Size or UDim2.fromOffset(660, 440)

	local gui = new("ScreenGui", { Name = "FrutigerAeroUI", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999 })
	mount(gui)
	Window.Gui = gui

	local main = new("Frame", {
		Name = "Main", Size = size, Position = UDim2.new(0.5, -size.X.Offset / 2, 0.5, -size.Y.Offset / 2),
		BackgroundColor3 = WHITE, BorderSizePixel = 0, ClipsDescendants = true, Parent = gui,
	}, {
		corner(18), stroke(WHITE, 0.1, 2),
		new("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(105, 190, 255)),
				ColorSequenceKeypoint.new(0.55, Color3.fromRGB(140, 220, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(160, 240, 200)),
			}),
		}),
	})
	Window.Main = main

	-- decorative bubbles
	for _, b in ipairs({ { 0.86, 0.14, 130 }, { 0.08, 0.82, 100 }, { 0.62, 0.95, 70 }, { 0.4, 0.04, 44 }, { 0.97, 0.62, 56 } }) do
		new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(b[1], b[2]), Size = UDim2.fromOffset(b[3], b[3]),
			BackgroundColor3 = WHITE, BackgroundTransparency = 0.85, BorderSizePixel = 0, Parent = main,
		}, { corner(999), stroke(WHITE, 0.5, 1.5) })
	end
	gloss(main, 18, 0.55, 1).Size = UDim2.new(1, -4, 0.35, 0)

	-- title bar
	local titleBar = new("Frame", { Name = "TitleBar", Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1, Parent = main })
	new("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(18, 0), Size = UDim2.new(1, -110, 1, 0), Text = cfg.Title or "Frutiger Aero",
		Font = Theme.FontBold, TextSize = 23, TextColor3 = WHITE, TextXAlignment = Enum.TextXAlignment.Left, Parent = titleBar,
	}, { textStroke() })

	local function circleBtn(symbol, color, xOff)
		local b = new("TextButton", {
			Text = "", AutoButtonColor = false, BackgroundColor3 = color, BorderSizePixel = 0, Size = UDim2.fromOffset(24, 24),
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -xOff, 0.5, 0), Parent = titleBar,
		}, { corner(999), stroke(WHITE, 0.15, 1.5), gradient(WHITE, Color3.fromRGB(190, 205, 215), 90) })
		gloss(b, 999, 0.35, 0.85)
		new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Text = symbol, Font = Theme.FontBold, TextSize = 18, TextColor3 = WHITE, Parent = b })
		b.MouseEnter:Connect(function() tween(b, { BackgroundTransparency = 0.25 }, 0.15) end)
		b.MouseLeave:Connect(function() tween(b, { BackgroundTransparency = 0 }, 0.15) end)
		return b
	end
	local closeBtn = circleBtn("×", Theme.Danger, 14)
	local minBtn = circleBtn("–", Theme.Aqua, 44)

	-- body
	local body = new("Frame", { Name = "Body", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 44), Size = UDim2.new(1, 0, 1, -44), Parent = main })
	local sidebar = new("Frame", {
		Name = "Sidebar", Position = UDim2.fromOffset(10, 0), Size = UDim2.new(0, 170, 1, -10), BackgroundColor3 = WHITE,
		BackgroundTransparency = 0.55, BorderSizePixel = 0, Parent = body,
	}, { corner(14), stroke(WHITE, 0.25, 1.5) })
	gloss(sidebar, 14, 0.5, 1)
	local catList = new("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = sidebar,
	}, {
		new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
		new("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }),
	})
	local content = new("Frame", {
		Name = "Content", Position = UDim2.fromOffset(190, 0), Size = UDim2.new(1, -200, 1, -10), BackgroundColor3 = WHITE,
		BackgroundTransparency = 0.45, BorderSizePixel = 0, ClipsDescendants = true, Parent = body,
	}, { corner(14), stroke(WHITE, 0.25, 1.5) })

	-- drag
	local dragging, dragStart, startPos
	titleBar.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging, dragStart, startPos = true, i.Position, main.Position
			i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then dragging = false end end)
		end
	end)
	table.insert(Window._conns, UserInputService.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local d = i.Position - dragStart
			main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end))

	-- toggle key
	table.insert(Window._conns, UserInputService.InputBegan:Connect(function(i, gp)
		if not gp and i.KeyCode == Window.ToggleKey then main.Visible = not main.Visible end
	end))

	-- collapse / close
	local collapsed = false
	minBtn.MouseButton1Click:Connect(function()
		collapsed = not collapsed
		if collapsed then
			tween(main, { Size = UDim2.new(size.X.Scale, size.X.Offset, 0, 44) }, 0.25)
			task.delay(0.2, function() if collapsed then body.Visible = false end end)
		else
			body.Visible = true
			tween(main, { Size = size }, 0.25)
		end
	end)
	closeBtn.MouseButton1Click:Connect(function() Window:Destroy() end)

	-- category selection
	local function select(cat)
		Window.Current = cat
		for _, c in ipairs(Window.Categories) do
			local on = c == cat
			c.Page.Visible = on
			tween(c.Button, { BackgroundColor3 = on and Theme.Green or WHITE, BackgroundTransparency = on and 0.05 or 0.5 }, 0.2)
			c.Label.TextColor3 = on and WHITE or Theme.Text
			c.LabelStroke.Transparency = on and 0.55 or 1
		end
	end

	function Window:AddCategory(name, icon)
		local cat = setmetatable({ Window = Window, _n = 0 }, Elements)
		local btn = new("TextButton", {
			Name = name, Text = "", AutoButtonColor = false, LayoutOrder = #Window.Categories + 1, Size = UDim2.new(1, 0, 0, 38),
			BackgroundColor3 = WHITE, BackgroundTransparency = 0.5, BorderSizePixel = 0, Parent = catList,
		}, { corner(12), stroke(WHITE, 0.3, 1.2), gradient(WHITE, Color3.fromRGB(205, 220, 232), 90) })
		gloss(btn, 12, 0.5, 0.95)
		if icon then
			if string.find(icon, "rbxasset") then
				new("ImageLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0.5, -10), Size = UDim2.fromOffset(20, 20), Image = icon, Parent = btn })
			else
				new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(8, 0), Size = UDim2.new(0, 24, 1, 0), Text = icon, TextSize = 18, Font = Theme.Font, TextColor3 = Theme.Text, Parent = btn })
			end
		end
		local label = new("TextLabel", {
			BackgroundTransparency = 1, Position = UDim2.fromOffset(icon and 38 or 14, 0), Size = UDim2.new(1, icon and -46 or -22, 1, 0),
			Text = name, Font = Theme.FontBold, TextSize = 19, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd, Parent = btn,
		})
		local lblStroke = new("UIStroke", { Color = Theme.Outline, Transparency = 1, Thickness = 1, Parent = label })

		local page = new("ScrollingFrame", {
			Name = name, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4,
			ScrollBarImageColor3 = Theme.Aqua, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false, Parent = content,
		}, {
			new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
			new("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 14) }),
		})
		cat.Page, cat.Button, cat.Label, cat.LabelStroke = page, btn, label, lblStroke
		order(cat, new("TextLabel", {
			BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 32), Text = name, Font = Theme.FontBold, TextSize = 27,
			TextColor3 = WHITE, TextXAlignment = Enum.TextXAlignment.Left, Parent = page,
		}, { textStroke(0.45) }))

		btn.MouseEnter:Connect(function() if Window.Current ~= cat then tween(btn, { BackgroundTransparency = 0.3 }, 0.15) end end)
		btn.MouseLeave:Connect(function() if Window.Current ~= cat then tween(btn, { BackgroundTransparency = 0.5 }, 0.15) end end)
		btn.MouseButton1Click:Connect(function() select(cat) end)

		table.insert(Window.Categories, cat)
		if #Window.Categories == 1 then select(cat) end
		return cat
	end

	function Window:Toggle() main.Visible = not main.Visible end
	function Window:SetToggleKey(k) Window.ToggleKey = k end
	function Window:Destroy()
		for _, c in ipairs(Window._conns) do c:Disconnect() end
		gui:Destroy()
	end

	return Window
end

----------------------------------------------------------------------
-- Notifications
----------------------------------------------------------------------
local notifyGui, notifyHolder
local notifyCount = 0

function Library:Notify(cfg)
	cfg = cfg or {}
	if not notifyGui or not notifyGui.Parent then
		notifyGui = new("ScreenGui", { Name = "FrutigerAeroNotify", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 1000 })
		mount(notifyGui)
		notifyHolder = new("Frame", {
			AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -16), Size = UDim2.fromOffset(290, 400), BackgroundTransparency = 1, Parent = notifyGui,
		}, { new("UIListLayout", { VerticalAlignment = Enum.VerticalAlignment.Bottom, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }) })
	end
	notifyCount += 1
	local slot = new("Frame", { LayoutOrder = notifyCount, Size = UDim2.new(1, 0, 0, 68), BackgroundTransparency = 1, Parent = notifyHolder })
	local card = new("Frame", {
		Position = UDim2.new(1, 320, 0, 0), Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = slot,
	}, { corner(12), stroke(WHITE, 0.1, 1.5), gradient(Color3.fromRGB(150, 225, 255), Color3.fromRGB(175, 242, 205), 90) })
	gloss(card, 12, 0.4, 0.9)
	new("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 6), Size = UDim2.new(1, -28, 0, 22), Text = cfg.Title or "Notification",
		Font = Theme.FontBold, TextSize = 19, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = card,
	})
	new("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 28), Size = UDim2.new(1, -28, 0, 34), Text = cfg.Content or "",
		Font = Theme.Font, TextSize = 16, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true, TextTruncate = Enum.TextTruncate.AtEnd, Parent = card,
	})
	tween(card, { Position = UDim2.new(0, 0, 0, 0) }, 0.4, Enum.EasingStyle.Back)
	task.delay(cfg.Duration or 4, function()
		tween(card, { Position = UDim2.new(1, 320, 0, 0) }, 0.3)
		task.wait(0.35)
		slot:Destroy()
	end)
end

return Library
