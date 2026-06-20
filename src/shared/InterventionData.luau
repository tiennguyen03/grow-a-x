-- Intervention definitions — the generic, data-driven format for planet
-- interventions / upgrades (Epic 5 "Matter Core").
--
-- This module is the FORMAT planet interventions plug into. The Tier-1 cell flow
-- (Create Life + organelle upgrades) is owned by Nova's PlayerManager /
-- OrganelleData / CellInterventionUI and is NOT duplicated here — `create_life`
-- appears only as the canonical reference (state = "Active", handled elsewhere).
--
-- The `category = "Ecosystem"` entries are the live Epic 6 ecosystem interventions
-- (Nourish Microbes / Stabilize Oceans / Accelerate Mutation). Both ends read this
-- one table: the server `PlayerManager.onApplyIntervention` validates `requirements`
-- /`cost` and applies `effects` (LifeProgress / Stability), and the client
-- `EcosystemInterventionUI` renders the cards. Adding a new intervention is one
-- entry here (+ a new `effects` branch on the server only if it's a new effect type).
--
-- Pure data + helpers — no services, no Instances. Safe to require on both sides.

local InterventionData = {}

InterventionData.CATEGORY_LIFE = "Life"

-- state:
--   "Active"     — already implemented elsewhere; DON'T render a duplicate card
--   "ComingSoon" — previewed now, implemented in `unlockEpic`
--   "Locked"     — visible but gated behind an unmet requirement (future use)
local DEFS = {
	{
		id = "create_life",
		displayName = "Create Life",
		category = "Life",
		description = "Spark the first Archaea Cell on your Origin World.",
		flavor = "Out of dust and Matter, the first fragile spark of life.",
		cost = { Matter = 15 },
		repeatable = true, -- Nova's model: a player may own many cells
		requirements = { evolutionStage = "Prebiotic" },
		effects = { setEvolutionTier = 1, setEvolutionStage = "Archaea", addCell = 1 },
		state = "Active",
		handledBy = "PlayerManager.onCreateArchaea + CellInterventionUI",
		sortOrder = 10,
	},
	-- Ecosystem interventions (Epic 6): planet-level support around the cells, NOT a
	-- second cell economy. Preview-only until Epic 6 wires the live effects.
	{
		id = "nourish_microbes",
		displayName = "Nourish Microbes",
		category = "Ecosystem",
		description = "Feed fragile ecosystems with patient nutrients so early life can spread.",
		flavor = "Patient nutrients turn a spark into an ecosystem.",
		cost = { Matter = 20 },
		repeatable = true,
		requirements = { lifeExists = true, minEvolutionTier = 1 },
		effects = { addLifeProgress = 20 },
		state = "Active",
		sortOrder = 100,
	},
	{
		id = "stabilize_oceans",
		displayName = "Stabilize Oceans",
		category = "Ecosystem",
		description = "Calm the planet's oceans so fragile cells can survive and multiply.",
		flavor = "A steady sea is a cradle, not a grave.",
		cost = { Matter = 25 },
		repeatable = true,
		requirements = { lifeExists = true, minEvolutionTier = 1 },
		effects = { addStability = 15 },
		state = "Active",
		sortOrder = 110,
	},
	{
		id = "accelerate_mutation",
		displayName = "Accelerate Mutation",
		category = "Ecosystem",
		description = "Force rapid adaptation. Evolution moves faster, but the ecosystem becomes less stable.",
		flavor = "Evolution loves a gamble — so do you.",
		cost = { Matter = 25 },
		repeatable = true,
		requirements = { lifeExists = true, minEvolutionTier = 1 },
		effects = { addLifeProgress = 35, addStability = -10 },
		state = "Active",
		sortOrder = 120,
	},
}

-- Stable display order + id index.
table.sort(DEFS, function(a, b)
	return a.sortOrder < b.sortOrder
end)
local byId = {}
for _, d in DEFS do
	byId[d.id] = d
end

function InterventionData.getAll()
	return DEFS
end

function InterventionData.get(id: string)
	return byId[id]
end

-- Interventions to render as previews: everything not already live ("Active").
function InterventionData.getPreviews()
	local out = {}
	for _, d in DEFS do
		if d.state ~= "Active" then
			table.insert(out, d)
		end
	end
	return out
end

-- Live, interactive ecosystem interventions (Epic 6): Active + category "Ecosystem".
-- (Excludes `create_life`, which is category "Life" and owned by Nova's cell flow.)
function InterventionData.getEcosystemActive()
	local out = {}
	for _, d in DEFS do
		if d.state == "Active" and d.category == "Ecosystem" then
			table.insert(out, d)
		end
	end
	return out
end

-- A friendly one-line summary of a definition's effects for a card.
function InterventionData.effectSummary(def): string
	local parts = {}
	local e = def.effects or {}
	if e.addLifeProgress then
		table.insert(parts, string.format("Life Progress %+d", e.addLifeProgress))
	end
	if e.addStability then
		table.insert(parts, string.format("Stability %+d", e.addStability))
	end
	if e.setEvolutionStage then
		table.insert(parts, "→ " .. e.setEvolutionStage)
	end
	if #parts == 0 then
		return "—"
	end
	return table.concat(parts, " · ")
end

return InterventionData
