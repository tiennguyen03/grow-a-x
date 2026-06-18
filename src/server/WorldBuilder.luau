-- Builds the static space environment: a glowing centerpiece star and a
-- scattered star field. These exist purely as visual reference points so the
-- player can perceive motion while floating through the void.
--
-- Built from script (not placed in the .rbxl) so the world is reproducible
-- from source and Nova gets it automatically on pull.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local GameConfig         = require(ReplicatedStorage.GameConfig)

local DUST_TAG  = "DustParticle"
local DUST_SEED = 20260619 -- fixed seed => reproducible dust layout

local STAR_SEED        = 20260618 -- fixed seed => both devs see the same field
local STAR_COUNT       = 200
local STAR_FIELD_RADIUS = 900     -- studs; how far stars scatter from origin
local STAR_MIN_DIST    = 150      -- keep stars away from spawn so they read as distant

local CENTERPIECE_POS    = Vector3.new(0, -20, -350)
local CENTERPIECE_RADIUS = 60

local WorldBuilder = {}

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

	local light = Instance.new("PointLight")
	light.Brightness = 4
	light.Range = 600
	light.Color = Color3.fromRGB(255, 210, 150)
	light.Parent = star
end

local function buildStarField(parent)
	local rng = Random.new(STAR_SEED)
	local field = Instance.new("Folder")
	field.Name = "StarField"
	field.Parent = parent

	for i = 1, STAR_COUNT do
		-- Random point in a sphere shell between STAR_MIN_DIST and STAR_FIELD_RADIUS
		local dir = rng:NextUnitVector()
		local dist = rng:NextNumber(STAR_MIN_DIST, STAR_FIELD_RADIUS)

		local star = Instance.new("Part")
		star.Name = "Star"
		star.Shape = Enum.PartType.Ball
		star.Size = Vector3.one * rng:NextNumber(1.5, 5)
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
	local dist = rng:NextNumber(60, GameConfig.DUST_SPAWN_RADIUS)
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
		mote.Size = Vector3.one * rng:NextNumber(0.6, 1.0)
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
		light.Brightness = 2
		light.Range = 14
		light.Color = Color3.fromRGB(255, 220, 150)
		light.Parent = mote

		mote.Parent = field
		CollectionService:AddTag(mote, DUST_TAG)
	end
end

function WorldBuilder.build()
	-- Clear any previous build (so re-running Studio doesn't stack duplicates)
	local existing = workspace:FindFirstChild("SpaceEnvironment")
	if existing then existing:Destroy() end

	local root = Instance.new("Folder")
	root.Name = "SpaceEnvironment"
	root.Parent = workspace

	buildCenterpiece(root)
	buildStarField(root)
	buildDust(root)
end

return WorldBuilder
