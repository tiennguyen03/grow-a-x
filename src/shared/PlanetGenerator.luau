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
