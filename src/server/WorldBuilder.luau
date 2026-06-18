-- Builds the static space environment from source: zero gravity, dark void
-- lighting, a glowing centerpiece star, a scattered star field, and the
-- collectible dust motes that players fly through to earn Matter.
--
-- Per-player planets are NOT built here — see PlayerPlanetService. WorldBuilder
-- owns only the shared, static backdrop. Everything is set from script (not
-- saved in the .rbxl) so a blank baseplate place becomes the correct space
-- environment on server start.

local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.GameConfig)

-- World / lighting
local GRAVITY        = 0
local CLOCK_TIME     = 0
local BRIGHTNESS     = 2
local AMBIENT        = Color3.fromRGB(80, 80, 110)
local OUTDOOR_AMBIENT = Color3.fromRGB(20, 20, 40)

-- Stars (pushed far out + small so they read as distant background, not eyesores)
local STAR_SEED        = 20260618 -- fixed seed => both devs see the same field
local STAR_COUNT       = 160
local STAR_FIELD_RADIUS = 1700    -- studs; how far stars scatter from origin
local STAR_MIN_DIST    = 450      -- keep stars well away so they read as distant

-- Centerpiece "sun": the system anchor. Composition reads, from the player's
-- spawn at the origin looking down -Z:  player -> home planet ahead (0,0,-260)
-- -> sun far behind on the SAME vertical center line (X = 0), lifted just enough
-- to clear the planet so both are clearly visible and the planet looks like it
-- belongs to this star. Pushed further out (-1300) so the now-larger star frames
-- the scene instead of crowding it.
local CENTERPIECE_POS    = Vector3.new(0, 250, -1300)
local CENTERPIECE_RADIUS = 116 -- ~2x the previous 58 (bigger, more impressive sun)

-- Dust motes (collectible Matter)
local DUST_TAG  = "DustParticle"
local DUST_SEED = 20260619 -- fixed seed => reproducible dust layout

local WorldBuilder = {}

local function configureWorld()
	-- Zero gravity so players float
	workspace.Gravity = GRAVITY

	-- Remove the default baseplate / spawn so there's no ground in space.
	-- Players then spawn at the origin (0, 0, 0).
	for _, inst in workspace:GetChildren() do
		if inst:IsA("SpawnLocation") or (inst:IsA("BasePart") and inst.Name == "Baseplate") then
			inst:Destroy()
		end
	end

	-- Dark void lighting
	Lighting.ClockTime      = CLOCK_TIME
	Lighting.Brightness     = BRIGHTNESS
	Lighting.Ambient        = AMBIENT
	Lighting.OutdoorAmbient = OUTDOOR_AMBIENT

	-- Kill atmospheric haze and the sun glow (no atmosphere/sun in open space)
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmosphere then
		atmosphere.Density = 0
		atmosphere.Haze    = 0
		atmosphere.Glare   = 0
	end

	local sunRays = Lighting:FindFirstChildOfClass("SunRaysEffect")
	if sunRays then sunRays.Enabled = false end

	local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
	if bloom then
		bloom.Intensity = 0.4
		bloom.Size      = 24
		bloom.Threshold = 0.95
	end

	local dof = Lighting:FindFirstChildOfClass("DepthOfFieldEffect")
	if dof then dof.Enabled = false end
end

local function buildCenterpiece(parent)
	local star = Instance.new("Part")
	star.Name = "Centerpiece"
	star.Shape = Enum.PartType.Ball
	star.Size = Vector3.one * (CENTERPIECE_RADIUS * 2)
	star.Position = CENTERPIECE_POS
	star.Anchored = true
	star.CanCollide = false
	star.CanQuery = false
	star.Material = Enum.Material.Neon
	star.Color = Color3.fromRGB(255, 196, 92)
	star.CastShadow = false
	star.Parent = parent

	-- A soft outer glow shell
	local halo = Instance.new("Part")
	halo.Name = "Halo"
	halo.Shape = Enum.PartType.Ball
	halo.Size = Vector3.one * (CENTERPIECE_RADIUS * 2.6)
	halo.Position = CENTERPIECE_POS
	halo.Anchored = true
	halo.CanCollide = false
	halo.CanQuery = false
	halo.Material = Enum.Material.ForceField
	halo.Color = Color3.fromRGB(255, 150, 60)
	halo.Transparency = 0.5
	halo.CastShadow = false
	halo.Parent = star

	-- Bigger sun sits further away, so widen the light range to keep the planet
	-- lit; trim brightness slightly so the larger neon ball doesn't over-bloom.
	local light = Instance.new("PointLight")
	light.Brightness = 3.5
	light.Range = 2400
	light.Color = Color3.fromRGB(255, 210, 150)
	light.Parent = star
end

local function buildStarField(parent)
	local rng = Random.new(STAR_SEED)
	local field = Instance.new("Folder")
	field.Name = "StarField"
	field.Parent = parent

	for _ = 1, STAR_COUNT do
		-- Random point in a sphere shell between STAR_MIN_DIST and STAR_FIELD_RADIUS
		local dir = rng:NextUnitVector()
		local dist = rng:NextNumber(STAR_MIN_DIST, STAR_FIELD_RADIUS)

		local star = Instance.new("Part")
		star.Name = "Star"
		star.Shape = Enum.PartType.Ball
		star.Size = Vector3.one * rng:NextNumber(0.5, 1.8)
		star.Position = dir * dist
		star.Anchored = true
		star.CanCollide = false
		star.CanQuery = false
		star.CastShadow = false
		star.Material = Enum.Material.Neon

		-- Mostly white, a few warm/cool tints
		local roll = rng:NextNumber()
		if roll < 0.15 then
			star.Color = Color3.fromRGB(150, 190, 255) -- blue star
		elseif roll < 0.25 then
			star.Color = Color3.fromRGB(255, 200, 170) -- warm star
		else
			star.Color = Color3.fromRGB(245, 245, 255) -- white
		end

		star.Parent = field
	end
end

-- A random point within a sphere of radius DUST_SPAWN_RADIUS, kept a little
-- away from the exact origin so motes aren't piled on top of spawn.
local function randomDustPosition(rng)
	local dir  = rng:NextUnitVector()
	local dist = rng:NextNumber(30, GameConfig.DUST_SPAWN_RADIUS)
	return dir * dist
end

-- Collectible dust motes: small warm glowing balls scattered through the void.
-- Tagged "DustParticle" so PlayerManager can detect collection; each stores its
-- un-bobbed home position so the client animator can bob it and the server can
-- respawn it cleanly.
local function buildDust(parent)
	local rng = Random.new(DUST_SEED)
	local field = Instance.new("Folder")
	field.Name = "Dust"
	field.Parent = parent

	for _ = 1, GameConfig.DUST_PARTICLE_COUNT do
		local pos = randomDustPosition(rng)

		local mote = Instance.new("Part")
		mote.Name = "Dust"
		mote.Shape = Enum.PartType.Ball
		mote.Size = Vector3.one * rng:NextNumber(1.8, 2.6)
		mote.Position = pos
		mote.Anchored = true
		mote.CanCollide = false
		mote.CanQuery = false
		mote.CastShadow = false
		mote.Material = Enum.Material.Neon
		mote.Color = Color3.fromRGB(255, 224, 150) -- warm gold

		mote:SetAttribute("BasePosition", pos)
		mote:SetAttribute("Collected", false)
		mote:SetAttribute("BobPhase", rng:NextNumber(0, math.pi * 2))

		local light = Instance.new("PointLight")
		light.Brightness = 5
		light.Range = 30
		light.Color = Color3.fromRGB(255, 220, 150)
		light.Parent = mote

		mote.Parent = field
		CollectionService:AddTag(mote, DUST_TAG)
	end
end

function WorldBuilder.build()
	configureWorld()

	-- Clear any previous build (so re-running Studio doesn't stack duplicates)
	local existing = workspace:FindFirstChild("SpaceEnvironment")
	if existing then existing:Destroy() end

	local root = Instance.new("Folder")
	root.Name = "SpaceEnvironment"
	root.Parent = workspace

	buildCenterpiece(root)
	buildStarField(root)
	buildDust(root)
	-- Player planets are added under this folder by PlayerPlanetService.
end

return WorldBuilder
