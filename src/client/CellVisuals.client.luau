-- Cell visuals — per-cell, per-organelle life on the planet (Epic 3, Tier 1).
--
-- Renders the local player's Archaea/Eukaryotic cells as small glowing bodies
-- orbiting their planet. Each cell shows its OWN organelle state: every organelle
-- the player buys adds a cosmetic layer (membrane glow, inner cytoplasm, ribosome
-- dots, a brighter nucleoid core, plasmid rings, a warm mitochondrial glow, and a
-- bright nucleus), so a fully evolved Eukaryotic Cell looks visibly complex and
-- vibrant next to a fresh Archaea Cell. When a cell completes its evolution the
-- server fires CellEvolved and we play a green pulse + particle burst on that cell
-- and float a "Eukaryotic Cell Unlocked!" notification.
--
-- Driven entirely by the server's ConverterUpdate (cell list) + CellEvolved — this
-- script owns no economy logic. Self-contained LocalScript (like PlanetStageVisuals
-- / PlanetMarker): no Main wiring. Cosmetic, client-only parts; nothing replicates.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local OrganelleData = require(ReplicatedStorage:WaitForChild("OrganelleData"))

local player = Players.LocalPlayer

-- Tunables.
local MAX_RENDERED_CELLS = 36   -- cells beyond this still count economically; we just stop drawing them
local RING_SLOTS         = 12   -- cells per orbital ring around the planet
local RING_BASE_MULT     = 1.28 -- first ring radius = planetRadius * this
local RING_STEP_MULT     = 0.22 -- each extra ring pushes out this much * planetRadius
local CELL_SIZE_MULT     = 0.12 -- cell diameter = planetRadius * this (min CELL_SIZE_MIN)
local CELL_SIZE_MIN      = 1.6
local BOB_AMPLITUDE      = 0.06 -- gentle vertical bob, fraction of planetRadius
local BOB_SPEED          = 1.4

local ARCHAEA_COLOR    = Color3.fromRGB(96, 224, 184)
local EUKARYOTIC_COLOR = Color3.fromRGB(120, 245, 150)
local MITO_COLOR       = Color3.fromRGB(255, 170, 70)
local NUCLEUS_COLOR    = Color3.fromRGB(220, 255, 220)

-- ---- State --------------------------------------------------------------------
local cellsData = {}                 -- latest cells from ConverterUpdate
local cellModels: { [number]: Model } = {} -- cellId -> visual Model
local cellSig: { [number]: string } = {}   -- cellId -> last-built signature (avoid per-frame rebuild)

local folder = Instance.new("Folder")
folder.Name = "CellVisuals"
folder.Parent = Workspace

-- ---- Planet lookup (mirrors PlanetStageVisuals) -------------------------------
local function findLocalPlanet(): Model?
	local env = Workspace:FindFirstChild("SpaceEnvironment")
	local planets = env and env:FindFirstChild("PlayerPlanets")
	if not planets then
		return nil
	end
	for _, model in planets:GetChildren() do
		if model:IsA("Model") and model:GetAttribute("OwnerUserId") == player.UserId then
			return model
		end
	end
	return nil
end

local function planetRadius(planet: Model, body: BasePart): number
	local r = planet:GetAttribute("Radius")
	if typeof(r) == "number" and r > 0 then
		return r
	end
	return math.max(body.Size.X, body.Size.Y, body.Size.Z) * 0.5
end

-- ---- Cell appearance ----------------------------------------------------------
local function makeAccentPart(name: string, parent: Instance, color: Color3): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = Enum.PartType.Ball
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.Color = color
	p.Parent = parent
	return p
end

-- Build a cell's visual Model from scratch for the given organelle progress.
-- `ownedCount` (= purchasedCount) determines which organelles are present, since
-- they're always bought in OrganelleData order.
local function buildCellModel(cell, cellSizeStuds: number): Model
	local owned = {}
	for i = 1, math.min(cell.purchasedCount, OrganelleData.COUNT) do
		owned[OrganelleData.ORGANELLES[i].id] = true
	end
	local isEukaryotic = cell.stage == OrganelleData.STAGE_EUKARYOTIC

	local model = Instance.new("Model")
	model.Name = "Cell_" .. cell.id

	-- Core body. Brighter/larger as it gains organelles; greener once eukaryotic.
	local core = makeAccentPart("Core", model, isEukaryotic and EUKARYOTIC_COLOR or ARCHAEA_COLOR)
	core.Size = Vector3.one * cellSizeStuds
	-- Cytoplasm makes the body read as filled (more opaque); bare cells are wispier.
	core.Transparency = owned.cytoplasm and 0.1 or 0.35
	model.PrimaryPart = core

	-- Membrane: faint outer shell glow around the cell.
	if owned.membrane then
		local shell = makeAccentPart("Membrane", model, isEukaryotic and EUKARYOTIC_COLOR or ARCHAEA_COLOR)
		shell.Material = Enum.Material.ForceField
		shell.Size = Vector3.one * (cellSizeStuds * 1.5)
		shell.Transparency = 0.55
	end

	-- A PointLight whose glow strengthens with each organelle.
	local light = Instance.new("PointLight")
	light.Color = isEukaryotic and EUKARYOTIC_COLOR or ARCHAEA_COLOR
	light.Range = cellSizeStuds * (3 + cell.purchasedCount)
	light.Brightness = 1 + cell.purchasedCount * 0.4
	light.Parent = core

	-- Ribosomes: a scatter of tiny green dots inside/around the cell.
	if owned.ribosomes then
		for i = 1, 4 do
			local dot = makeAccentPart("Ribosome" .. i, model, EUKARYOTIC_COLOR)
			dot.Size = Vector3.one * (cellSizeStuds * 0.16)
			local a = (i / 4) * math.pi * 2
			dot.CFrame = core.CFrame * CFrame.new(
				math.cos(a) * cellSizeStuds * 0.3,
				math.sin(a * 1.7) * cellSizeStuds * 0.2,
				math.sin(a) * cellSizeStuds * 0.3
			)
		end
	end

	-- Nucleoid: a brighter, denser inner core.
	if owned.nucleoid then
		local nucleoid = makeAccentPart("Nucleoid", model, EUKARYOTIC_COLOR)
		nucleoid.Size = Vector3.one * (cellSizeStuds * 0.42)
		nucleoid.Transparency = 0.05
		nucleoid.CFrame = core.CFrame
	end

	-- Plasmids: thin ring structures circling the cell.
	if owned.plasmids then
		for i = 1, 8 do
			local bead = makeAccentPart("Plasmid" .. i, model, ARCHAEA_COLOR)
			bead.Shape = Enum.PartType.Ball
			bead.Size = Vector3.one * (cellSizeStuds * 0.12)
			local a = (i / 8) * math.pi * 2
			bead.CFrame = core.CFrame * CFrame.new(
				math.cos(a) * cellSizeStuds * 0.85,
				0,
				math.sin(a) * cellSizeStuds * 0.85
			)
		end
	end

	-- Mitochondria: warm orange-gold energy glow — the powerhouse.
	if owned.mitochondria then
		local mito = makeAccentPart("Mitochondria", model, MITO_COLOR)
		mito.Size = Vector3.one * (cellSizeStuds * 0.5)
		mito.Transparency = 0.25
		mito.CFrame = core.CFrame * CFrame.new(cellSizeStuds * 0.45, 0, 0)
		local mitoLight = Instance.new("PointLight")
		mitoLight.Color = MITO_COLOR
		mitoLight.Range = cellSizeStuds * 5
		mitoLight.Brightness = 2
		mitoLight.Parent = mito
	end

	-- Nucleus: a bright central core that makes the cell look fully mature.
	if owned.nucleus then
		local nucleus = makeAccentPart("Nucleus", model, NUCLEUS_COLOR)
		nucleus.Size = Vector3.one * (cellSizeStuds * 0.55)
		nucleus.Transparency = 0
		nucleus.CFrame = core.CFrame
		local nucLight = Instance.new("PointLight")
		nucLight.Color = NUCLEUS_COLOR
		nucLight.Range = cellSizeStuds * 7
		nucLight.Brightness = 3
		nucLight.Parent = nucleus
	end

	model.Parent = folder
	return model
end

-- Stable orbital offset (planet-local space) for the ordinal-th rendered cell.
local function cellOffset(ordinal: number, radius: number, t: number): CFrame
	local slot = (ordinal - 1) % RING_SLOTS
	local ring = math.floor((ordinal - 1) / RING_SLOTS)
	local ringRadius = radius * (RING_BASE_MULT + ring * RING_STEP_MULT)
	local angle = (slot / RING_SLOTS) * math.pi * 2 + ring * 0.4
	local bob = math.sin(t * BOB_SPEED + ordinal) * radius * BOB_AMPLITUDE
	return CFrame.new(
		math.cos(angle) * ringRadius,
		bob + ring * radius * 0.15,
		math.sin(angle) * ringRadius
	)
end

-- ---- Per-frame placement + lazy rebuild ---------------------------------------
RunService.Heartbeat:Connect(function()
	local planet = findLocalPlanet()
	local body = planet and planet.PrimaryPart
	if not (planet and body) then
		return
	end

	local radius = planetRadius(planet, body)
	local cellSize = math.max(radius * CELL_SIZE_MULT, CELL_SIZE_MIN)
	local t = os.clock()

	-- Track which cells are live this frame so we can prune removed ones.
	local seen = {}

	for ordinal, cell in ipairs(cellsData) do
		if ordinal > MAX_RENDERED_CELLS then
			break
		end
		seen[cell.id] = true

		-- Rebuild the model only when the cell's organelle state actually changed.
		local sig = cell.stage .. ":" .. tostring(cell.purchasedCount)
		if cellSig[cell.id] ~= sig then
			local old = cellModels[cell.id]
			if old then
				old:Destroy()
			end
			cellModels[cell.id] = buildCellModel(cell, cellSize)
			cellSig[cell.id] = sig
		end

		local model = cellModels[cell.id]
		if model and model.PrimaryPart then
			model:PivotTo(body.CFrame * cellOffset(ordinal, radius, t))
		end
	end

	-- Remove visuals for cells that no longer exist (or scrolled past the cap).
	for cellId, model in pairs(cellModels) do
		if not seen[cellId] then
			model:Destroy()
			cellModels[cellId] = nil
			cellSig[cellId] = nil
		end
	end
end)

-- ---- Evolution celebration ----------------------------------------------------
-- Floating "Eukaryotic Cell Unlocked!" toast (built once; each event spawns a label).
local toastGui = Instance.new("ScreenGui")
toastGui.Name = "CellEvolveToast"
toastGui.ResetOnSpawn = false
toastGui.IgnoreGuiInset = true
toastGui.DisplayOrder = 20
toastGui.Parent = player:WaitForChild("PlayerGui")

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

-- Bigger two-line announcement for the one-time Eukaryotic Cascade: a bold title
-- and a gold subtitle (cell count + new Dust Value). Rises and fades like playToast.
local function playCascadeToast(title: string, subtitle: string)
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
	titleLabel.Text = title
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

-- Green pulse + particle burst on a specific cell's body.
local function playBurst(model: Model)
	if not (model and model.PrimaryPart) then
		return
	end
	local origin = model:GetPivot()
	local size = model.PrimaryPart.Size.X

	-- Expanding, fading green shell.
	local pulse = Instance.new("Part")
	pulse.Shape = Enum.PartType.Ball
	pulse.Anchored = true
	pulse.CanCollide = false
	pulse.CanQuery = false
	pulse.CastShadow = false
	pulse.Material = Enum.Material.ForceField
	pulse.Color = EUKARYOTIC_COLOR
	pulse.Size = Vector3.one * size
	pulse.CFrame = origin
	pulse.Transparency = 0.2
	pulse.Parent = folder

	local grow = TweenService:Create(
		pulse,
		TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = Vector3.one * size * 6, Transparency = 1 }
	)
	grow:Play()
	grow.Completed:Connect(function()
		pulse:Destroy()
	end)

	-- One-shot particle burst.
	local emitterPart = Instance.new("Part")
	emitterPart.Anchored = true
	emitterPart.CanCollide = false
	emitterPart.CanQuery = false
	emitterPart.Transparency = 1
	emitterPart.Size = Vector3.one
	emitterPart.CFrame = origin
	emitterPart.Parent = folder

	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(EUKARYOTIC_COLOR)
	emitter.LightEmission = 1
	emitter.Lifetime = NumberRange.new(0.5, 1.0)
	emitter.Speed = NumberRange.new(size * 4, size * 8)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Rate = 0
	emitter.Size = NumberSequence.new(size * 0.4)
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Parent = emitterPart
	emitter:Emit(40)

	task.delay(1.2, function()
		emitterPart:Destroy()
	end)
end

-- ---- Remote wiring ------------------------------------------------------------
task.spawn(function()
	local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))

	Remotes.ConverterUpdate.OnClientEvent:Connect(function(data)
		cellsData = data.cells or {}
	end)

	Remotes.CellEvolved.OnClientEvent:Connect(function(data)
		playToast("Eukaryotic Cell Unlocked!")
		local model = data and cellModels[data.cellId]
		-- The model may rebuild this same frame from ConverterUpdate; try now and
		-- once more shortly after so the burst lands on the rebuilt eukaryote.
		playBurst(model)
		task.delay(0.1, function()
			playBurst(cellModels[data and data.cellId])
		end)
	end)

	-- The one-time Eukaryotic Cascade: every cell turns Eukaryotic at once. Announce
	-- it as a single big moment and burst across every affected cell (the trigger
	-- cell plus all the cells the cascade swept up).
	Remotes.CascadeTriggered.OnClientEvent:Connect(function(data)
		local count = data and data.count or 0
		local mult = data and data.dustMultiplier or 1
		local title = (count > 0) and "Eukaryotic Evolution Cascade!" or "First Eukaryotic Cell!"
		local subtitle = (count > 0)
			and string.format("%d cell%s evolved   ·   Dust Value ×%d", count, count == 1 and "" or "s", mult)
			or string.format("Dust Value ×%d", mult)
		playCascadeToast(title, subtitle)

		-- Burst on every cell that just became Eukaryotic. Models may rebuild this same
		-- frame from ConverterUpdate, so fire now and again shortly after.
		local ids = {}
		if data then
			if data.triggerCellId then
				table.insert(ids, data.triggerCellId)
			end
			for _, id in ipairs(data.cellIds or {}) do
				table.insert(ids, id)
			end
		end
		local function burstAll()
			for _, id in ipairs(ids) do
				playBurst(cellModels[id])
			end
		end
		burstAll()
		task.delay(0.12, burstAll)
	end)
end)
