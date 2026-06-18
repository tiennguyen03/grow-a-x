-- Planet archetype definitions: allowed planet categories and the constrained,
-- scientifically-grounded trait ranges + color palettes each one rolls within.
--
-- The generator picks an archetype FIRST, then rolls traits inside that
-- archetype's ranges — so planets are varied but never impossible nonsense.
--
-- Part of Epic 7: Procedural Planet Generation.
--
-- Trait conventions:
--   *Range     = { min, max } numeric, rolled with rng:NextNumber
--   *Palette   = array of Color3, one chosen with rng:NextInteger
--   allowedForHome = may the starting "Origin World" use this archetype
--   enabled        = is this archetype usable at all yet
--
-- Home archetypes are ocean-dominant young-Earth-like worlds: liquid water,
-- continents, a thin atmosphere — believable but not modern Earth.

local PlanetArchetypes = {}

PlanetArchetypes.Temperate = {
	displayName = "Temperate World",
	allowedForHome = true,
	enabled = true,

	radiusRange = { min = 34, max = 40 },
	waterCoverageRange = { min = 0.55, max = 0.70 },
	cloudCoverageRange = { min = 0.25, max = 0.50 },
	atmosphereThicknessRange = { min = 0.45, max = 0.62 },
	iceCoverageRange = { min = 0.05, max = 0.18 },
	rotationSecondsRange = { min = 130, max = 190 },

	oceanPalette = {
		Color3.fromRGB(20, 70, 130),
		Color3.fromRGB(18, 95, 145),
		Color3.fromRGB(25, 85, 160),
	},
	landPalette = {
		Color3.fromRGB(95, 140, 90),
		Color3.fromRGB(125, 135, 85),
		Color3.fromRGB(105, 155, 110),
	},
	atmospherePalette = {
		Color3.fromRGB(120, 195, 255),
		Color3.fromRGB(140, 205, 255),
	},

	tags = { "rocky", "habitable", "temperate" },
}

PlanetArchetypes.Ocean = {
	displayName = "Ocean World",
	allowedForHome = true,
	enabled = true,

	radiusRange = { min = 36, max = 43 },
	waterCoverageRange = { min = 0.72, max = 0.85 },
	cloudCoverageRange = { min = 0.40, max = 0.65 },
	atmosphereThicknessRange = { min = 0.50, max = 0.68 },
	iceCoverageRange = { min = 0.03, max = 0.12 },
	rotationSecondsRange = { min = 150, max = 210 },

	oceanPalette = {
		Color3.fromRGB(15, 75, 120),
		Color3.fromRGB(20, 95, 135),
		Color3.fromRGB(18, 110, 140),
	},
	landPalette = {
		Color3.fromRGB(90, 135, 100),
		Color3.fromRGB(115, 130, 90),
	},
	atmospherePalette = {
		Color3.fromRGB(120, 200, 255),
		Color3.fromRGB(140, 210, 250),
	},

	tags = { "rocky", "habitable", "ocean" },
}

PlanetArchetypes.YoungHabitable = {
	displayName = "Young Habitable World",
	allowedForHome = true,
	enabled = true,

	radiusRange = { min = 33, max = 39 },
	waterCoverageRange = { min = 0.50, max = 0.66 },
	cloudCoverageRange = { min = 0.20, max = 0.45 },
	atmosphereThicknessRange = { min = 0.45, max = 0.60 },
	iceCoverageRange = { min = 0.00, max = 0.10 },
	rotationSecondsRange = { min = 120, max = 175 },

	oceanPalette = {
		Color3.fromRGB(25, 65, 110),
		Color3.fromRGB(30, 80, 120),
	},
	landPalette = {
		Color3.fromRGB(135, 110, 85),  -- volcanic brown
		Color3.fromRGB(115, 105, 95),  -- basalt grey
		Color3.fromRGB(105, 145, 95),  -- early green
	},
	atmospherePalette = {
		Color3.fromRGB(135, 180, 225),
		Color3.fromRGB(150, 190, 230),
	},

	tags = { "rocky", "habitable", "young" },
}

-- ---------------------------------------------------------------------------
-- Future archetypes: defined for reference but NOT yet usable.
-- `enabled = false` keeps the generator from ever rolling them; flip to true
-- (and add to a planet's allowedArchetypes pool) when their epic is ready.
-- Never use these for the starting Origin World (`allowedForHome = false`).
-- ---------------------------------------------------------------------------

PlanetArchetypes.Desert = {
	displayName = "Desert World",
	allowedForHome = false,
	enabled = false,

	radiusRange = { min = 30, max = 40 },
	waterCoverageRange = { min = 0.05, max = 0.25 },
	cloudCoverageRange = { min = 0.05, max = 0.20 },
	atmosphereThicknessRange = { min = 0.40, max = 0.65 },
	iceCoverageRange = { min = 0.00, max = 0.08 },
	rotationSecondsRange = { min = 120, max = 180 },

	oceanPalette = { Color3.fromRGB(60, 90, 110) },
	landPalette = {
		Color3.fromRGB(190, 150, 95),
		Color3.fromRGB(170, 120, 70),
		Color3.fromRGB(150, 105, 60),
	},
	atmospherePalette = {
		Color3.fromRGB(225, 200, 150),
		Color3.fromRGB(210, 185, 140),
	},

	tags = { "rocky", "arid", "desert" },
}

PlanetArchetypes.Ice = {
	displayName = "Ice World",
	allowedForHome = false,
	enabled = false,

	radiusRange = { min = 30, max = 42 },
	waterCoverageRange = { min = 0.10, max = 0.30 },
	cloudCoverageRange = { min = 0.20, max = 0.40 },
	atmosphereThicknessRange = { min = 0.30, max = 0.60 },
	iceCoverageRange = { min = 0.50, max = 0.85 },
	rotationSecondsRange = { min = 140, max = 210 },

	oceanPalette = { Color3.fromRGB(120, 160, 190) },
	landPalette = {
		Color3.fromRGB(225, 235, 245),
		Color3.fromRGB(200, 215, 235),
	},
	atmospherePalette = {
		Color3.fromRGB(200, 225, 245),
		Color3.fromRGB(180, 210, 240),
	},

	tags = { "rocky", "frozen", "ice" },
}

PlanetArchetypes.Volcanic = {
	displayName = "Volcanic World",
	allowedForHome = false,
	enabled = false,

	radiusRange = { min = 30, max = 42 },
	waterCoverageRange = { min = 0.00, max = 0.10 },
	cloudCoverageRange = { min = 0.10, max = 0.30 },
	atmosphereThicknessRange = { min = 0.60, max = 0.90 },
	iceCoverageRange = { min = 0.00, max = 0.02 },
	rotationSecondsRange = { min = 110, max = 160 },

	oceanPalette = { Color3.fromRGB(70, 30, 20) },
	landPalette = {
		Color3.fromRGB(50, 40, 40),
		Color3.fromRGB(70, 45, 40),
		Color3.fromRGB(40, 35, 35),
	},
	atmospherePalette = {
		Color3.fromRGB(180, 110, 90),
		Color3.fromRGB(160, 100, 85),
	},

	tags = { "rocky", "volcanic", "unstable" },
}

PlanetArchetypes.Barren = {
	displayName = "Barren Rocky World",
	allowedForHome = false,
	enabled = false,

	radiusRange = { min = 26, max = 40 },
	waterCoverageRange = { min = 0.00, max = 0.05 },
	cloudCoverageRange = { min = 0.00, max = 0.10 },
	atmosphereThicknessRange = { min = 0.00, max = 0.20 },
	iceCoverageRange = { min = 0.00, max = 0.10 },
	rotationSecondsRange = { min = 130, max = 200 },

	oceanPalette = { Color3.fromRGB(80, 80, 85) },
	landPalette = {
		Color3.fromRGB(110, 105, 100),
		Color3.fromRGB(90, 88, 85),
		Color3.fromRGB(130, 122, 115),
	},
	atmospherePalette = {
		Color3.fromRGB(140, 140, 150),
	},

	tags = { "rocky", "dead", "barren" },
}

-- ---------------------------------------------------------------------------
-- Future gameplay hooks (DOCUMENTATION ONLY, nothing implemented).
-- When interventions/economy land, archetype tags can bias gameplay, e.g.:
--   Ocean    : + faster early life growth      - slower industrial land expansion
--   Desert   : + stronger solar energy         - lower natural biomass
--   Ice      : + climate stability             - slower early evolution
--   Volcanic : + minerals/resources            - higher disaster risk
--   Barren   : (start point only; needs heavy intervention to host life)
-- These are design notes — do NOT wire any modifiers here yet.
-- ---------------------------------------------------------------------------

return PlanetArchetypes
