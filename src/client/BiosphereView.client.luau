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

local MICRO_MAX_CELLS = 50      -- hard cap on cells drawn in the microscope (perf)
local MICRO_REGION = Vector3.new(22, 13, 9) -- swim box (studs) inside the viewport
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

	-- Target spot: a fixed offset in camera space (a companion orb at the lower right).
	local targetCFrame = camera.CFrame * CFrame.new(VESSEL_OFFSET)
	local goalPos = targetCFrame.Position
	local alpha = math.clamp(VESSEL_FOLLOW_SPEED * dt, 0, 1)
	local pos = orb.Position:Lerp(goalPos, alpha)

	-- Heartbeat pulse (double-thump feel via |sin| shaped curve).
	local t = os.clock()
	local beat = math.abs(math.sin(t * HEARTBEAT_RATE * math.pi))
	local pulse = 1 + beat * HEARTBEAT_AMPLITUDE * (state.totalCount > 0 and 1 or 0.3)
	orb.Size = Vector3.one * (VESSEL_BASE_SIZE * pulse)
	orb.CFrame = CFrame.new(pos)

	-- Ease the glow toward the tier's target so changes feel organic.
	curLight += (def.light - curLight) * math.clamp(6 * dt, 0, 1)
	orbLight.Brightness = curLight * (0.85 + beat * 0.3)
	orbLight.Range = VESSEL_BASE_SIZE * (3 + state.tier)

	-- Swirl: rotate the speckle cloud; place each speckle at its stable local offset.
	speckleSpin += def.swirl * dt
	local spin = CFrame.Angles(0, speckleSpin, speckleSpin * 0.4)
	for _, p in speckleParts do
		local off = p:GetAttribute("LocalOffset")
		if typeof(off) == "Vector3" then
			-- Gentle internal drift so the cloud feels alive at higher tiers.
			local wobble = Vector3.new(
				math.sin(t * 1.3 + off.X) * 0.04,
				math.cos(t * 1.1 + off.Y) * 0.04,
				math.sin(t * 0.9 + off.Z) * 0.04
			) * def.swirl
			p.CFrame = CFrame.new(pos) * spin * CFrame.new(off + wobble)
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

-- ---- Microscope cell sim ------------------------------------------------------
type MicroCell = {
	model: Model,
	pos: Vector3,
	vel: Vector3,
}

local microCells: { MicroCell } = {}
local microWorld = Instance.new("Model") -- holds the swimming cells inside the viewport
microWorld.Name = "Cells"
microWorld.Parent = viewport

-- How many cells to draw: exactly the player's actual cell count, capped for perf.
-- Never more than they really own — the sample is accurate, not inflated.
local function microCountForPopulation(n: number): number
	return math.clamp(n, 0, MICRO_MAX_CELLS)
end

-- Build one microscope cell: a translucent body + nucleus + (for eukaryotes) a few
-- organelle specks, so richer life reads as more complex under the lens.
local function buildMicroCell(complex: boolean, color: Color3): Model
	local model = Instance.new("Model")

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Ball
	body.Anchored = true
	body.CanCollide = false
	body.CanQuery = false
	body.CastShadow = false
	body.Material = Enum.Material.SmoothPlastic
	body.Color = color
	body.Transparency = 0.35
	body.Size = Vector3.one * (complex and 1.6 or 1.1)
	model.PrimaryPart = body
	body.Parent = model

	-- Nucleus.
	local nucleus = Instance.new("Part")
	nucleus.Name = "Nucleus"
	nucleus.Shape = Enum.PartType.Ball
	nucleus.Anchored = true
	nucleus.CanCollide = false
	nucleus.CanQuery = false
	nucleus.CastShadow = false
	nucleus.Material = Enum.Material.Neon
	nucleus.Color = color:Lerp(Color3.new(1, 1, 1), 0.3)
	nucleus.Size = body.Size * 0.42
	nucleus.Parent = model

	if complex then
		for _ = 1, 4 do
			local org = Instance.new("Part")
			org.Name = "Organelle"
			org.Shape = Enum.PartType.Ball
			org.Anchored = true
			org.CanCollide = false
			org.CanQuery = false
			org.CastShadow = false
			org.Material = Enum.Material.Neon
			org.Color = Color3.fromRGB(255, 190, 90)
			org.Size = body.Size * 0.14
			org.Parent = model
		end
	end

	model.Parent = microWorld
	return model
end

-- Place a cell's parts at a center point (body + nucleus + organelles scattered).
local function placeMicroCell(cell: MicroCell)
	local body = cell.model.PrimaryPart
	if not body then return end
	body.CFrame = CFrame.new(cell.pos)
	local r = body.Size.X * 0.5
	for _, part in cell.model:GetChildren() do
		if part:IsA("BasePart") and part ~= body then
			if part.Name == "Organelle" then
				part.CFrame = body.CFrame * CFrame.new(
					(math.random() - 0.5) * r,
					(math.random() - 0.5) * r,
					(math.random() - 0.5) * r
				)
			else
				part.CFrame = body.CFrame -- nucleus stays centered
			end
		end
	end
end

local function clearMicroCells()
	for _, cell in microCells do
		cell.model:Destroy()
	end
	table.clear(microCells)
end

-- Accurate readout: shows the real cell count, and only notes "(capped)" when the
-- population exceeds what we can draw — so the number never overstates the cells.
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

-- Rebuild the swimming sample to match the current population + dominant form.
local function rebuildMicroSample()
	local target = microCountForPopulation(state.totalCount)
	local color = colorForDominant(state.dominant)
	local complex = state.dominant == OrganelleData.STAGE_EUKARYOTIC

	clearMicroCells()
	local rng = Random.new()
	for _ = 1, target do
		local pos = Vector3.new(
			(rng:NextNumber() - 0.5) * MICRO_REGION.X,
			(rng:NextNumber() - 0.5) * MICRO_REGION.Y,
			(rng:NextNumber() - 0.5) * MICRO_REGION.Z
		)
		local cell: MicroCell = {
			model = buildMicroCell(complex, color),
			pos = pos,
			vel = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-1, 1), rng:NextNumber(-1, 1)) * 2,
		}
		placeMicroCell(cell)
		table.insert(microCells, cell)
	end
	lastMicroCount = target
	refreshMicroReadout()
end

-- The viewport camera pulls BACK as the population climbs, showing a larger sample.
local function microCameraDistance(): number
	-- zoom out smoothly with log population: ~26 studs empty → ~46 at huge counts.
	local zoom = 26 + math.clamp(math.log10(math.max(state.totalCount, 1)) * 2.4, 0, 22)
	return zoom
end

-- Brownian motion + camera framing while the microscope is open.
local microRunning = false
local function runMicroSim()
	if microRunning then return end
	microRunning = true
	task.spawn(function()
		while microGui.Enabled do
			local dt = RunService.Heartbeat:Wait()
			local half = MICRO_REGION * 0.5
			for _, cell in microCells do
				-- Brownian: random nudge + mild damping, bounce off the box walls.
				local jitter = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 18
				cell.vel = (cell.vel + jitter * dt) * 0.92
				local nextPos = cell.pos + cell.vel * dt
				if math.abs(nextPos.X) > half.X then cell.vel = Vector3.new(-cell.vel.X, cell.vel.Y, cell.vel.Z) end
				if math.abs(nextPos.Y) > half.Y then cell.vel = Vector3.new(cell.vel.X, -cell.vel.Y, cell.vel.Z) end
				if math.abs(nextPos.Z) > half.Z then cell.vel = Vector3.new(cell.vel.X, cell.vel.Y, -cell.vel.Z) end
				cell.pos = Vector3.new(
					math.clamp(cell.pos.X + cell.vel.X * dt, -half.X, half.X),
					math.clamp(cell.pos.Y + cell.vel.Y * dt, -half.Y, half.Y),
					math.clamp(cell.pos.Z + cell.vel.Z * dt, -half.Z, half.Z)
				)
				placeMicroCell(cell)
			end
			-- Slow orbit of the camera for a living, lens-drifting feel.
			local dist = microCameraDistance()
			local a = os.clock() * 0.15
			vpCamera.CFrame = CFrame.lookAt(
				Vector3.new(math.sin(a) * 3, 2, dist),
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
		rebuildMicroSample()
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
local function recomputeState(cells)
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

	updateVesselAppearance()

	-- A new cell appeared → celebratory burst on the vessel.
	if total > prevTotal then
		burst:Emit(16)
	end

	-- Keep the open microscope sample in step with the population.
	if microGui.Enabled and microCountForPopulation(total) ~= lastMicroCount then
		rebuildMicroSample()
	elseif microGui.Enabled then
		refreshMicroReadout()
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
		recomputeState(data.cells or {})
	end)

	-- A single cell finished its organelle path → flare the vessel + announce it.
	Remotes.CellEvolved.OnClientEvent:Connect(function()
		burst:Emit(24)
		playToast("Eukaryotic Cell Unlocked!")
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
