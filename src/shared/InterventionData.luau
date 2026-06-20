-- Intervention definitions — the generic, data-driven format for planet
-- interventions / upgrades (Epic 5 "Matter Core").
--
-- This module is the FORMAT future interventions plug into. The active Tier-1
-- flow (Create Life + organelle upgrades) is owned by Nova's PlayerManager /
-- OrganelleData / CellInterventionUI and is NOT duplicated here — `create_life`
-- appears only as the canonical reference example (state = "Active", handled
-- elsewhere). The other entries are FUTURE interventions (Epic 6: Early Evolution
-- Progression) surfaced now as read-only "Coming Soon" previews by
-- InterventionPreviewUI.
--
-- When Epic 6 implements LifeProgress / Stability, a "ComingSoon" entry becomes
-- live by: (1) flipping its `state`, and (2) adding a server handler that reads
-- this entry's `cost` / `requirements` / `effects` and applies them — without a
-- second purchase framework. See "Extension points" in docs/EPICS/Epic5.md.
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
	{
		id = "nourish_microbes",
		displayName = "Nourish Microbes",
		category = "Life",
		description = "Feed the first fragile ecosystems and prepare the planet for more complex life.",
		flavor = "Patience and nutrients turn a spark into an ecosystem.",
		cost = { Matter = 20 },
		repeatable = false,
		requirements = { evolutionStage = "Archaea" },
		effects = { addLifeProgress = 20 },
		state = "ComingSoon",
		unlockEpic = 6,
		sortOrder = 20,
	},
	{
		id = "stabilize_oceans",
		displayName = "Stabilize Oceans",
		category = "Life",
		description = "Calm violent oceans so fragile life can endure.",
		flavor = "A steady sea is a cradle, not a grave.",
		cost = { Matter = 25 },
		repeatable = false,
		requirements = { lifeExists = true },
		effects = { addStability = 15 },
		state = "ComingSoon",
		unlockEpic = 6,
		sortOrder = 30,
	},
	{
		id = "accelerate_mutation",
		displayName = "Accelerate Mutation",
		category = "Life",
		description = "Push life to change faster. Progress comes quickly, but fragile ecosystems may become unstable.",
		flavor = "Evolution loves a gamble — so do you.",
		cost = { Matter = 25 },
		repeatable = true,
		requirements = { evolutionStage = "Archaea" },
		effects = { addLifeProgress = 35, addStability = -10 },
		state = "ComingSoon",
		unlockEpic = 6,
		sortOrder = 40,
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
