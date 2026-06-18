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

local WorldConfig = require(ReplicatedStorage.WorldConfig)
local PlanetGenerator = require(ReplicatedStorage.PlanetGenerator)

local PlayerPlanetService = {}

local PLANET_SPACING = 800 -- studs between players' planets so they never overlap

local planets = {}   -- userId -> { model = Model, slot = number }
local usedSlots = {} -- slot -> true

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

-- Smallest free non-negative slot, so the solo player always gets slot 0
-- (= exactly WorldConfig.HOME_PLANET_POS).
local function allocSlot()
	local slot = 0
	while usedSlots[slot] do
		slot += 1
	end
	usedSlots[slot] = true
	return slot
end

local function seedForPlayer(player)
	local id = player.UserId
	if id <= 0 then -- Studio "Play Solo" can give non-positive ids
		id = WorldConfig.FALLBACK_HOME_PLANET_SEED
	end
	return id + WorldConfig.WORLD_SEED_SALT
end

-- Lays a flat square tile tangent to the sphere surface (its thin axis points
-- along the surface normal), so tiles hug the planet instead of poking out.
local function buildTile(parent, center, radius, tile)
	local isCloud = tile.kind == "cloud"
	local size = tile.size
	local thickness = math.max(0.5, size * 0.16)
	local dist = isCloud and (radius + radius * 0.025) or (radius - thickness * 0.5)
	local pos = center + tile.dir * dist

	-- up hint avoids a degenerate lookAt when a tile sits near the poles
	local up = (math.abs(tile.dir.Y) < 0.99) and Vector3.yAxis or Vector3.xAxis
	local part = Instance.new("Part")
	part.Size = Vector3.new(size, size, thickness)
	part.CFrame = CFrame.lookAt(pos, pos + tile.dir, up) -- LookVector = normal => thin axis is radial
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CastShadow = false
	part.Material = Enum.Material.SmoothPlastic
	part.Color = tile.color

	if isCloud then
		part.Name = "Cloud"
		part.Transparency = 0.5
	else
		part.Name = (tile.kind == "ice") and "IceTile" or "LandTile"
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
	model:SetAttribute("AtmosphereThickness", descriptor.atmosphereThickness)
	model:SetAttribute("RotationSeconds", descriptor.rotationSeconds)

	return model
end

local function spawnPlanet(player)
	local existing = planets[player.UserId]
	if existing and existing.model and existing.model.Parent then
		return -- already has a planet; never duplicate (e.g. on respawn)
	end

	local slot = existing and existing.slot or allocSlot()
	local position = WorldConfig.HOME_PLANET_POS + Vector3.new(slot * PLANET_SPACING, 0, 0)

	local descriptor = PlanetGenerator.generatePlanetDescriptor(seedForPlayer(player), {
		planetId = "player_" .. player.UserId,
		displayName = player.Name .. "'s World",
		allowedArchetypes = WorldConfig.HOME_ARCHETYPE_POOL,
	})

	local model = buildPlanetModel(descriptor, position, player.UserId)
	model.Parent = ensurePlayerPlanetsFolder()
	planets[player.UserId] = { model = model, slot = slot }
end

local function removePlanet(player)
	local entry = planets[player.UserId]
	if not entry then
		return
	end
	if entry.model then
		entry.model:Destroy()
	end
	usedSlots[entry.slot] = nil
	planets[player.UserId] = nil
end

function PlayerPlanetService.init()
	ensurePlayerPlanetsFolder()
	Players.PlayerAdded:Connect(spawnPlanet)
	Players.PlayerRemoving:Connect(removePlanet)
	for _, player in Players:GetPlayers() do
		spawnPlanet(player)
	end
end

return PlayerPlanetService
