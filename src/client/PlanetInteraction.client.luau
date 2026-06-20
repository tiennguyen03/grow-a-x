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
-- Scope: own planet only (never other players'). While inspecting, a read-only
-- info panel (4C) shows the planet's attributes, plus an Intervention section with
-- a "Create Life" button — a PLANET intervention that requests a server-authoritative
-- Archaea purchase (Matter Core integration). The client only requests + reflects
-- server-pushed numbers; PlayerManager validates, deducts Matter, and flips the
-- planet to the Archaea stage. Context is still published via PlanetInspectContext
-- (4D) so the standalone Matter Core panel can show the inspected planet's name.
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

-- Organelle / cell-management UI (Epic 3, Tier 1). The whole life-intervention
-- interface (create cells, buy organelles, watch a cell evolve into a Eukaryote)
-- is mounted into this inspect panel below — the old Matter Core panel is obsolete.
-- All spends are server-authoritative; this module only requests + reflects them.
local CellInterventionUI = require(script.Parent:WaitForChild("CellInterventionUI"))

-- Interactive ecosystem interventions (Epic 6: Life Progress / Stability), mounted
-- below the live cell UI.
local EcosystemInterventionUI = require(script.Parent:WaitForChild("EcosystemInterventionUI"))

-- Sentience interventions (Epic 7: Complex Life — Sentience Progress + tendencies),
-- mounted below the ecosystem section; gated until Complex Life.
local SentienceUI = require(script.Parent:WaitForChild("SentienceUI"))

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

-- Wider, TABBED panel: a fixed header (planet name + tab row) over a page area, so
-- the four sections (Overview / Cells / Ecosystem / Sentience) each get their own
-- short page instead of one endlessly-scrolling column crammed on the right.
local PANEL_W = 430
local PANEL_FRAC = 0.84 -- panel height as a fraction of the viewport
local HEADER_H = 78
local DIM_TEXT = Color3.fromRGB(150, 166, 186)

local infoPanel = Instance.new("CanvasGroup")
infoPanel.Name = "InfoPanel"
infoPanel.AnchorPoint = Vector2.new(1, 0.5)
infoPanel.Position = UDim2.new(1, -36, 0.5, 0) -- right side, vertically centered
infoPanel.Size = UDim2.fromOffset(PANEL_W, 480) -- height set from the viewport below
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

-- Fixed, comfortable size; tabs keep each section short so the whole panel never scrolls.
local function updateInfoPanelHeight()
	local camera = Workspace.CurrentCamera
	local viewportH = (camera and camera.ViewportSize.Y) or 600
	infoPanel.Size = UDim2.fromOffset(PANEL_W, math.floor(viewportH * PANEL_FRAC))
end
do
	local cam0 = Workspace.CurrentCamera
	if cam0 then
		cam0:GetPropertyChangedSignal("ViewportSize"):Connect(updateInfoPanelHeight)
	end
end
updateInfoPanelHeight()

-- ---- Header (planet name + tab row), fixed at the top ----
local headerFrame = Instance.new("Frame")
headerFrame.Name = "Header"
headerFrame.Size = UDim2.new(1, 0, 0, HEADER_H)
headerFrame.BackgroundTransparency = 1
headerFrame.Parent = infoPanel
local headerPad = Instance.new("UIPadding")
headerPad.PaddingLeft = UDim.new(0, 18)
headerPad.PaddingRight = UDim.new(0, 18)
headerPad.PaddingTop = UDim.new(0, 12)
headerPad.Parent = headerFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, 0, 0, 26)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 22
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.TextColor3 = Color3.fromRGB(228, 240, 255)
titleLabel.Text = "Origin World"
titleLabel.Parent = headerFrame

local tabBar = Instance.new("Frame")
tabBar.Name = "Tabs"
tabBar.Position = UDim2.fromOffset(0, 36)
tabBar.Size = UDim2.new(1, 0, 0, 28)
tabBar.BackgroundTransparency = 1
tabBar.Parent = headerFrame
local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
tabLayout.Padding = UDim.new(0, 4)
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Parent = tabBar

local headerDivider = Instance.new("Frame")
headerDivider.Position = UDim2.new(0, 0, 0, HEADER_H - 1)
headerDivider.Size = UDim2.new(1, 0, 0, 1)
headerDivider.BackgroundColor3 = CYAN
headerDivider.BackgroundTransparency = 0.7
headerDivider.BorderSizePixel = 0
headerDivider.Parent = infoPanel

-- ---- Page area (below the header) ----
local pagesHost = Instance.new("Frame")
pagesHost.Name = "Pages"
pagesHost.Position = UDim2.fromOffset(0, HEADER_H)
pagesHost.Size = UDim2.new(1, 0, 1, -HEADER_H)
pagesHost.BackgroundTransparency = 1
pagesHost.Parent = infoPanel

-- A page is a scrolling frame (only the active page scrolls, and only if it's long).
local function makePage()
	local p = Instance.new("ScrollingFrame")
	p.Size = UDim2.fromScale(1, 1)
	p.BackgroundTransparency = 1
	p.BorderSizePixel = 0
	p.CanvasSize = UDim2.new()
	p.AutomaticCanvasSize = Enum.AutomaticSize.Y
	p.ScrollingDirection = Enum.ScrollingDirection.Y
	p.ScrollBarThickness = 5
	p.ScrollBarImageColor3 = CYAN
	p.ScrollBarImageTransparency = 0.4
	p.Active = true
	p.Visible = false
	p.Parent = pagesHost
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 12)
	pad.PaddingBottom = UDim.new(0, 14)
	pad.PaddingLeft = UDim.new(0, 18)
	pad.PaddingRight = UDim.new(0, 18)
	pad.Parent = p
	local lay = Instance.new("UIListLayout")
	lay.FillDirection = Enum.FillDirection.Vertical
	lay.SortOrder = Enum.SortOrder.LayoutOrder
	lay.Padding = UDim.new(0, 8)
	lay.Parent = p
	return p
end

local overviewPage = makePage()
local cellsPage = makePage()
local ecoPage = makePage()
local sentiencePage = makePage()
local infoScroll = overviewPage -- planet-info rows live on the Overview page

-- ---- Tabs ----
local tabs = {}
local function setActiveTab(idx)
	for i, t in tabs do
		t.page.Visible = (i == idx)
		t.button.TextColor3 = (i == idx) and CYAN or DIM_TEXT
		t.underline.Visible = (i == idx)
	end
end
local function makeTab(name, page, order)
	local b = Instance.new("TextButton")
	b.Name = "Tab_" .. name
	b.AutomaticSize = Enum.AutomaticSize.X
	b.Size = UDim2.fromOffset(0, 28)
	b.BackgroundTransparency = 1
	b.AutoButtonColor = false
	b.Font = Enum.Font.GothamMedium
	b.TextSize = 14
	b.TextColor3 = DIM_TEXT
	b.Text = name
	b.LayoutOrder = order
	b.Parent = tabBar
	local bp = Instance.new("UIPadding")
	bp.PaddingLeft = UDim.new(0, 7)
	bp.PaddingRight = UDim.new(0, 7)
	bp.Parent = b
	local underline = Instance.new("Frame")
	underline.AnchorPoint = Vector2.new(0.5, 1)
	underline.Position = UDim2.new(0.5, 0, 1, 0)
	underline.Size = UDim2.new(1, -6, 0, 2)
	underline.BackgroundColor3 = CYAN
	underline.BorderSizePixel = 0
	underline.Visible = false
	underline.Parent = b
	local idx = #tabs + 1
	b.Activated:Connect(function()
		setActiveTab(idx)
	end)
	table.insert(tabs, { button = b, page = page, underline = underline })
end
makeTab("Overview", overviewPage, 1)
makeTab("Cells", cellsPage, 2)
makeTab("Ecosystem", ecoPage, 3)
makeTab("World Direction", sentiencePage, 4)

-- A left-aligned text row on a page (defaults to the Overview page).
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
	l.Parent = opts.parent or infoScroll
	return l
end

-- A "Field   value" row string with the field name dimmed (RichText).
local function field(name: string, value: string): string
	return string.format('<font color="%s">%s</font>   %s', DIM_COLOR, name, value)
end

-- Overview page. World Overview first (what the world is *becoming* — V3 framing:
-- K-Rating / Era / Next Milestone / Species Identity), then planet identity + conditions.
local rowKRating    = makeInfoLabel(1, { font = Enum.Font.GothamBold, size = 18, height = 22, color = CYAN })
local rowEra        = makeInfoLabel(2)
local rowMilestone  = makeInfoLabel(3)
local rowCiv        = makeInfoLabel(4)
local rowArchetype  = makeInfoLabel(7)
local rowStage      = makeInfoLabel(8)
local rowLife       = makeInfoLabel(9)
local rowWater      = makeInfoLabel(11)
local rowClouds     = makeInfoLabel(12)
local rowAtmos      = makeInfoLabel(13)
local debugLabel    = makeInfoLabel(14, { wrap = true, size = 13, color = Color3.fromRGB(150, 170, 190) })
local exitLabel     = makeInfoLabel(20, { size = 13, color = DIM_TEXT })

-- Each gameplay system mounts into its own tab page (server-authoritative; the
-- modules own their remotes/state — they just parent into whatever frame we pass).
CellInterventionUI.mount(cellsPage, { layoutOrder = 1 })
EcosystemInterventionUI.mount(ecoPage, { layoutOrder = 1 })
SentienceUI.mount(sentiencePage, { layoutOrder = 1 })

setActiveTab(1) -- default to Overview

-- ---- Formatting helpers -------------------------------------------------------
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

	-- ---- World Overview (Epic 7 / V3): K-Rating · Era · Next Milestone · Species Identity ----
	-- All derived client-side from mirrored attributes (no server change). Complex Life is
	-- reached at the Multicellular stage / Life Progress maxed; K-Rating is display-only and
	-- spans K0.45–K0.70 across Complex Life (Tool Use at K0.70 — see Epic7.md §1).
	local lifeProgress = tonumber(planet:GetAttribute("LifeProgress")) or 0
	local lifeProgressMax = tonumber(planet:GetAttribute("LifeProgressMax")) or 0
	local sentience = tonumber(planet:GetAttribute("SentienceProgress")) or 0
	local stageLower = stage:lower()
	local toolUse = stageLower == "tooluse"
	local complexLife = toolUse
		or stageLower == "multicellular"
		or (lifeProgressMax > 0 and lifeProgress >= lifeProgressMax)

	local kRating
	if toolUse then
		kRating = 0.70
	elseif complexLife then
		kRating = 0.45 + (math.clamp(sentience, 0, 100) / 100) * 0.25
	elseif lifeProgressMax > 0 then
		kRating = 0.20 + math.clamp(lifeProgress / lifeProgressMax, 0, 1) * 0.25
	elseif alive then
		kRating = 0.20
	else
		kRating = 0.10
	end
	rowKRating.Text = field("K-Rating", string.format("K%.2f", kRating))

	local era
	if toolUse then
		era = "Tool Use"
	elseif complexLife then
		era = "Complex Life"
	elseif alive then
		era = "Early Life"
	else
		era = "Prebiotic"
	end
	rowEra.Text = field("Era", era)

	local milestone
	if not complexLife then
		milestone = "Complex Life (K0.45)"
	elseif not toolUse then
		milestone = "Tool Use (K0.70)"
	else
		milestone = "Civilization era"
	end
	rowMilestone.Text = field("Next Milestone", milestone)

	-- Species Identity emerges from sentience tendencies. Server writes the CivIdentity
	-- attribute once Complex Life begins; "Emerging…" once Complex Life starts, else "—".
	local identity = planet:GetAttribute("CivIdentity")
	local identityText
	if typeof(identity) == "string" and identity ~= "" and identity ~= "—" then
		identityText = identity
	elseif complexLife then
		identityText = "Emerging…"
	else
		identityText = "—"
	end
	rowCiv.Text = field("Species Identity", identityText)

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
