-- Builds the entire space environment from source: zero gravity, dark void
-- lighting, a glowing centerpiece star, and a scattered star field.
--
-- Everything here is set from script (not saved in the .rbxl) so the world is
-- fully reproducible from source. A blank baseplate place will become the
-- correct space environment on server start, so any dev can clone + serve.

local Lighting = game:GetService("Lighting")

-- World / lighting
local GRAVITY        = 0
local CLOCK_TIME     = 0
local BRIGHTNESS     = 2
local AMBIENT        = Color3.fromRGB(80, 80, 110)
local OUTDOOR_AMBIENT = Color3.fromRGB(20, 20, 40)

-- Stars
local STAR_SEED        = 20260618 -- fixed seed => both devs see the same field
local STAR_COUNT       = 200
local STAR_FIELD_RADIUS = 900     -- studs; how far stars scatter from origin
local STAR_MIN_DIST    = 150      -- keep stars away from spawn so they read as distant

local CENTERPIECE_POS    = Vector3.new(0, -20, -350)
local CENTERPIECE_RADIUS = 60

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
end

return WorldBuilder
