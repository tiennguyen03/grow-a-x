-- Per-player planet manager (Epic 7).
--
-- Gives each player one deterministic procedural planet, built when they join
-- and removed when they leave. Planets live under:
--   workspace.SpaceEnvironment.PlayerPlanets.Planet_<UserId>
--
-- Deterministic: a player's UserId (+ world salt) seeds the generator, so the
-- same player always gets the same world. Respawning does NOT rebuild or
-- duplicate the planet — it's environment, not tied to the character.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local WorldConfig = require(ReplicatedStorage.WorldConfig)
local PlanetGenerator = require(ReplicatedStorage.PlanetGenerator)

local PlayerPlanetService = {}

local DEFAULT_ROTATION_SECONDS = 160 -- fallback if a descriptor lacks RotationSeconds
local ORBIT_ANGLE_SALT = 104729 -- prime mixed into the seed for orbit rolls

-- userId -> {
--   model,
--   orbitRadius, orbitHeight, orbitAngle, orbitSpeed,  -- position around the star
--   spinAngle, spinSpeed,                              -- own-axis rotation
-- }
-- orbitAngle and spinAngle accumulate forever (never reset), so both the orbit
-- and the spin are continuous and never snap. They are kept SEPARATE: orbitAngle
-- places the planet around the star, spinAngle rotates it about its own center.
local planets = {}

local function ensurePlayerPlanetsFolder()
	local env = workspace:FindFirstChild("SpaceEnvironment")
	if not env then
		env = Instance.new("Folder")
		env.Name = "SpaceEnvironment"
		env.Parent = workspace
	end
	local folder = env:FindFirstChild("PlayerPlanets")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "PlayerPlanets"
		folder.Parent = env
	end
	return folder
end

-- Current world position of a planet on its orbit, given its angle.
local function orbitPosition(entry)
	local center = WorldConfig.CENTERPIECE_STAR_POS
	return center + Vector3.new(
		math.cos(entry.orbitAngle) * entry.orbitRadius,
		entry.orbitHeight,
		math.sin(entry.orbitAngle) * entry.orbitRadius
	)
end

local function seedForPlayer(player)
	local id = player.UserId
	if id <= 0 then -- Studio "Play Solo" can give non-positive ids
		id = WorldConfig.FALLBACK_HOME_PLANET_SEED
	end
	return id + WorldConfig.WORLD_SEED_SALT
end

-- Lays a flat tile tangent to the sphere surface (its thin axis points along the
-- surface normal), so tiles hug the planet instead of poking out. The generator
-- gives each tile a jittered size plus optional rectangular `width`/`length` and a
-- `roll` (rotation in the tangent plane) so the surface reads as organic patches
-- rather than a uniform square grid.
local function buildTile(parent, center, radius, tile)
	local isCloud = tile.kind == "cloud"
	local size = tile.size
	local width = tile.width or size   -- face dimensions (default square)
	local length = tile.length or size
	local thickness = math.max(0.5, size * 0.16)
	-- Land sits flush; mountains add `raise` so highlands read as raised terrain.
	local dist = isCloud and (radius + radius * 0.025)
		or (radius - thickness * 0.5 + (tile.raise or 0))
	local pos = center + tile.dir * dist

	-- up hint avoids a degenerate lookAt when a tile sits near the poles
	local up = (math.abs(tile.dir.Y) < 0.99) and Vector3.yAxis or Vector3.xAxis
	local part = Instance.new("Part")
	part.Size = Vector3.new(width, length, thickness)
	-- LookVector = normal => thin (Z) axis is radial; roll spins the face about it.
	local cf = CFrame.lookAt(pos, pos + tile.dir, up)
	if tile.roll then
		cf = cf * CFrame.Angles(0, 0, tile.roll)
	end
	part.CFrame = cf
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CastShadow = false
	-- Biomes can request a material (e.g. Slate for rocky mountains); default clean.
	part.Material = tile.material or Enum.Material.SmoothPlastic
	part.Color = tile.color

	if isCloud then
		part.Name = "Cloud"
		part.Transparency = 0.5
	elseif tile.kind == "ice" then
		part.Name = "IceTile"
	else
		-- Name land tiles by biome so future scripts can read the surface makeup.
		part.Name = (tile.biome and (tile.biome:sub(1, 1):upper() .. tile.biome:sub(2)) or "Land") .. "Tile"
	end
	part.Parent = parent
end

local function buildPlanetModel(descriptor, position, ownerUserId)
	local model = Instance.new("Model")
	model.Name = "Planet_" .. ownerUserId
	local radius = descriptor.radius

	-- Body is the ocean; continents are tiled on top, so the world reads as
	-- "mostly ocean with continents".
	local body = Instance.new("Part")
	body.Name = "PlanetBody"
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.one * (radius * 2)
	body.Position = position
	body.Anchored = true
	body.CanCollide = false
	body.CanQuery = true -- future inspect raycast can hit it
	body.Material = Enum.Material.SmoothPlastic
	body.Color = descriptor.oceanColor
	body.Parent = model
	model.PrimaryPart = body

	-- Thin atmosphere shell (scale ~1.04–1.08), subtle so it doesn't overpower
	local shellScale = 1.04 + descriptor.atmosphereThickness * 0.04
	local atmosphere = Instance.new("Part")
	atmosphere.Name = "AtmosphereShell"
	atmosphere.Shape = Enum.PartType.Ball
	atmosphere.Size = Vector3.one * (radius * 2 * shellScale)
	atmosphere.Position = position
	atmosphere.Anchored = true
	atmosphere.CanCollide = false
	atmosphere.CanQuery = false
	atmosphere.CastShadow = false
	atmosphere.Material = Enum.Material.ForceField
	atmosphere.Color = descriptor.atmosphereColor
	atmosphere.Transparency = math.clamp(0.78 - descriptor.atmosphereThickness * 0.18, 0.6, 0.75)
	atmosphere.Parent = model

	-- Continents/ice on the surface, clouds just above it
	local surface = Instance.new("Folder")
	surface.Name = "Surface"
	surface.Parent = model
	local clouds = Instance.new("Folder")
	clouds.Name = "Clouds"
	clouds.Parent = model

	for _, tile in PlanetGenerator.generateSurface(descriptor) do
		buildTile(tile.kind == "cloud" and clouds or surface, position, radius, tile)
	end

	-- Expose descriptor data for future client/interaction scripts to read
	model:SetAttribute("PlanetId", descriptor.planetId)
	model:SetAttribute("DisplayName", descriptor.displayName)
	model:SetAttribute("OwnerUserId", ownerUserId)
	model:SetAttribute("Seed", descriptor.seed)
	model:SetAttribute("Archetype", descriptor.archetype)
	model:SetAttribute("Radius", descriptor.radius)
	model:SetAttribute("WaterCoverage", descriptor.waterCoverage)
	model:SetAttribute("CloudCoverage", descriptor.cloudCoverage)
	model:SetAttribute("AtmosphereThickness", descriptor.atmosphereThickness)
	model:SetAttribute("RotationSeconds", descriptor.rotationSeconds)

	return model
end

local function spawnPlanet(player)
	local existing = planets[player.UserId]
	if existing and existing.model and existing.model.Parent then
		return -- already has a planet; never duplicate (e.g. on respawn)
	end

	local seed = seedForPlayer(player)
	local descriptor = PlanetGenerator.generatePlanetDescriptor(seed, {
		planetId = "player_" .. player.UserId,
		displayName = player.Name .. "'s World",
		allowedArchetypes = WorldConfig.HOME_ARCHETYPE_POOL,
	})

	-- Orbit params come from a SEPARATE deterministic rng stream so they don't
	-- disturb the descriptor's rolls — the same player still gets the same planet
	-- AND the same orbit. Per-player angle/radius/height spread keeps multiple
	-- players' planets from stacking at the same spot on the orbit.
	local orbitRng = Random.new(seed + ORBIT_ANGLE_SALT)
	local radiusVar = WorldConfig.PLANET_ORBIT_RADIUS_VARIATION
	local heightVar = WorldConfig.PLANET_ORBIT_HEIGHT_VARIATION
	local rotationSeconds = descriptor.rotationSeconds or DEFAULT_ROTATION_SECONDS

	local entry = {
		orbitRadius = WorldConfig.PLANET_ORBIT_BASE_RADIUS + orbitRng:NextNumber(-radiusVar, radiusVar),
		orbitHeight = orbitRng:NextNumber(-heightVar, heightVar),
		orbitAngle = orbitRng:NextNumber(0, 2 * math.pi),
		orbitSpeed = (2 * math.pi) / WorldConfig.PLANET_ORBIT_PERIOD_SECONDS,
		spinAngle = 0,
		spinSpeed = (2 * math.pi) / rotationSeconds,
	}

	-- Build it already at its current orbit position so it never pops in from the
	-- origin before the first Heartbeat.
	local model = buildPlanetModel(descriptor, orbitPosition(entry), player.UserId)
	model.Parent = ensurePlayerPlanetsFolder()
	entry.model = model
	planets[player.UserId] = entry
end

local function removePlanet(player)
	local entry = planets[player.UserId]
	if not entry then
		return
	end
	if entry.model then
		entry.model:Destroy()
	end
	planets[player.UserId] = nil
end

-- Continuous, authoritative orbit + spin.
--
-- This MUST run on the server: the planet parts are anchored and server-owned,
-- so the server is the source of truth for their CFrames (an earlier client-side
-- spin lost to the server re-replicating the anchored CFrames, snapping it back).
-- Each frame we advance TWO independent accumulators that never reset:
--   * orbitAngle — moves the whole model around the star (orbit position)
--   * spinAngle  — rotates the model about its own center (day/night spin)
-- We compute the orbit position, then PivotTo with the spin baked in, so a single
-- rigid move carries the body, atmosphere, surface tiles, clouds, and marker.
local function stepOrbitSpin(dt)
	for _, entry in planets do
		local model = entry.model
		if model and model.Parent and model.PrimaryPart then
			entry.orbitAngle += entry.orbitSpeed * dt
			entry.spinAngle += entry.spinSpeed * dt
			local pos = orbitPosition(entry)
			model:PivotTo(CFrame.new(pos) * CFrame.Angles(0, entry.spinAngle, 0))
		end
	end
end

function PlayerPlanetService.init()
	ensurePlayerPlanetsFolder()
	Players.PlayerAdded:Connect(spawnPlanet)
	Players.PlayerRemoving:Connect(removePlanet)
	for _, player in Players:GetPlayers() do
		spawnPlanet(player)
	end
	RunService.Heartbeat:Connect(stepOrbitSpin)
end

return PlayerPlanetService
