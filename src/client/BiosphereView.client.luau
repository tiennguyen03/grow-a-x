-- Biosphere View — dual-mode visual feedback for the player's life forms (Epic 3).
--
-- TWO modes, both driven by the SAME underlying data (the player's total cell
-- count + dominant life form, derived client-side from ConverterUpdate):
--
--   1. Life Vessel  — a glowing, glass-like orb that floats near the camera and
--      represents the whole biosphere. Its richness grows with cell count (dark &
--      empty → faint speckles → dots → clustered glow → swirling motion → living
--      texture → brilliant patterns). It pulses like a heartbeat, tints toward the
--      dominant life form, trails subtle particles, and bursts on create/evolve.
--      ALWAYS active in the background.
--
--   2. Microscope View — a large UI overlay (ScreenGui + ViewportFrame) showing a
--      simulated drop of water: individual cells swim with Brownian motion, each
--      with a nucleus + organelle specks. More cells appear (and the view zooms
--      out for a bigger sample) as the population grows.
--
-- Toggle between them with M (or Tab): opening the microscope "zooms in" from the
-- vessel; closing zooms back out. The vessel keeps running underneath the overlay.
--
-- Self-contained LocalScript (like PlanetStageVisuals): no Main wiring. Cosmetic +
-- client-only — nothing replicates. It NEVER touches the planet visuals; it owns
-- only its own orb (near the camera), its UI overlay, and the celebration toasts.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local OrganelleData = require(ReplicatedStorage:WaitForChild("OrganelleData"))
local MulticellularData = require(ReplicatedStorage:WaitForChild("MulticellularData"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ---- Tunables -----------------------------------------------------------------
local VESSEL_OFFSET = Vector3.new(2.6, -1.6, -7) -- camera-local: right, down, forward
local VESSEL_BASE_SIZE = 2.2
local VESSEL_FOLLOW_SPEED = 10  -- how snappily the orb chases its target spot
local HEARTBEAT_RATE = 1.6      -- pulses per ~second (×2π handled below)
local HEARTBEAT_AMPLITUDE = 0.05

local VESSEL_SPECKLE_CAP = 120  -- max speckles drawn inside the orb (1 per cell up to here)
local VESSEL_SPECKLE_SEED = 8675309 -- fixed so speckle positions are stable as cells grow

local MICRO_MAX_CELLS = 200     -- hard cap on cells drawn in the microscope (perf)
local MICRO_BASE_REGION = Vector3.new(9, 6, 5) -- swim box at the CLOSEST zoom; grows with zoom-out
local MICRO_TOGGLE_KEYS = { [Enum.KeyCode.M] = true, [Enum.KeyCode.Tab] = true }

-- Dominant-life-form palette. The orb + cells tint toward whichever stage leads.
local ARCHAEA_COLOR    = Color3.fromRGB(96, 224, 184)
local EUKARYOTIC_COLOR = Color3.fromRGB(120, 245, 150)
local EMPTY_COLOR      = Color3.fromRGB(60, 70, 90)

-- Per-tier vessel character. Index 1 = 0 cells … index 7 = 1e9+ cells.
local VESSEL_TIERS = {
	{ speckles = 0,  light = 0.0, glow = false, swirl = 0.0, emit = 0.0 }, -- empty
	{ speckles = 5,  light = 0.6, glow = false, swirl = 0.0, emit = 1.0 }, -- 1–9
	{ speckles = 12, light = 1.1, glow = false, swirl = 0.2, emit = 2.0 }, -- 10–99
	{ speckles = 20, light = 1.8, glow = true,  swirl = 0.5, emit = 3.0 }, -- 100–999
	{ speckles = 28, light = 2.6, glow = true,  swirl = 1.1, emit = 4.0 }, -- 1e3–1e6
	{ speckles = 36, light = 3.4, glow = true,  swirl = 1.8, emit = 5.0 }, -- 1e6–1e9
	{ speckles = 44, light = 4.2, glow = true,  swirl = 2.6, emit = 6.5 }, -- 1e9+
}

-- ---- Shared state (both modes read this) --------------------------------------
local state = {
	totalCount = 0,
	dominant = nil,        -- "Archaea" | "Eukaryotic" | nil(empty)
	tier = 1,              -- 1-based index into VESSEL_TIERS
	cells = {},            -- the latest per-cell list from ConverterUpdate (id, stage, purchased, purchasedCount)
	upgrades = 0,          -- multicellular upgrades bought (0..6) — drives the organized-body progression
}

local function tierForCount(n: number): number
	if n <= 0 then return 1
	elseif n < 10 then return 2
	elseif n < 100 then return 3
	elseif n < 1000 then return 4
	elseif n < 1e6 then return 5
	elseif n < 1e9 then return 6
	else return 7 end
end

local function colorForDominant(dominant): Color3
	if dominant == OrganelleData.STAGE_EUKARYOTIC then
		return EUKARYOTIC_COLOR
	elseif dominant == OrganelleData.STAGE_ARCHAEA then
		return ARCHAEA_COLOR
	end
	return EMPTY_COLOR
end

-- =================================================================================
--  LIFE VESSEL  (3D orb near the camera)
-- =================================================================================
local vesselFolder = Instance.new("Folder")
vesselFolder.Name = "LifeVessel"
vesselFolder.Parent = Workspace

-- Glass shell.
local orb = Instance.new("Part")
orb.Name = "VesselOrb"
orb.Shape = Enum.PartType.Ball
orb.Anchored = true
orb.CanCollide = false
orb.CanQuery = false
orb.CanTouch = false
orb.CastShadow = false
orb.Material = Enum.Material.Glass
orb.Color = Color3.fromRGB(180, 220, 230)
orb.Transparency = 0.45
orb.Size = Vector3.one * VESSEL_BASE_SIZE
orb.Parent = vesselFolder

-- Inner glow.
local orbLight = Instance.new("PointLight")
orbLight.Color = EMPTY_COLOR
orbLight.Range = VESSEL_BASE_SIZE * 4
orbLight.Brightness = 0
orbLight.Parent = orb

-- A spinning container the internal speckles live in (so swirl is one transform).
local speckleSpin = 0

-- Subtle continuous particle trail.
local trail = Instance.new("ParticleEmitter")
trail.Color = ColorSequence.new(EMPTY_COLOR)
trail.LightEmission = 0.8
trail.Lifetime = NumberRange.new(0.6, 1.2)
trail.Rate = 0
trail.Speed = NumberRange.new(0.2, 0.8)
trail.SpreadAngle = Vector2.new(40, 40)
trail.Size = NumberSequence.new(0.35)
trail.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.3),
	NumberSequenceKeypoint.new(1, 1),
})
trail.Parent = orb

-- Bigger one-shot burst emitter (cell created / evolved / cascade).
local burst = Instance.new("ParticleEmitter")
burst.Color = ColorSequence.new(EUKARYOTIC_COLOR)
burst.LightEmission = 1
burst.Lifetime = NumberRange.new(0.5, 1.0)
burst.Rate = 0
burst.Speed = NumberRange.new(6, 12)
burst.SpreadAngle = Vector2.new(180, 180)
burst.Size = NumberSequence.new(0.5)
burst.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.1),
	NumberSequenceKeypoint.new(1, 1),
})
burst.Parent = orb

-- The internal speckles are a 1:1 stand-in for the player's actual cells: exactly
-- one per cell (capped for performance), never more. A fixed seed means the first
-- N speckle positions are stable, so growing the count just ADDS a speckle rather
-- than reshuffling the whole cloud.
local speckleParts: { Part } = {}
local builtSpeckleCount = -1

local function rebuildSpeckles(count: number, color: Color3)
	for _, p in speckleParts do
		p:Destroy()
	end
	table.clear(speckleParts)

	local rng = Random.new(VESSEL_SPECKLE_SEED)
	for i = 1, count do
		local s = Instance.new("Part")
		s.Name = "Speckle" .. i
		s.Shape = Enum.PartType.Ball
		s.Anchored = true
		s.CanCollide = false
		s.CanQuery = false
		s.CanTouch = false
		s.CastShadow = false
		s.Material = Enum.Material.Neon
		s.Color = color
		s.Size = Vector3.one * (VESSEL_BASE_SIZE * rng:NextNumber(0.05, 0.12))
		-- A stable point inside the orb (kept as an attribute for placement).
		local dir = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-1, 1), rng:NextNumber(-1, 1))
		if dir.Magnitude < 0.01 then dir = Vector3.yAxis end
		local r = (VESSEL_BASE_SIZE * 0.42) * (rng:NextNumber() ^ (1 / 3))
		s:SetAttribute("LocalOffset", dir.Unit * r)
		s.Parent = vesselFolder
		table.insert(speckleParts, s)
	end
	builtSpeckleCount = count
end

-- Smoothly-approached display values so tier changes ease in rather than snap.
local curLight = 0
local curColor = EMPTY_COLOR

local function updateVesselAppearance()
	local def = VESSEL_TIERS[state.tier]
	local target = colorForDominant(state.dominant)

	-- One speckle per actual cell (capped). Rebuild only when the count changes.
	local desired = math.min(state.totalCount, VESSEL_SPECKLE_CAP)
	if builtSpeckleCount ~= desired then
		rebuildSpeckles(desired, target)
	else
		for _, p in speckleParts do
			p.Color = target
		end
	end

	orbLight.Color = target
	trail.Color = ColorSequence.new(target)
	burst.Color = ColorSequence.new(target)
	trail.Rate = def.emit
	-- Orb tints from a near-clear glass toward the life color as it fills.
	orb.Color = target:Lerp(Color3.fromRGB(200, 225, 230), 0.5)
end

-- Per-frame: follow the camera, heartbeat-pulse, swirl, ease the glow.
RunService.RenderStepped:Connect(function(dt)
	local camera = Workspace.CurrentCamera
	if not camera then return end

	local def = VESSEL_TIERS[state.tier]

	-- Multicellular structure (0 → 1 across the six 1C upgrades): as it rises the loose
	-- cloud of dots becomes an ORGANIZED body — the speckles stop wandering, draw inward
	-- into a tighter form, and pulse together in a stronger, coordinated heartbeat.
	local structure = math.clamp(state.upgrades / MulticellularData.COUNT, 0, 1)

	-- Target spot: a fixed offset in camera space (a companion orb at the lower right).
	local targetCFrame = camera.CFrame * CFrame.new(VESSEL_OFFSET)
	local goalPos = targetCFrame.Position
	local alpha = math.clamp(VESSEL_FOLLOW_SPEED * dt, 0, 1)
	local pos = orb.Position:Lerp(goalPos, alpha)

	-- Heartbeat pulse (double-thump feel via |sin| shaped curve). Coordinated pulse
	-- grows stronger as the body organizes.
	local t = os.clock()
	local beat = math.abs(math.sin(t * HEARTBEAT_RATE * math.pi))
	local pulse = 1 + beat * HEARTBEAT_AMPLITUDE * (state.totalCount > 0 and 1 or 0.3) * (1 + structure)
	orb.Size = Vector3.one * (VESSEL_BASE_SIZE * pulse)
	orb.CFrame = CFrame.new(pos)

	-- Ease the glow toward the tier's target so changes feel organic; an organized body
	-- glows a touch brighter and more steadily.
	curLight += (def.light - curLight) * math.clamp(6 * dt, 0, 1)
	orbLight.Brightness = curLight * (0.85 + beat * 0.3) * (1 + structure * 0.4)
	orbLight.Range = VESSEL_BASE_SIZE * (3 + state.tier)

	-- Swirl: rotate the speckle cloud; place each speckle at its stable local offset.
	speckleSpin += def.swirl * (1 - structure * 0.7) * dt
	local spin = CFrame.Angles(0, speckleSpin, speckleSpin * 0.4)
	local coherent = 1 + beat * structure * 0.14   -- speckles breathe together with the orb
	local draw = 1 - structure * 0.25              -- and draw inward into a tighter body
	for _, p in speckleParts do
		local off = p:GetAttribute("LocalOffset")
		if typeof(off) == "Vector3" then
			-- Internal drift, damped as the body organizes (loose cloud → ordered structure).
			local wobble = Vector3.new(
				math.sin(t * 1.3 + off.X) * 0.04,
				math.cos(t * 1.1 + off.Y) * 0.04,
				math.sin(t * 0.9 + off.Z) * 0.04
			) * def.swirl * (1 - structure * 0.85)
			p.CFrame = CFrame.new(pos) * spin * CFrame.new(off * (draw * coherent) + wobble)
		end
	end
end)

-- =================================================================================
--  MICROSCOPE VIEW  (UI overlay with a ViewportFrame "drop of water")
-- =================================================================================
local microGui = Instance.new("ScreenGui")
microGui.Name = "MicroscopeView"
microGui.ResetOnSpawn = false
microGui.IgnoreGuiInset = true
microGui.DisplayOrder = 30
microGui.Enabled = false
microGui.Parent = playerGui

-- Dim backdrop.
local backdrop = Instance.new("Frame")
backdrop.Name = "Backdrop"
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.BackgroundColor3 = Color3.fromRGB(2, 6, 10)
backdrop.BackgroundTransparency = 0.35
backdrop.BorderSizePixel = 0
backdrop.Parent = microGui

-- The "petri dish" panel that scales in from the vessel's screen position.
local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromScale(0.72, 0.78)
panel.BackgroundColor3 = Color3.fromRGB(8, 16, 22)
panel.BorderSizePixel = 0
panel.Parent = microGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 16)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(90, 200, 180)
panelStroke.Transparency = 0.4
panelStroke.Thickness = 2
panelStroke.Parent = panel

-- The water drop: a circular, blue-tinted viewport.
local viewport = Instance.new("ViewportFrame")
viewport.Name = "WaterDrop"
viewport.AnchorPoint = Vector2.new(0.5, 0.5)
viewport.Position = UDim2.fromScale(0.5, 0.54)
viewport.Size = UDim2.fromScale(0.92, 0.82)
viewport.BackgroundColor3 = Color3.fromRGB(10, 30, 46)
viewport.BorderSizePixel = 0
viewport.Ambient = Color3.fromRGB(150, 190, 210)
viewport.LightColor = Color3.fromRGB(255, 255, 255)
viewport.LightDirection = Vector3.new(-0.4, -1, -0.2)
viewport.Parent = panel

local dropCorner = Instance.new("UICorner")
dropCorner.CornerRadius = UDim.new(0, 12)
dropCorner.Parent = viewport

local vpCamera = Instance.new("Camera")
vpCamera.FieldOfView = 60
vpCamera.Parent = viewport
viewport.CurrentCamera = vpCamera

-- Header + live readout.
local title = Instance.new("TextLabel")
title.Name = "Title"
title.AnchorPoint = Vector2.new(0.5, 0)
title.Position = UDim2.fromScale(0.5, 0.02)
title.Size = UDim2.fromScale(0.9, 0.08)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextScaled = true
title.TextColor3 = Color3.fromRGB(190, 240, 230)
title.Text = "Microscope — Drop of Water"
title.Parent = panel

local readout = Instance.new("TextLabel")
readout.Name = "Readout"
readout.AnchorPoint = Vector2.new(0.5, 1)
readout.Position = UDim2.fromScale(0.5, 0.99)
readout.Size = UDim2.fromScale(0.9, 0.06)
readout.BackgroundTransparency = 1
readout.Font = Enum.Font.GothamSemibold
readout.TextScaled = true
readout.TextColor3 = Color3.fromRGB(150, 200, 220)
readout.Text = "No life yet — create a cell to populate the sample."
readout.Parent = panel

local hint = Instance.new("TextLabel")
hint.Name = "Hint"
hint.AnchorPoint = Vector2.new(1, 0)
hint.Position = UDim2.fromScale(0.98, 0.02)
hint.Size = UDim2.fromScale(0.2, 0.05)
hint.BackgroundTransparency = 1
hint.Font = Enum.Font.Gotham
hint.TextScaled = true
hint.TextColor3 = Color3.fromRGB(120, 150, 165)
hint.Text = "[M] close"
hint.Parent = panel

-- ---- Microscope: cells, organelles, zoom --------------------------------------
-- Each microscope cell mirrors a REAL cell (matched by array index): it draws only
-- the organelles that cell has actually purchased in the upgrade path — so a freshly
-- created Archaea Cell is a bare blob, and organelles appear one at a time as the
-- player buys them. (`cytoplasm` isn't a discrete part — it fills/opacifies the body.)
--
-- An organelle ALSO hides once the population is large enough that the lens has
-- zoomed too far out to make it out; `ORG_ZOOM_MAX` is that per-organelle cell-count
-- ceiling. So an organelle shows iff: purchased AND population ≤ its zoom ceiling.
local ORG_ZOOM_MAX = {
	membrane     = 200, -- the cell outline reads longest
	cytoplasm    = 200,
	ribosomes    = 20,  -- tiny specks: only the closest zoom
	nucleoid     = 50,
	plasmids     = 20,
	mitochondria = 50,
	nucleus      = 60,  -- the prominent core reads a touch longer
}

-- Camera zoom range (studs from the sample). Near = a single cell fills the frame
-- (organelles legible); far = a living field of dots. Mapped from population on a
-- log curve so each ~decade of cells pulls the lens back another step.
local ZOOM_NEAR = 9
local ZOOM_FAR  = 140

type MicroCell = {
	model: Model,
	body: BasePart,
	cellId: number, -- the real cell this mirrors
	sig: string,    -- last-built signature (rebuild organelles when it changes)
	pos: Vector3,
	vel: Vector3,
}

local microCells: { MicroCell } = {}
local microWorld = Instance.new("Model") -- holds the swimming cells inside the viewport
microWorld.Name = "Cells"
microWorld.Parent = viewport
local microRng = Random.new()

-- Camera distance is TweenService-animated via this NumberValue, which the render
-- loop reads each frame — so the zoom glides smoothly as the population changes.
local zoomValue = Instance.new("NumberValue")
zoomValue.Value = ZOOM_NEAR

local function targetZoomFor(count: number): number
	return math.clamp(ZOOM_NEAR + 21 * math.log10(math.max(count, 1)), ZOOM_NEAR, ZOOM_FAR)
end

local function updateZoom(animate: boolean)
	local target = targetZoomFor(state.totalCount)
	if animate then
		TweenService:Create(
			zoomValue,
			TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Value = target }
		):Play()
	else
		zoomValue.Value = target
	end
end

-- The swim box grows with the zoom, but SUB-LINEARLY (^0.65), so as the lens pulls
-- back the cells pack closer together in the frame — a sparse few up close becoming
-- dense clusters and finally a packed field at the far end.
local function currentRegion(): Vector3
	return MICRO_BASE_REGION * ((zoomValue.Value / ZOOM_NEAR) ^ 0.65)
end

-- A new cell's spawn point: budding off a parent (division), or random in the box.
local function newCellPosition(near: Vector3?): Vector3
	local reg = currentRegion()
	if near then
		local off = Vector3.new(microRng:NextNumber(-1, 1), microRng:NextNumber(-1, 1), microRng:NextNumber(-1, 1))
		if off.Magnitude < 0.01 then off = Vector3.xAxis end
		return near + off.Unit * (reg.X * 0.05)
	end
	return Vector3.new(
		(microRng:NextNumber() - 0.5) * reg.X,
		(microRng:NextNumber() - 0.5) * reg.Y,
		(microRng:NextNumber() - 0.5) * reg.Z
	)
end

-- How many organelle zoom ceilings the population has passed — part of a cell's draw
-- signature, so crossing a ceiling rebuilds the cells (organelles drop away).
local function zoomBucket(count: number): number
	local b = 0
	for _, ceiling in pairs(ORG_ZOOM_MAX) do
		if count > ceiling then b += 1 end
	end
	return b
end

-- A cell's draw signature: stage + organelles purchased + zoom bucket. When it
-- changes, that cell's organelles are rebuilt.
local function cellSignature(rc): string
	return rc.stage .. "/" .. tostring(rc.purchasedCount) .. "/" .. tostring(zoomBucket(state.totalCount))
end

-- The cell's base colour (by its own stage) tinted toward white.
local function tintFor(rc, amount: number): Color3
	return colorForDominant(rc.stage):Lerp(Color3.new(1, 1, 1), amount)
end

-- One anchored organelle ball at a fixed LOCAL offset from the body. The model is
-- PivotTo'd as a unit each frame, so offsets are set once here. Every offset stays
-- inside the body radius, so nothing pokes out of the cell.
local function makeOrg(model, name, color, diameter, offset, material, transparency)
	local p = Instance.new("Part")
	p.Name = "Org_" .. name
	p.Shape = Enum.PartType.Ball
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CastShadow = false
	p.Material = material or Enum.Material.Neon
	p.Color = color
	p.Transparency = transparency or 0
	p.Size = Vector3.one * diameter
	p.CFrame = CFrame.new(offset)
	p.Parent = model
	return p
end

-- (Re)build a cell's organelles from the REAL cell's PURCHASED set: an organelle is
-- drawn only if the player has bought it AND the population is still within its zoom
-- ceiling. Everything is arranged neatly inside the body. `fadeIn` eases new parts in.
local function buildCellOrganelles(model: Model, body: BasePart, rc, fadeIn: boolean)
	local R = body.Size.X * 0.5
	local count = state.totalCount
	local purchased = rc.purchased or {}
	local function vis(id: string): boolean
		return purchased[id] == true and count <= (ORG_ZOOM_MAX[id] or 0)
	end

	local fresh: { BasePart } = {}
	local function org(name, color, diameter, offset, material, transparency)
		table.insert(fresh, makeOrg(model, name, color, diameter, offset, material, transparency))
	end

	-- Cytoplasm: not a part — it FILLS the cell, so the body reads more opaque.
	body.Transparency = vis("cytoplasm") and 0.12 or 0.4

	-- Membrane: a thin glowing rim right at the cell surface (subtle, not bulging).
	if vis("membrane") then
		org("membrane", tintFor(rc, 0.15), body.Size.X * 1.05, Vector3.zero, Enum.Material.ForceField, 0.5)
	end
	-- Plasmids: a neat equatorial ring of small beads, well inside the membrane.
	if vis("plasmids") then
		for i = 1, 5 do
			local a = (i / 5) * math.pi * 2
			org("plasmids", tintFor(rc, 0.2), R * 0.16, Vector3.new(math.cos(a) * R * 0.6, 0, math.sin(a) * R * 0.6))
		end
	end
	-- Ribosomes: a small even scatter of specks (golden-angle spread) inside the body.
	if vis("ribosomes") then
		for i = 1, 6 do
			local a = i * 2.399963 -- golden angle → even, non-clumpy spread
			local rad = R * 0.52 * math.sqrt(i / 6)
			org("ribosomes", Color3.fromRGB(195, 255, 210), R * 0.13,
				Vector3.new(math.cos(a) * rad, ((i % 2 == 0) and 1 or -1) * R * 0.14, math.sin(a) * rad))
		end
	end
	-- Mitochondria: two warm blobs tucked inside, opposite each other.
	if vis("mitochondria") then
		for i = 1, 2 do
			local a = i * math.pi
			org("mitochondria", Color3.fromRGB(255, 170, 80), R * 0.36,
				Vector3.new(math.cos(a) * R * 0.42, math.sin(a) * R * 0.18, 0))
		end
	end
	-- Nucleoid: a soft dense core. Nudged aside if a true nucleus is also present.
	if vis("nucleoid") then
		local off = (purchased["nucleus"] == true) and Vector3.new(R * 0.18, 0, 0) or Vector3.zero
		org("nucleoid", tintFor(rc, 0.25), R * 0.5, off, Enum.Material.Neon, 0.25)
	end
	-- Nucleus: the prominent central core.
	if vis("nucleus") then
		org("nucleus", tintFor(rc, 0.4), R * 0.82, Vector3.zero, Enum.Material.Neon, 0)
	end

	if fadeIn then
		for _, p in fresh do
			local target = p.Transparency
			p.Transparency = 1
			TweenService:Create(p, TweenInfo.new(0.35, Enum.EasingStyle.Quad), { Transparency = target }):Play()
		end
	end
end

-- Build a cell model (bare body + its purchased organelles) for real cell `rc`.
local function buildMicroCellModel(rc): (Model, BasePart)
	local model = Instance.new("Model")
	local size = (rc.stage == OrganelleData.STAGE_EUKARYOTIC) and 1.7 or 1.2

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Ball
	body.Anchored = true
	body.CanCollide = false
	body.CanQuery = false
	body.CastShadow = false
	body.Material = Enum.Material.SmoothPlastic
	body.Color = colorForDominant(rc.stage)
	body.Size = Vector3.one * size
	model.PrimaryPart = body
	body.Parent = model

	buildCellOrganelles(model, body, rc, false)
	model.Parent = microWorld
	return model, body
end

-- Create a microscope cell mirroring real cell `rc`. A genuinely new cell buds off a
-- random existing cell and grows into place — a visible division.
local function createMicroCell(rc, animateDivision: boolean): MicroCell
	local parent = (animateDivision and #microCells > 0) and microCells[microRng:NextInteger(1, #microCells)] or nil
	local pos = newCellPosition(parent and parent.pos or nil)
	local model, body = buildMicroCellModel(rc)
	model:PivotTo(CFrame.new(pos))

	local cell: MicroCell = {
		model = model,
		body = body,
		cellId = rc.id,
		sig = cellSignature(rc),
		pos = pos,
		vel = Vector3.new(microRng:NextNumber(-1, 1), microRng:NextNumber(-1, 1), microRng:NextNumber(-1, 1)) * 2,
	}

	if parent then
		local full = body.Size
		body.Size = full * 0.25
		TweenService:Create(body, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Size = full }):Play()
	end
	return cell
end

-- Rebuild a cell's organelles in place (keeps its body + position) when its real cell
-- changed — bought an organelle, evolved — or the zoom bucket shifted.
local function rebuildMicroCellVisual(mc: MicroCell, rc)
	local size = (rc.stage == OrganelleData.STAGE_EUKARYOTIC) and 1.7 or 1.2
	mc.body.Size = Vector3.one * size
	mc.body.Color = colorForDominant(rc.stage)
	for _, ch in mc.model:GetChildren() do
		if ch ~= mc.body and ch:IsA("BasePart") then
			ch:Destroy()
		end
	end
	buildCellOrganelles(mc.model, mc.body, rc, true)
	mc.cellId = rc.id
	mc.sig = cellSignature(rc)
end

local function clearMicroCells()
	for _, cell in microCells do
		cell.model:Destroy()
	end
	table.clear(microCells)
end

-- Accurate readout: shows the real cell count, noting "(capped)" only when the
-- population exceeds what we can draw — the number never overstates the cells.
local lastMicroCount = -1
local function refreshMicroReadout()
	if state.totalCount <= 0 then
		readout.Text = "No life yet — create a cell to populate the sample."
	elseif lastMicroCount < state.totalCount then
		readout.Text = string.format(
			"Cells: %d   ·   showing %d (capped)   ·   dominant: %s",
			state.totalCount, lastMicroCount, state.dominant or "—"
		)
	else
		readout.Text = string.format(
			"Cells: %d   ·   dominant: %s",
			state.totalCount, state.dominant or "—"
		)
	end
end

-- Bring the sample in line with the REAL cells: microscope cell i mirrors real cell
-- i, drawing exactly that cell's purchased organelles. Newly-appeared cells animate
-- as divisions; cells whose real counterpart changed (bought an organelle / evolved /
-- crossed a zoom ceiling) are rebuilt in place; the camera eases to the new distance.
local lastShown = 0
local function syncMicroSample(animate: boolean)
	local cells = state.cells
	local shown = math.min(#cells, MICRO_MAX_CELLS)

	for i = 1, shown do
		local rc = cells[i]
		local mc = microCells[i]
		if not mc then
			microCells[i] = createMicroCell(rc, animate and i > lastShown)
		elseif mc.cellId ~= rc.id or mc.sig ~= cellSignature(rc) then
			rebuildMicroCellVisual(mc, rc)
		end
	end
	for i = #microCells, shown + 1, -1 do
		microCells[i].model:Destroy()
		microCells[i] = nil
	end

	updateZoom(animate)
	lastMicroCount = shown
	lastShown = shown
	refreshMicroReadout()
end

-- ---- Multicellular visual progression in the Microscope (Tier 1C) -------------
-- Each upgrade adds a layer to the swimming sample (driven by state.upgrades 0..6):
--   1 Adhesion        → cells pull together into a cluster (no longer free-floating)
--   2 Signaling       → signal pulses ripple out from the cluster centre
--   3 Matrix          → a translucent extracellular-matrix hull wraps the cluster
--   4 Cell Cycle      → the cluster breathes — cells contract/expand in unison
--   5 Differentiation → cells take on varied tints (they specialize)
--   6 Tissue          → the body tightens + the matrix hull brightens (organized tissue)

-- Translucent extracellular-matrix hull around the cluster (shown from upgrade #3).
local matrixHull = Instance.new("Part")
matrixHull.Name = "MatrixHull"
matrixHull.Shape = Enum.PartType.Ball
matrixHull.Anchored = true
matrixHull.CanCollide = false
matrixHull.CanQuery = false
matrixHull.CastShadow = false
matrixHull.Material = Enum.Material.ForceField
matrixHull.Color = Color3.fromRGB(150, 215, 205)
matrixHull.Transparency = 1
matrixHull.Size = Vector3.one
matrixHull.Parent = microWorld

-- A one-shot expanding "signal pulse" ring from the cluster centre (upgrade #2).
local function emitSignalPulse(center: Vector3, color: Color3)
	local ring = Instance.new("Part")
	ring.Shape = Enum.PartType.Ball
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CastShadow = false
	ring.Material = Enum.Material.ForceField
	ring.Color = color
	ring.Transparency = 0.45
	ring.Size = Vector3.one * 2
	ring.CFrame = CFrame.new(center)
	ring.Parent = microWorld
	local grow = TweenService:Create(ring,
		TweenInfo.new(1.0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = Vector3.one * 30, Transparency = 1 })
	grow:Play()
	grow.Completed:Connect(function()
		ring:Destroy()
	end)
end

-- Differentiation tint (upgrade #5): a stable per-index colour shift toward warm/cool.
local function differentiatedColor(i: number): Color3
	local base = colorForDominant(state.dominant)
	local k = (i % 3)
	if k == 0 then
		return base:Lerp(Color3.fromRGB(255, 200, 120), 0.45) -- warm specialization
	elseif k == 1 then
		return base:Lerp(Color3.fromRGB(150, 200, 255), 0.35) -- cool specialization
	end
	return base
end

-- Brownian motion + multicellular layers + camera framing while the scope is open.
local microRunning = false
local function runMicroSim()
	if microRunning then return end
	microRunning = true
	task.spawn(function()
		local signalTimer = 0
		while microGui.Enabled do
			local dt = RunService.Heartbeat:Wait()
			local half = currentRegion() * 0.5
			local n = #microCells
			local upg = state.upgrades
			local structure = math.clamp(upg / MulticellularData.COUNT, 0, 1)

			-- Cluster centre — cells pull toward it as the body adheres/organizes.
			local center = Vector3.zero
			if n > 0 then
				for _, c in microCells do
					center += c.pos
				end
				center /= n
			end
			-- Cell-cycle "breathing" (upgrade #4): the pull strength oscillates so the
			-- whole cluster contracts and expands in unison.
			local breathe = (upg >= 4) and (0.55 + 0.45 * math.sin(os.clock() * 1.4)) or 1
			local pull = structure * 2.4 * breathe
			local jitterScale = 18 * (1 - structure * 0.65) -- calmer motion as it organizes

			local maxR = 0
			for i, cell in microCells do
				local jitter = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * jitterScale
				cell.vel = (cell.vel + jitter * dt) * (0.92 - structure * 0.05)
				if pull > 0 then
					cell.vel += (center - cell.pos) * pull * dt -- adhesion → clustering
				end
				local np = cell.pos + cell.vel * dt
				if math.abs(np.X) > half.X then cell.vel = Vector3.new(-cell.vel.X, cell.vel.Y, cell.vel.Z) end
				if math.abs(np.Y) > half.Y then cell.vel = Vector3.new(cell.vel.X, -cell.vel.Y, cell.vel.Z) end
				if math.abs(np.Z) > half.Z then cell.vel = Vector3.new(cell.vel.X, cell.vel.Y, -cell.vel.Z) end
				cell.pos = Vector3.new(
					math.clamp(cell.pos.X + cell.vel.X * dt, -half.X, half.X),
					math.clamp(cell.pos.Y + cell.vel.Y * dt, -half.Y, half.Y),
					math.clamp(cell.pos.Z + cell.vel.Z * dt, -half.Z, half.Z)
				)
				if cell.model.PrimaryPart then
					cell.model:PivotTo(CFrame.new(cell.pos)) -- moves body + organelles rigidly
				end
				-- Differentiation (upgrade #5): specialize cell colours by index.
				if cell.body then
					cell.body.Color = (upg >= 5) and differentiatedColor(i) or colorForDominant(state.dominant)
				end
				local d = (cell.pos - center).Magnitude
				if d > maxR then maxR = d end
			end

			-- Extracellular matrix hull (upgrade #3; brighter at tissue, upgrade #6).
			if upg >= 3 and n > 0 then
				matrixHull.CFrame = CFrame.new(center)
				matrixHull.Size = Vector3.one * (maxR * 2 + 4)
				matrixHull.Transparency = (upg >= 6) and 0.7 or 0.85
			else
				matrixHull.Transparency = 1
			end

			-- Intercellular signaling (upgrade #2): periodic pulse from the centre.
			if upg >= 2 and n > 0 then
				signalTimer += dt
				if signalTimer >= 1.8 then
					signalTimer = 0
					emitSignalPulse(center, colorForDominant(state.dominant))
				end
			end

			-- Camera frames the sample from the current (tweened) zoom distance.
			local dist = zoomValue.Value
			local a = os.clock() * 0.12
			vpCamera.CFrame = CFrame.lookAt(
				Vector3.new(math.sin(a) * dist * 0.08, dist * 0.06, dist),
				Vector3.zero
			)
		end
		microRunning = false
	end)
end

-- =================================================================================
--  MODE TOGGLE + TRANSITION
-- =================================================================================
local microOpen = false

-- Project the vessel's current world position to a screen scale (for the zoom origin).
local function vesselScreenScale(): Vector2
	local camera = Workspace.CurrentCamera
	if not camera then return Vector2.new(0.78, 0.7) end
	local sp = camera:WorldToViewportPoint(orb.Position)
	local vp = camera.ViewportSize
	if vp.X <= 0 or vp.Y <= 0 then return Vector2.new(0.78, 0.7) end
	return Vector2.new(math.clamp(sp.X / vp.X, 0, 1), math.clamp(sp.Y / vp.Y, 0, 1))
end

local TWEEN_OPEN = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_CLOSE = TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local function setMicroOpen(open: boolean)
	if open == microOpen then return end
	microOpen = open

	if open then
		syncMicroSample(false) -- build the sample to the current population (instant zoom)
		microGui.Enabled = true
		runMicroSim()

		-- Zoom IN from the vessel: start the panel tiny at the orb's screen spot,
		-- grow to full. Backdrop fades in alongside.
		local origin = vesselScreenScale()
		panel.AnchorPoint = Vector2.new(0.5, 0.5)
		panel.Position = UDim2.fromScale(origin.X, origin.Y)
		panel.Size = UDim2.fromScale(0.04, 0.04)
		backdrop.BackgroundTransparency = 1

		TweenService:Create(panel, TWEEN_OPEN, {
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.72, 0.78),
		}):Play()
		TweenService:Create(backdrop, TWEEN_OPEN, { BackgroundTransparency = 0.35 }):Play()

		-- The vessel briefly flares as we "dive in".
		burst:Emit(20)
	else
		-- Zoom back OUT to the vessel, then hide.
		local origin = vesselScreenScale()
		local shrink = TweenService:Create(panel, TWEEN_CLOSE, {
			Position = UDim2.fromScale(origin.X, origin.Y),
			Size = UDim2.fromScale(0.04, 0.04),
		})
		TweenService:Create(backdrop, TWEEN_CLOSE, { BackgroundTransparency = 1 }):Play()
		shrink:Play()
		shrink.Completed:Connect(function()
			if not microOpen then
				microGui.Enabled = false -- stops runMicroSim's loop
				clearMicroCells()        -- free the cell parts while closed
				lastShown = 0            -- next open rebuilds from scratch
			end
		end)
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if MICRO_TOGGLE_KEYS[input.KeyCode] then
		setMicroOpen(not microOpen)
	end
end)

-- =================================================================================
--  DATA WIRING  (derive shared state from ConverterUpdate; bursts from events)
-- =================================================================================
local function recomputeState(cells, upgrades)
	state.upgrades = math.clamp(upgrades or 0, 0, MulticellularData.COUNT)
	local total = #cells
	local archaea, eukaryotic = 0, 0
	for _, cell in ipairs(cells) do
		if cell.stage == OrganelleData.STAGE_EUKARYOTIC then
			eukaryotic += 1
		else
			archaea += 1
		end
	end

	local dominant = nil
	if total > 0 then
		dominant = (eukaryotic >= archaea) and OrganelleData.STAGE_EUKARYOTIC or OrganelleData.STAGE_ARCHAEA
	end

	local prevTotal = state.totalCount
	state.totalCount = total
	state.dominant = dominant
	state.tier = tierForCount(total)
	state.cells = cells -- per-cell purchased data drives the microscope organelles

	updateVesselAppearance()

	-- A new cell appeared → celebratory burst on the vessel.
	if total > prevTotal then
		burst:Emit(16)
	end

	-- Keep the open microscope sample in step in real time: mirror each real cell,
	-- draw exactly its purchased organelles, animate new cells as divisions, ease zoom.
	if microGui.Enabled then
		syncMicroSample(true)
	end
end

updateVesselAppearance()

-- =================================================================================
--  CELEBRATION TOASTS  (moved here from the removed CellVisuals; the vessel is now
--  the single home for evolution feedback — bursts on the orb + a floating toast).
-- =================================================================================
local toastGui = Instance.new("ScreenGui")
toastGui.Name = "BiosphereToasts"
toastGui.ResetOnSpawn = false
toastGui.IgnoreGuiInset = true
toastGui.DisplayOrder = 40
toastGui.Parent = playerGui

local function playToast(text: string)
	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromScale(0.5, 0.32)
	label.Size = UDim2.fromOffset(420, 44)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 26
	label.TextColor3 = EUKARYOTIC_COLOR
	label.TextStrokeColor3 = Color3.fromRGB(10, 30, 18)
	label.TextStrokeTransparency = 0.2
	label.Text = text
	label.Parent = toastGui

	local rise = TweenService:Create(
		label,
		TweenInfo.new(2.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = UDim2.fromScale(0.5, 0.22), TextTransparency = 1, TextStrokeTransparency = 1 }
	)
	rise:Play()
	rise.Completed:Connect(function()
		label:Destroy()
	end)
end

-- Bigger two-line announcement for the one-time Eukaryotic Cascade.
local function playCascadeToast(titleText: string, subtitle: string)
	local holder = Instance.new("Frame")
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.fromScale(0.5, 0.34)
	holder.Size = UDim2.fromOffset(560, 76)
	holder.BackgroundTransparency = 1
	holder.Parent = toastGui

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 0, 44)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 32
	titleLabel.TextColor3 = EUKARYOTIC_COLOR
	titleLabel.TextStrokeColor3 = Color3.fromRGB(10, 30, 18)
	titleLabel.TextStrokeTransparency = 0.15
	titleLabel.Text = titleText
	titleLabel.Parent = holder

	local subLabel = Instance.new("TextLabel")
	subLabel.Position = UDim2.fromOffset(0, 44)
	subLabel.Size = UDim2.new(1, 0, 0, 26)
	subLabel.BackgroundTransparency = 1
	subLabel.Font = Enum.Font.GothamSemibold
	subLabel.TextSize = 18
	subLabel.TextColor3 = Color3.fromRGB(255, 220, 140)
	subLabel.TextStrokeColor3 = Color3.fromRGB(30, 24, 8)
	subLabel.TextStrokeTransparency = 0.3
	subLabel.Text = subtitle
	subLabel.Parent = holder

	local riseInfo = TweenInfo.new(3.0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(holder, riseInfo, { Position = UDim2.fromScale(0.5, 0.24) }):Play()
	for _, lbl in { titleLabel, subLabel } do
		TweenService:Create(lbl, riseInfo, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	end
	task.delay(3.0, function()
		holder:Destroy()
	end)
end

task.spawn(function()
	local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))

	Remotes.ConverterUpdate.OnClientEvent:Connect(function(data)
		recomputeState(data.cells or {}, data.multicellularUpgrades or 0)
	end)

	-- A single cell finished its organelle path → flare the vessel + announce it.
	Remotes.CellEvolved.OnClientEvent:Connect(function()
		burst:Emit(24)
		playToast("Eukaryotic Cell Unlocked!")
	end)

	-- A multicellular upgrade was bought → flare the vessel + name it (Tier 1C).
	Remotes.UpgradePurchased.OnClientEvent:Connect(function(data)
		burst:Emit(30)
		local upgrade = data and MulticellularData.at(data.step)
		local name = upgrade and upgrade.name or "Multicellular Upgrade"
		if data and data.step == MulticellularData.COUNT then
			playCascadeToast("Multicellular Organism!", name .. " — the body is whole")
		else
			playToast(name)
		end
	end)

	-- The one-time Eukaryotic Cascade → bigger flare + two-line announcement.
	Remotes.CascadeTriggered.OnClientEvent:Connect(function(data)
		burst:Emit(40)
		local count = data and data.count or 0
		local mult = data and data.dustMultiplier or 1
		local titleText = (count > 0) and "Eukaryotic Evolution Cascade!" or "First Eukaryotic Cell!"
		local subtitle = (count > 0)
			and string.format("%d cell%s evolved   ·   Dust Value ×%d", count, count == 1 and "" or "s", mult)
			or string.format("Dust Value ×%d", mult)
		playCascadeToast(titleText, subtitle)
	end)
end)
