-- Pure, deterministic planet descriptor generator.
--
-- Given a seed it picks an archetype and rolls traits inside that archetype's
-- ranges, returning a plain Luau table (a "descriptor"). It creates NO Roblox
-- Instances and requires NO server/client-only services — WorldBuilder turns a
-- descriptor into a visual model later (Sprint 7B).
--
-- Determinism contract: the same seed + same options always yields the same
-- descriptor. This relies on a FIXED order of rng calls and an explicit ordered
-- candidate list (never `pairs`, whose order isn't guaranteed).
--
-- Part of Epic 7: Procedural Planet Generation (Sprint 7A).

local PlanetArchetypes = require(script.Parent.PlanetArchetypes)

local PlanetGenerator = {}

-- Default ordered archetype pool for the home/origin planet.
local DEFAULT_HOME_POOL = { "Temperate", "Ocean", "YoungHabitable" }

local function round(value, decimals)
	local mult = 10 ^ (decimals or 0)
	return math.floor(value * mult + 0.5) / mult
end

local function pickFromRange(rng, range)
	return rng:NextNumber(range.min, range.max)
end

local function pickColor(rng, palette)
	return palette[rng:NextInteger(1, #palette)]
end

-- Build the ordered list of candidate archetype names to roll from.
local function resolveCandidates(options)
	local requested = options.allowedArchetypes or DEFAULT_HOME_POOL
	local candidates = {}
	for _, name in requested do
		local archetype = PlanetArchetypes[name]
		if archetype and archetype.enabled then
			table.insert(candidates, name)
		end
	end
	return candidates
end

--[[
	generatePlanetDescriptor(seed, options?) -> descriptor

	seed    : number — deterministic source
	options : optional table {
		planetId          : string?       -- stable internal id (default "planet")
		displayName       : string?       -- player-facing name (default archetype name)
		allowedArchetypes : { string }?   -- ordered pool (default home pool)
	}
]]
function PlanetGenerator.generatePlanetDescriptor(seed, options)
	options = options or {}

	local candidates = resolveCandidates(options)
	assert(#candidates > 0, "PlanetGenerator: no valid archetypes to choose from")

	local rng = Random.new(seed)

	-- 1. Archetype (fixed-order list keeps this deterministic)
	local archetypeName = candidates[rng:NextInteger(1, #candidates)]
	local archetype = PlanetArchetypes[archetypeName]

	-- 2. Numeric traits — ORDER MATTERS, do not reorder these rng calls
	local radius = round(pickFromRange(rng, archetype.radiusRange), 0)
	local waterCoverage = pickFromRange(rng, archetype.waterCoverageRange)
	local cloudPick = pickFromRange(rng, archetype.cloudCoverageRange)
	local atmosphereThickness = pickFromRange(rng, archetype.atmosphereThicknessRange)
	local iceCoverage = pickFromRange(rng, archetype.iceCoverageRange)

	-- 3. Colors
	local oceanColor = pickColor(rng, archetype.oceanPalette)
	local landColor = pickColor(rng, archetype.landPalette)
	local atmosphereColor = pickColor(rng, archetype.atmospherePalette)

	-- 4. Rotation
	local rotationSeconds = round(pickFromRange(rng, archetype.rotationSecondsRange), 0)

	-- Gently correlate clouds with water (more water -> a touch more cloud),
	-- then clamp back into the archetype's range. No extra rng -> still deterministic.
	local cloudCoverage = cloudPick + (waterCoverage - cloudPick) * 0.3
	cloudCoverage = math.clamp(
		cloudCoverage,
		archetype.cloudCoverageRange.min,
		archetype.cloudCoverageRange.max
	)

	-- Clouds read as near-white, faintly tinted by the atmosphere. Derived, no rng.
	local cloudColor = Color3.new(1, 1, 1):Lerp(atmosphereColor, 0.15)

	-- Copy tags so callers can't mutate the archetype's shared table
	local tags = {}
	for _, tag in archetype.tags do
		table.insert(tags, tag)
	end

	return {
		planetId = options.planetId or "planet",
		displayName = options.displayName or archetype.displayName,
		seed = seed,
		archetype = archetypeName,

		radius = radius,
		waterCoverage = round(waterCoverage, 2),
		cloudCoverage = round(cloudCoverage, 2),
		atmosphereThickness = round(atmosphereThickness, 2),
		iceCoverage = round(iceCoverage, 2),

		oceanColor = oceanColor,
		landColor = landColor,
		atmosphereColor = atmosphereColor,
		cloudColor = cloudColor,

		rotationSeconds = rotationSeconds,

		hasRings = false, -- future (Sprint 7F)
		moonCount = 0,    -- future (Sprint 7F)

		tags = tags,
	}
end

-- Biome base colors (shared across archetypes; temperate keeps the archetype's
-- own landColor so each world still has its palette identity). Tuned to the
-- "habitable Earth-like" target: muted green / sandy tan / rocky grey / pale
-- tundra. See biomeFor() below for the climate logic that places them.
local DESERT_COLOR   = Color3.fromRGB(206, 178, 122) -- sandy tan
local MOUNTAIN_COLOR = Color3.fromRGB(126, 122, 118) -- rocky grey
local TUNDRA_COLOR   = Color3.fromRGB(214, 224, 232) -- pale white-blue

-- Climate thresholds. Kept generous toward "temperate" so the starting world
-- reads as habitable rather than a patchwork of extremes.
local MOUNTAIN_ELEV = 0.64 -- top elevations become rocky highlands
local COLD_TEMP     = 0.20 -- below this (cold, high latitude) => tundra
local HOT_TEMP      = 0.56 -- above this (hot, low latitude) ...
local DRY_MOISTURE  = 0.42 -- ... AND drier than this => desert

-- Deterministic surface generation using COHERENT NOISE over the sphere, so
-- land forms connected continents/islands instead of disconnected blobs, and
-- biomes follow believable climate bands rather than random coloring.
--
-- Returns an array of tiles, each a small flat patch the builder lays tangent
-- on the surface:
--   { dir = Vector3 (unit normal), size, color, kind, biome?, material?, raise? }
--
-- How it works:
--  * A latitude/longitude grid is walked, with fewer longitude cells near the
--    poles (roughly equal-area) so tiles are evenly spaced.
--  * Land vs ocean: a low-frequency CONTINENT noise layer (few big shapes) plus
--    a higher-frequency DETAIL layer. Cells above a water-derived threshold are
--    land; connected land cells overlap into coherent continents.
--  * Biome of each land cell comes from COHERENT climate fields, not random
--    color: ELEVATION noise (high => mountains), TEMPERATURE from latitude minus
--    altitude (poles/highlands cold => tundra), and MOISTURE noise (hot + dry =>
--    desert). Everything else stays temperate, which dominates by design.
--  * `math.noise` isn't seedable, so we shift each field's sample domain by a
--    large per-seed offset — that's what makes each world unique yet deterministic.
function PlanetGenerator.generateSurface(descriptor)
	local radius = descriptor.radius
	local tiles = {}

	-- Per-seed domain offsets (deterministic from the seed). One independent
	-- offset per noise field so the fields don't correlate into stripes.
	local rng = Random.new(descriptor.seed)
	local function offset()
		return Vector3.new(rng:NextNumber(-400, 400), rng:NextNumber(-400, 400), rng:NextNumber(-400, 400))
	end
	local contOff, detailOff, cloudOff, elevOff, moistOff =
		offset(), offset(), offset(), offset(), offset()

	local CONTINENT_FREQ = 1.4 -- low => a few big continents
	local DETAIL_FREQ = 3.3
	local DETAIL_AMP = 0.4
	local CLOUD_FREQ = 2.1
	local ELEV_FREQ = 1.9   -- coherent mountain ranges, not speckle
	local MOIST_FREQ = 1.6  -- coherent humid / arid regions

	-- More water => higher land threshold => less land
	local landThreshold = (descriptor.waterCoverage - 0.5) * 0.5

	-- math.noise returns roughly -1..1; sampleField remaps a field to 0..1.
	local function sampleField(d, freq, off)
		return (math.noise(d.X * freq + off.X, d.Y * freq + off.Y, d.Z * freq + off.Z) + 1) * 0.5
	end

	local function landValue(d)
		local cont = math.noise(d.X * CONTINENT_FREQ + contOff.X, d.Y * CONTINENT_FREQ + contOff.Y, d.Z * CONTINENT_FREQ + contOff.Z)
		local detail = math.noise(d.X * DETAIL_FREQ + detailOff.X, d.Y * DETAIL_FREQ + detailOff.Y, d.Z * DETAIL_FREQ + detailOff.Z)
		return cont + detail * DETAIL_AMP
	end

	local function shade(color, factor)
		return Color3.new(
			math.clamp(color.R * factor, 0, 1),
			math.clamp(color.G * factor, 0, 1),
			math.clamp(color.B * factor, 0, 1)
		)
	end

	-- Decide a land cell's biome from coherent climate fields.
	--   dir        : surface normal
	--   lat        : latitude (poles -> cold)
	--   landMargin : 0..1, how far inland/above the waterline (drives green depth)
	local function biomeFor(dir, lat, landMargin)
		local elevation = sampleField(dir, ELEV_FREQ, elevOff)
		local moisture = sampleField(dir, MOIST_FREQ, moistOff)
		-- Warm at the equator, cold at the poles; high ground is colder too.
		local temperature = (1 - math.abs(math.sin(lat))) - elevation * 0.3

		if elevation > MOUNTAIN_ELEV then
			-- Rocky highland: grey, lighter toward the peaks, and raised slightly.
			local peak = math.clamp((elevation - MOUNTAIN_ELEV) / (1 - MOUNTAIN_ELEV), 0, 1)
			return {
				biome = "mountain",
				color = shade(MOUNTAIN_COLOR, 0.9 + peak * 0.45),
				material = Enum.Material.Slate,
				raise = radius * (0.015 + peak * 0.03),
			}
		elseif temperature < COLD_TEMP then
			return { biome = "tundra", color = TUNDRA_COLOR }
		elseif temperature > HOT_TEMP and moisture < DRY_MOISTURE then
			return { biome = "desert", color = shade(DESERT_COLOR, 0.94 + moisture * 0.16) }
		else
			-- Temperate grassland: the archetype's own green, deeper inland.
			return { biome = "temperate", color = shade(descriptor.landColor, 0.9 + landMargin * 0.3) }
		end
	end

	local function dirFromLatLon(lat, lon)
		local cosLat = math.cos(lat)
		return Vector3.new(cosLat * math.cos(lon), math.sin(lat), cosLat * math.sin(lon))
	end

	local GRID_LAT = 16
	local BASE_LON = 34
	local POLAR_LAT = math.rad(64)
	local LAND_TILE = radius * 0.24
	local ICE_TILE = radius * 0.26

	for li = 0, GRID_LAT - 1 do
		local lat = -math.pi / 2 + math.pi * (li + 0.5) / GRID_LAT
		local cosLat = math.cos(lat)
		local lonCount = math.max(math.floor(BASE_LON * cosLat + 0.5), 4)
		for lo = 0, lonCount - 1 do
			local lon = 2 * math.pi * (lo + 0.5) / lonCount
			local dir = dirFromLatLon(lat, lon)

			if math.abs(lat) > POLAR_LAT and descriptor.iceCoverage > 0.04 then
				table.insert(tiles, { dir = dir, size = ICE_TILE, color = Color3.fromRGB(238, 246, 255), kind = "ice" })
			else
				local v = landValue(dir)
				if v > landThreshold then
					local landMargin = math.clamp((v - landThreshold) * 2.5, 0, 1)
					local b = biomeFor(dir, lat, landMargin)
					table.insert(tiles, {
						dir = dir,
						size = LAND_TILE,
						color = b.color,
						kind = "land",
						biome = b.biome,
						material = b.material,
						raise = b.raise,
					})
				end
			end
		end
	end

	-- Sparse, coarse cloud layer — hints at weather without hiding the world
	if descriptor.cloudCoverage > 0.05 then
		local CLOUD_LAT = 11
		local CLOUD_LON = 20
		local cloudThreshold = 0.42 - descriptor.cloudCoverage * 0.45
		for li = 0, CLOUD_LAT - 1 do
			local lat = -math.pi / 2 + math.pi * (li + 0.5) / CLOUD_LAT
			local cosLat = math.cos(lat)
			local lonCount = math.max(math.floor(CLOUD_LON * cosLat + 0.5), 3)
			for lo = 0, lonCount - 1 do
				local lon = 2 * math.pi * (lo + 0.5) / lonCount
				local dir = dirFromLatLon(lat, lon)
				local cv = math.noise(dir.X * CLOUD_FREQ + cloudOff.X, dir.Y * CLOUD_FREQ + cloudOff.Y, dir.Z * CLOUD_FREQ + cloudOff.Z)
				if cv > cloudThreshold then
					table.insert(tiles, { dir = dir, size = radius * 0.30, color = descriptor.cloudColor, kind = "cloud" })
				end
			end
		end
	end

	return tiles
end

-- Optional dev helper: returns a one-line summary string for printing.
function PlanetGenerator.debugDescriptor(descriptor)
	return string.format(
		"[%s] %s seed=%d r=%d water=%.2f cloud=%.2f atmo=%.2f ice=%.2f",
		descriptor.archetype,
		descriptor.displayName,
		descriptor.seed,
		descriptor.radius,
		descriptor.waterCoverage,
		descriptor.cloudCoverage,
		descriptor.atmosphereThickness,
		descriptor.iceCoverage
	)
end

return PlanetGenerator
