-- Planet archetype definitions: allowed planet categories and the constrained,
-- scientifically-grounded trait ranges + color palettes each one rolls within.
--
-- The generator picks an archetype FIRST, then rolls traits inside that
-- archetype's ranges — so planets are varied but never impossible nonsense.
--
-- Part of Epic 7: Procedural Planet Generation (Sprint 7A).
--
-- Trait conventions:
--   *Range     = { min, max } numeric, rolled with rng:NextNumber
--   *Palette   = array of Color3, one chosen with rng:NextInteger
--   allowedForHome = may the starting "Origin World" use this archetype
--   enabled        = is this archetype usable at all yet

local PlanetArchetypes = {}

PlanetArchetypes.Temperate = {
	displayName = "Temperate World",
	allowedForHome = true,
	enabled = true,

	radiusRange = { min = 32, max = 42 },
	waterCoverageRange = { min = 0.45, max = 0.72 },
	cloudCoverageRange = { min = 0.25, max = 0.55 },
	atmosphereThicknessRange = { min = 0.65, max = 0.90 },
	iceCoverageRange = { min = 0.05, max = 0.18 },
	rotationSecondsRange = { min = 130, max = 190 },

	oceanPalette = {
		Color3.fromRGB(20, 70, 130),
		Color3.fromRGB(18, 95, 145),
		Color3.fromRGB(25, 85, 160),
	},
	landPalette = {
		Color3.fromRGB(65, 105, 65),
		Color3.fromRGB(90, 95, 55),
		Color3.fromRGB(70, 120, 80),
	},
	atmospherePalette = {
		Color3.fromRGB(100, 180, 255),
		Color3.fromRGB(120, 200, 255),
	},

	tags = { "rocky", "habitable", "temperate" },
}

PlanetArchetypes.Ocean = {
	displayName = "Ocean World",
	allowedForHome = true,
	enabled = true,

	radiusRange = { min = 34, max = 44 },
	waterCoverageRange = { min = 0.78, max = 0.95 },
	cloudCoverageRange = { min = 0.40, max = 0.70 },
	atmosphereThicknessRange = { min = 0.70, max = 0.92 },
	iceCoverageRange = { min = 0.03, max = 0.12 },
	rotationSecondsRange = { min = 150, max = 210 },

	oceanPalette = {
		Color3.fromRGB(15, 75, 120),
		Color3.fromRGB(20, 95, 135),
		Color3.fromRGB(18, 110, 140),
	},
	landPalette = {
		Color3.fromRGB(60, 100, 70),
		Color3.fromRGB(80, 90, 60),
	},
	atmospherePalette = {
		Color3.fromRGB(110, 190, 255),
		Color3.fromRGB(130, 205, 245),
	},

	tags = { "rocky", "habitable", "ocean" },
}

PlanetArchetypes.YoungHabitable = {
	displayName = "Young Habitable World",
	allowedForHome = true,
	enabled = true,

	radiusRange = { min = 30, max = 40 },
	waterCoverageRange = { min = 0.40, max = 0.65 },
	cloudCoverageRange = { min = 0.20, max = 0.45 },
	atmosphereThicknessRange = { min = 0.55, max = 0.80 },
	iceCoverageRange = { min = 0.00, max = 0.10 },
	rotationSecondsRange = { min = 120, max = 175 },

	oceanPalette = {
		Color3.fromRGB(25, 65, 110),
		Color3.fromRGB(30, 80, 120),
	},
	landPalette = {
		Color3.fromRGB(95, 80, 60),   -- volcanic brown
		Color3.fromRGB(80, 75, 70),   -- basalt grey
		Color3.fromRGB(75, 100, 65),  -- early green
	},
	atmospherePalette = {
		Color3.fromRGB(120, 165, 210),
		Color3.fromRGB(140, 175, 215),
	},

	tags = { "rocky", "habitable", "young" },
}

return PlanetArchetypes
