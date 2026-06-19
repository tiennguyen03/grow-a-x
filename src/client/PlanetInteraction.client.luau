-- Planet interaction — approach prompt + inspect camera + info panel (Epic 4, 4A–4D).
--
-- Detects the local player's own Origin World (matched by the OwnerUserId
-- attribute) and shows an "[E] Inspect <planet>" prompt — an auto-sizing pill
-- with a keycap-style E badge — when the player flies close enough. The prompt
-- fades out again when they leave range. Because the planet orbits the star,
-- distance is measured against the model's LIVE pivot every check, so the prompt
-- naturally follows the planet around its orbit.
--
-- Pressing E near the planet (4B) enters inspect mode: a scriptable camera frames
-- the planet from its sunlit side and tracks it as it orbits, while the player is
-- locked in place (via the `PlanetInspectLocked` attribute that SpaceMovement
-- reads). E again or Backspace exits and restores the normal camera + movement.
-- The camera is always restored on exit, even if the planet disappears or the
-- character respawns mid-inspect.
--
-- Scope so far: own planet only (never other players'); no Matter/economy/server
-- spending. While inspecting, a read-only info panel (4C) shows the planet's
-- attributes, and an "Open Matter Converter" button publishes the current planet
-- context via PlanetInspectContext (4D) for Nova's economy UI to consume — this
-- file never deducts Matter or calls economy remotes.
--
-- Self-contained LocalScript (like SpaceMovement / DustAnimator / PlanetMarker)
-- — no Main.client wiring. One ScreenGui is built with ResetOnSpawn = false so
-- respawning never spawns a duplicate prompt.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- WorldConfig gives us the star position so the inspect camera can frame the
-- planet from its sunlit side. Falls back gracefully if it can't be required.
local STAR_POS = Vector3.new(0, 0, -900)
do
	local ok, config = pcall(function()
		return require(ReplicatedStorage:WaitForChild("WorldConfig", 5))
	end)
	if ok and config and typeof(config.CENTERPIECE_STAR_POS) == "Vector3" then
		STAR_POS = config.CENTERPIECE_STAR_POS
	end
end

-- The inspect→Matter Converter seam (Sprint 4D). We publish planet context here;
-- Nova's Converter UI consumes it. Sibling client ModuleScript.
local PlanetInspectContext = require(script.Parent:WaitForChild("PlanetInspectContext"))

local PROMPT_DISTANCE    = 170  -- show the prompt at/under this distance (studs)
local PROMPT_HIDE_BUFFER = 20   -- ...and hide once you pass distance + this (=190)
local UPDATE_INTERVAL    = 0.1  -- seconds between distance checks (no need per-frame)

local DEFAULT_DISPLAY_NAME = "Origin World"
local DEFAULT_RADIUS       = 50

-- Set true to show raw seed / owner / radius in the inspect panel (dev only).
local SHOW_DEBUG_PLANET_INFO = false

local player = Players.LocalPlayer

-- ---- Prompt UI (built once) ---------------------------------------------------
-- A pill that auto-sizes to its text (so any planet name fits), with a keycap-
-- style "E" badge, a soft vertical gradient for depth, a cyan rim, and a gentle
-- fade + pop animation on show/hide. A CanvasGroup root lets us fade everything
-- (background, stroke, text, keycap) uniformly via one GroupTransparency.
local CYAN = Color3.fromRGB(130, 205, 255)

local gui = Instance.new("ScreenGui")
gui.Name = "PlanetInteraction"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 11 -- above the planet marker (10)
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("CanvasGroup")
panel.Name = "Prompt"
panel.AnchorPoint = Vector2.new(0.5, 1)
panel.Position = UDim2.new(0.5, 0, 1, -90) -- bottom-center, lifted off the edge
panel.AutomaticSize = Enum.AutomaticSize.X  -- width grows to fit the text
panel.Size = UDim2.fromOffset(0, 48)
panel.BackgroundColor3 = Color3.fromRGB(11, 15, 23)
panel.BackgroundTransparency = 0.08
panel.BorderSizePixel = 0
panel.GroupTransparency = 1 -- starts hidden; the show tween fades it in
panel.Parent = gui

-- A UIScale drives the subtle pop-in (0.9 → 1.0) alongside the fade.
local panelScale = Instance.new("UIScale")
panelScale.Scale = 1
panelScale.Parent = panel

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 12)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = CYAN
panelStroke.Transparency = 0.45
panelStroke.Thickness = 1.5
panelStroke.Parent = panel

-- Top-lit gradient: a touch brighter at the top, darker at the bottom.
local panelGradient = Instance.new("UIGradient")
panelGradient.Rotation = 90
panelGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(26, 34, 48)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(9, 12, 19)),
})
panelGradient.Parent = panel

local panelPadding = Instance.new("UIPadding")
panelPadding.PaddingLeft = UDim.new(0, 14)
panelPadding.PaddingRight = UDim.new(0, 18)
panelPadding.Parent = panel

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
layout.Padding = UDim.new(0, 10)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = panel

-- Keycap "E" badge.
local keycap = Instance.new("Frame")
keycap.Name = "Keycap"
keycap.LayoutOrder = 1
keycap.Size = UDim2.fromOffset(30, 30)
keycap.BackgroundColor3 = Color3.fromRGB(31, 42, 60)
keycap.BorderSizePixel = 0
keycap.Parent = panel

local keycapCorner = Instance.new("UICorner")
keycapCorner.CornerRadius = UDim.new(0, 7)
keycapCorner.Parent = keycap

local keycapStroke = Instance.new("UIStroke")
keycapStroke.Color = CYAN
keycapStroke.Transparency = 0.25
keycapStroke.Thickness = 1.5
keycapStroke.Parent = keycap

local keyLabel = Instance.new("TextLabel")
keyLabel.Name = "Key"
keyLabel.Size = UDim2.fromScale(1, 1)
keyLabel.BackgroundTransparency = 1
keyLabel.Font = Enum.Font.GothamBold
keyLabel.Text = "E"
keyLabel.TextSize = 16
keyLabel.TextColor3 = Color3.fromRGB(214, 238, 255)
keyLabel.Parent = keycap

-- Description text — auto-sizes its width so the pill fits the planet name.
local label = Instance.new("TextLabel")
label.Name = "Label"
label.LayoutOrder = 2
label.AutomaticSize = Enum.AutomaticSize.X
label.Size = UDim2.fromOffset(0, 30)
label.BackgroundTransparency = 1
label.Font = Enum.Font.GothamMedium
label.TextSize = 18
label.TextColor3 = Color3.fromRGB(228, 240, 255)
label.Text = "Inspect Origin World"
label.Parent = panel

-- ---- Planet lookup helpers ----------------------------------------------------
local function getPlayerPlanetsFolder(): Folder?
	local env = Workspace:FindFirstChild("SpaceEnvironment")
	local folder = env and env:FindFirstChild("PlayerPlanets")
	if folder and folder:IsA("Folder") then
		return folder
	end
	return nil
end

local function findLocalPlayerPlanet(): Model?
	local folder = getPlayerPlanetsFolder()
	if not folder then
		return nil
	end
	for _, model in folder:GetChildren() do
		if model:IsA("Model") and model:GetAttribute("OwnerUserId") == player.UserId then
			return model
		end
	end
	return nil
end

local function getPlanetRadius(planet: Model): number
	local radius = planet:GetAttribute("Radius")
	if typeof(radius) == "number" and radius > 0 then
		return radius
	end
	return DEFAULT_RADIUS
end

local function getPlanetDisplayName(planet: Model): string
	local name = planet:GetAttribute("DisplayName")
	if typeof(name) == "string" and name ~= "" then
		return name
	end
	return DEFAULT_DISPLAY_NAME
end

-- ---- State --------------------------------------------------------------------
local promptVisible = false
local currentPlanet: Model? = nil

local function getRootPart(): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local SHOW_TWEEN = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local HIDE_TWEEN = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local activeTween: Tween? = nil

local function setPromptVisible(visible: boolean, planet: Model?)
	if visible == promptVisible then
		return
	end
	promptVisible = visible
	-- Let PlanetMarker know the prompt is up so it can hide (no marker/prompt overlap).
	player:SetAttribute("PlanetPromptVisible", visible or nil)

	if activeTween then
		activeTween:Cancel()
		activeTween = nil
	end

	if visible then
		if planet then
			label.Text = string.format("Inspect %s", getPlanetDisplayName(planet))
		end
		gui.Enabled = true
		panelScale.Scale = 0.9
		panel.GroupTransparency = 1
		TweenService:Create(panelScale, SHOW_TWEEN, { Scale = 1 }):Play()
		activeTween = TweenService:Create(panel, SHOW_TWEEN, { GroupTransparency = 0 })
		activeTween:Play()
	else
		TweenService:Create(panelScale, HIDE_TWEEN, { Scale = 0.95 }):Play()
		local tween = TweenService:Create(panel, HIDE_TWEEN, { GroupTransparency = 1 })
		activeTween = tween
		tween.Completed:Connect(function()
			-- Only disable if we're still meant to be hidden (no re-show raced in).
			if not promptVisible then
				gui.Enabled = false
			end
		end)
		tween:Play()
	end
end

-- ---- Inspect info panel (Sprint 4C) -------------------------------------------
-- A read-only panel shown while inspecting: name, archetype, life stage, water /
-- clouds / atmosphere, and a "Matter Converter: Coming Soon" placeholder. Reads
-- straight from the planet model's attributes, all with graceful fallbacks — no
-- spending, no remotes. Lives in its own ScreenGui so it shows/hides independently
-- of the approach prompt.
local DIM_COLOR = "rgb(150,172,196)" -- field-name color inside RichText rows

local infoGui = Instance.new("ScreenGui")
infoGui.Name = "PlanetInspectInfo"
infoGui.ResetOnSpawn = false
infoGui.IgnoreGuiInset = true
infoGui.DisplayOrder = 12
infoGui.Enabled = false
infoGui.Parent = player:WaitForChild("PlayerGui")

local infoPanel = Instance.new("CanvasGroup")
infoPanel.Name = "InfoPanel"
infoPanel.AnchorPoint = Vector2.new(1, 0.5)
infoPanel.Position = UDim2.new(1, -36, 0.5, 0) -- right side, vertically centered
infoPanel.Size = UDim2.fromOffset(316, 0)
infoPanel.AutomaticSize = Enum.AutomaticSize.Y -- height grows to fit the rows
infoPanel.BackgroundColor3 = Color3.fromRGB(11, 15, 23)
infoPanel.BackgroundTransparency = 0.06
infoPanel.BorderSizePixel = 0
infoPanel.GroupTransparency = 1
infoPanel.Parent = infoGui

local infoScale = Instance.new("UIScale")
infoScale.Scale = 1
infoScale.Parent = infoPanel

local infoCorner = Instance.new("UICorner")
infoCorner.CornerRadius = UDim.new(0, 14)
infoCorner.Parent = infoPanel

local infoStroke = Instance.new("UIStroke")
infoStroke.Color = CYAN
infoStroke.Transparency = 0.45
infoStroke.Thickness = 1.5
infoStroke.Parent = infoPanel

local infoGradient = Instance.new("UIGradient")
infoGradient.Rotation = 90
infoGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(24, 32, 46)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(9, 12, 19)),
})
infoGradient.Parent = infoPanel

local infoPadding = Instance.new("UIPadding")
infoPadding.PaddingTop = UDim.new(0, 16)
infoPadding.PaddingBottom = UDim.new(0, 16)
infoPadding.PaddingLeft = UDim.new(0, 18)
infoPadding.PaddingRight = UDim.new(0, 18)
infoPadding.Parent = infoPanel

local infoLayout = Instance.new("UIListLayout")
infoLayout.FillDirection = Enum.FillDirection.Vertical
infoLayout.SortOrder = Enum.SortOrder.LayoutOrder
infoLayout.Padding = UDim.new(0, 6)
infoLayout.Parent = infoPanel

-- Small factory for a left-aligned text row inside the panel.
local function makeInfoLabel(order: number, opts)
	opts = opts or {}
	local l = Instance.new("TextLabel")
	l.LayoutOrder = order
	l.BackgroundTransparency = 1
	l.AutomaticSize = Enum.AutomaticSize.Y
	l.Size = UDim2.new(1, 0, 0, opts.height or 20)
	l.Font = opts.font or Enum.Font.Gotham
	l.TextSize = opts.size or 16
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextYAlignment = Enum.TextYAlignment.Center
	l.TextColor3 = opts.color or Color3.fromRGB(224, 236, 248)
	l.TextWrapped = opts.wrap or false
	l.RichText = true
	l.Text = ""
	l.Parent = infoPanel
	return l
end

local function makeDivider(order: number)
	local d = Instance.new("Frame")
	d.LayoutOrder = order
	d.Size = UDim2.new(1, 0, 0, 1)
	d.BackgroundColor3 = CYAN
	d.BackgroundTransparency = 0.7
	d.BorderSizePixel = 0
	d.Parent = infoPanel
	return d
end

local titleLabel    = makeInfoLabel(1, { font = Enum.Font.GothamBold, size = 22, height = 28 })
makeDivider(2)
local rowArchetype  = makeInfoLabel(3)
local rowStage      = makeInfoLabel(4)
local rowLife       = makeInfoLabel(5)
local rowCiv        = makeInfoLabel(6)
local rowWater      = makeInfoLabel(8)
local rowClouds     = makeInfoLabel(9)
local rowAtmos      = makeInfoLabel(10)
local debugLabel    = makeInfoLabel(11, { wrap = true, size = 13, color = Color3.fromRGB(150, 170, 190) })
makeDivider(12)

-- "Open Matter Converter" button (Sprint 4D) — hands the current planet context to
-- Nova's Converter via PlanetInspectContext. No spending happens here.
local converterButton = Instance.new("TextButton")
converterButton.Name = "OpenMatterConverter"
converterButton.LayoutOrder = 13
converterButton.Size = UDim2.new(1, 0, 0, 34)
converterButton.BackgroundColor3 = Color3.fromRGB(22, 40, 60)
converterButton.BackgroundTransparency = 0.1
converterButton.BorderSizePixel = 0
converterButton.AutoButtonColor = true
converterButton.Font = Enum.Font.GothamMedium
converterButton.TextSize = 15
converterButton.TextColor3 = Color3.fromRGB(176, 218, 255)
converterButton.Text = "Open Matter Converter"
converterButton.Parent = infoPanel

local converterCorner = Instance.new("UICorner")
converterCorner.CornerRadius = UDim.new(0, 8)
converterCorner.Parent = converterButton

local converterStroke = Instance.new("UIStroke")
converterStroke.Color = CYAN
converterStroke.Transparency = 0.5
converterStroke.Thickness = 1
converterStroke.Parent = converterButton

local exitLabel      = makeInfoLabel(14, { size = 13, color = Color3.fromRGB(150, 170, 190) })

converterButton.Activated:Connect(function()
	PlanetInspectContext.requestOpen()
	local ctx = PlanetInspectContext.get()
	print(string.format(
		"[PlanetInteraction] Matter Converter open requested for %s (awaiting Nova's Converter UI)",
		(ctx and ctx.displayName) or "your planet"
	))
	-- Brief placeholder feedback until Nova's Converter UI is wired in.
	converterButton.Text = "Matter Converter integration pending…"
	task.delay(1.4, function()
		if converterButton.Parent then
			converterButton.Text = "Open Matter Converter"
		end
	end)
end)

-- ---- Formatting helpers -------------------------------------------------------
local function field(name: string, value: string): string
	return string.format('<font color="%s">%s</font>   %s', DIM_COLOR, name, value)
end

-- "TemperateOcean" / "young_habitable" -> "Temperate Ocean" / "Young Habitable"
local function prettify(raw): string
	if typeof(raw) ~= "string" or raw == "" then
		return "Unknown"
	end
	local s = raw:gsub("[_%-]+", " ")          -- snake/kebab -> spaces
	s = s:gsub("(%l)(%u)", "%1 %2")            -- camelCase -> spaced
	s = s:gsub("(%a)(%d)", "%1 %2")            -- letters|digits boundary
	s = s:gsub("^%l", string.upper)            -- capitalize first letter
	return s
end

local function formatPct(value): string
	if typeof(value) == "number" then
		return string.format("%d%%", math.floor(value * 100 + 0.5))
	end
	return "—"
end

local function atmosphereLabel(value): string
	if typeof(value) ~= "number" then
		return "—"
	elseif value <= 0.33 then
		return "Thin"
	elseif value <= 0.66 then
		return "Moderate"
	end
	return "Dense"
end

-- Pull all displayed values from the model's attributes (graceful on missing).
local function updateInfoPanel(planet: Model?)
	if not (planet and planet.Parent) then
		return
	end
	titleLabel.Text = getPlanetDisplayName(planet)
	rowArchetype.Text = field("Archetype", prettify(planet:GetAttribute("Archetype")))

	-- Stage/life/civ track Nova's progression attributes when present, else show
	-- placeholders. Mirrors PlanetStageVisuals: stage string wins, else derive from
	-- the numeric tier (0 = Prebiotic, 1 = Archaea — the only stage hooked up so far).
	local stageAttr = planet:GetAttribute("EvolutionStage")
	local tierAttr = planet:GetAttribute("EvolutionTier")
	local stage = "Prebiotic"
	local alive = false
	if typeof(stageAttr) == "string" and stageAttr ~= "" then
		stage = stageAttr
		alive = stageAttr:lower() ~= "prebiotic"
	elseif typeof(tierAttr) == "number" and tierAttr >= 1 then
		stage = (tierAttr == 1) and "Archaea" or ("Tier " .. tierAttr)
		alive = true
	end
	rowStage.Text = field("Stage", stage)
	rowLife.Text = field("Life", alive and "Microbial" or "Dormant")
	rowCiv.Text = field("Civilization", "None")

	rowWater.Text = field("Water", formatPct(planet:GetAttribute("WaterCoverage")))
	rowClouds.Text = field("Clouds", formatPct(planet:GetAttribute("CloudCoverage")))
	rowAtmos.Text = field("Atmosphere", atmosphereLabel(planet:GetAttribute("AtmosphereThickness")))

	exitLabel.Text = field("[E] / [Backspace]", "Exit")

	if SHOW_DEBUG_PLANET_INFO then
		debugLabel.Visible = true
		debugLabel.Text = string.format(
			"seed %s · owner %s · r %s",
			tostring(planet:GetAttribute("Seed")),
			tostring(planet:GetAttribute("OwnerUserId")),
			tostring(planet:GetAttribute("Radius"))
		)
	else
		debugLabel.Visible = false
	end
end

local INFO_SHOW_TWEEN = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local INFO_HIDE_TWEEN = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local infoTween: Tween? = nil
local infoPanelOpen = false

local function showInfoPanel(planet: Model)
	infoPanelOpen = true
	updateInfoPanel(planet)
	if infoTween then
		infoTween:Cancel()
	end
	infoGui.Enabled = true
	infoScale.Scale = 0.96
	infoPanel.GroupTransparency = 1
	TweenService:Create(infoScale, INFO_SHOW_TWEEN, { Scale = 1 }):Play()
	infoTween = TweenService:Create(infoPanel, INFO_SHOW_TWEEN, { GroupTransparency = 0 })
	infoTween:Play()
end

local function hideInfoPanel()
	infoPanelOpen = false
	if infoTween then
		infoTween:Cancel()
	end
	local tween = TweenService:Create(infoPanel, INFO_HIDE_TWEEN, { GroupTransparency = 1 })
	infoTween = tween
	tween.Completed:Connect(function()
		-- Don't disable if a new inspect re-opened the panel in the meantime.
		if not infoPanelOpen then
			infoGui.Enabled = false
		end
	end)
	tween:Play()
end

-- ---- Inspect mode (Sprint 4B) -------------------------------------------------
-- Pressing E near the planet frames it with a scriptable camera and locks the
-- player in place; E again or Backspace exits. The camera tracks the planet's
-- LIVE pivot every frame, so it follows the world as it orbits the star.
local CAMERA_SMOOTH    = 8    -- higher = snappier camera lerp
local CAMERA_DIST_MULT = 3.5  -- camera distance = radius * this
local CAMERA_HEIGHT_MULT = 0.7 -- camera lift above planet center = radius * this

local inspectMode = false
local inspectPlanet: Model? = nil

-- Camera CFrame that frames the planet from its sunlit (star-facing-away) side.
local function inspectCameraTarget(planet: Model): CFrame
	local planetPos = planet:GetPivot().Position
	local radius = getPlanetRadius(planet)
	local awayFromStar = planetPos - STAR_POS
	awayFromStar = (awayFromStar.Magnitude > 1e-3) and awayFromStar.Unit or Vector3.zAxis
	local camPos = planetPos
		+ awayFromStar * (radius * CAMERA_DIST_MULT)
		+ Vector3.new(0, radius * CAMERA_HEIGHT_MULT, 0)
	return CFrame.lookAt(camPos, planetPos)
end

local function exitInspectMode()
	if not inspectMode then
		return
	end
	inspectMode = false
	inspectPlanet = nil
	hideInfoPanel()
	PlanetInspectContext.clear() -- tell Nova's Converter we left planet context
	player:SetAttribute("InspectingPlanet", nil)
	player:SetAttribute("PlanetInspectLocked", nil) -- release the movement lock

	-- Always restore the camera, even if the planet vanished mid-inspect.
	local camera = Workspace.CurrentCamera
	if camera then
		camera.CameraType = Enum.CameraType.Custom
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			camera.CameraSubject = humanoid
		end
	end
end

local function enterInspectMode(planet: Model?)
	if inspectMode or not planet then
		return
	end
	local rootPart = getRootPart()
	if not rootPart then
		return -- no character to lock; ignore
	end

	inspectMode = true
	inspectPlanet = planet
	player:SetAttribute("InspectingPlanet", true) -- PlanetMarker hides while inspecting
	setPromptVisible(false) -- hide the approach prompt while focused
	showInfoPanel(planet)   -- open the read-only info panel

	-- Publish planet context for Nova's Matter Converter (no spending here).
	PlanetInspectContext.set({
		type = "Planet",
		planetModel = planet,
		planetId = planet:GetAttribute("PlanetId"),
		ownerUserId = planet:GetAttribute("OwnerUserId"),
		displayName = getPlanetDisplayName(planet),
	})

	-- Lock movement (SpaceMovement reads this) and kill residual motion now.
	player:SetAttribute("PlanetInspectLocked", true)
	rootPart.AssemblyLinearVelocity = Vector3.zero
	rootPart.AssemblyAngularVelocity = Vector3.zero

	local camera = Workspace.CurrentCamera
	if camera then
		camera.CameraType = Enum.CameraType.Scriptable -- lerps from the current view
	end
end

-- Camera tracking: runs every frame but only does work while inspecting.
local sinceInfoRefresh = 0
RunService.RenderStepped:Connect(function(dt)
	if not inspectMode then
		return
	end
	local camera = Workspace.CurrentCamera
	local planet = inspectPlanet
	-- Failure recovery: planet destroyed / camera gone → bail out cleanly.
	if not (camera and planet and planet.Parent and planet.PrimaryPart) then
		exitInspectMode()
		return
	end
	local alpha = 1 - math.exp(-CAMERA_SMOOTH * dt)
	camera.CFrame = camera.CFrame:Lerp(inspectCameraTarget(planet), alpha)

	-- Refresh the panel a few times a second so it reflects live attribute changes
	-- (e.g. when Nova's progression system updates the stage) without per-frame churn.
	sinceInfoRefresh += dt
	if sinceInfoRefresh >= 0.25 then
		sinceInfoRefresh = 0
		updateInfoPanel(planet)
	end
end)

-- If the character respawns mid-inspect, exit so we don't strand the camera.
player.CharacterAdded:Connect(function()
	if inspectMode then
		exitInspectMode()
	end
end)

-- ---- Distance check (throttled) -----------------------------------------------
local sinceUpdate = 0
RunService.Heartbeat:Connect(function(dt)
	-- While inspecting, the prompt stays hidden; resume normal prompt logic on exit.
	if inspectMode then
		return
	end

	sinceUpdate += dt
	if sinceUpdate < UPDATE_INTERVAL then
		return
	end
	sinceUpdate = 0

	local rootPart = getRootPart()
	local planet = findLocalPlayerPlanet()
	currentPlanet = planet

	-- No character or planet not spawned yet: keep the prompt hidden, no errors.
	if not (rootPart and planet) then
		setPromptVisible(false)
		return
	end

	local distance = (rootPart.Position - planet:GetPivot().Position).Magnitude
	-- Hysteresis: cross PROMPT_DISTANCE to show, but only hide past the buffer,
	-- so hovering right at the threshold doesn't flicker the prompt on/off.
	if not promptVisible and distance <= PROMPT_DISTANCE then
		setPromptVisible(true, planet)
	elseif promptVisible and distance >= PROMPT_DISTANCE + PROMPT_HIDE_BUFFER then
		setPromptVisible(false)
	end
end)

-- ---- Input: enter / exit inspect mode -----------------------------------------
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.E then
		if inspectMode then
			exitInspectMode() -- E toggles back out
		elseif promptVisible and currentPlanet then
			enterInspectMode(currentPlanet)
		end
	elseif input.KeyCode == Enum.KeyCode.Backspace then
		if inspectMode then
			exitInspectMode()
		end
	elseif input.KeyCode == Enum.KeyCode.R then
		-- R is return-home (handled in SpaceMovement). If we're inspecting, exit first
		-- so the player flies home with a normal camera instead of staying focused.
		if inspectMode then
			exitInspectMode()
		end
	end
end)
