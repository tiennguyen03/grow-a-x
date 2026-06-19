-- Organelle data — the Tier 1 (Archaea → Eukaryotic) upgrade path (Epic 3).
--
-- A single Archaea Cell starts as the simplest form of life and is upgraded one
-- organelle at a time, in a fixed order, each organelle raising that cell's
-- passive Matter production. Buying the final organelle (the Nucleus) evolves the
-- cell from Archaea into a Eukaryotic Cell, completing Tier 1.
--
-- This is PURE DATA shared by server (validates purchases, applies bonuses) and
-- client (renders the upgrade panel + per-organelle planet visuals). It holds no
-- Instances and no state. Future tiers (Bacteria, Tier 2…) will add their own
-- ordered paths alongside this one.
--
-- Order matters: ORGANELLES is the canonical purchase sequence. Each organelle
-- unlocks the next; you cannot skip ahead. The costs sum to TOTAL_COST (240) and
-- the production bonuses sum to 3.5 Matter/sec — a fully evolved cell produces
-- about that much (see GameConfig.ARCHAEA_BASE_PRODUCTION for the small starting
-- rate a fresh, organelle-less cell makes).

local OrganelleData = {}

-- The ordered Archaea → Eukaryotic organelle path. `visual` is a key the
-- client-side CellVisuals script maps to a cosmetic layer on the cell.
OrganelleData.ORGANELLES = {
	{
		id = "membrane",
		name = "Cell Membrane",
		cost = 5,
		productionBonus = 0.2,
		visual = "membrane",
		description = "A boundary forms — the cell becomes a distinct living thing.",
	},
	{
		id = "cytoplasm",
		name = "Cytoplasm",
		cost = 10,
		productionBonus = 0.2,
		visual = "cytoplasm",
		description = "Inner fluid fills the cell, hosting its chemistry.",
	},
	{
		id = "ribosomes",
		name = "Ribosomes",
		cost = 15,
		productionBonus = 0.3,
		visual = "ribosomes",
		description = "Protein factories switch on, accelerating growth.",
	},
	{
		id = "nucleoid",
		name = "Nucleoid",
		cost = 25,
		productionBonus = 0.4,
		visual = "nucleoid",
		description = "Genetic material gathers into a denser core.",
	},
	{
		id = "plasmids",
		name = "Plasmids",
		cost = 40,
		productionBonus = 0.6,
		visual = "plasmids",
		description = "Extra gene rings grant new metabolic tricks.",
	},
	{
		id = "mitochondria",
		name = "Mitochondria",
		cost = 60,
		productionBonus = 0.8,
		visual = "mitochondria",
		description = "The powerhouse of the cell — energy output surges.",
	},
	{
		id = "nucleus",
		name = "Nucleus",
		cost = 85,
		productionBonus = 1.0,
		visual = "nucleus",
		description = "A true nucleus forms. The cell evolves into a Eukaryote.",
	},
}

-- Stage names before and after the path is complete.
OrganelleData.STAGE_ARCHAEA = "Archaea"
OrganelleData.STAGE_EUKARYOTIC = "Eukaryotic"

-- Derived constants (computed once at require time).
local total = 0
local byId = {}
local indexById = {}
for i, organelle in ipairs(OrganelleData.ORGANELLES) do
	total += organelle.cost
	byId[organelle.id] = organelle
	indexById[organelle.id] = i
end

OrganelleData.COUNT = #OrganelleData.ORGANELLES -- 7
OrganelleData.TOTAL_COST = total                -- 240

-- The organelle definition for an id, or nil if unknown.
function OrganelleData.get(id: string)
	return byId[id]
end

-- 1-based position of an organelle in the purchase order, or nil if unknown.
function OrganelleData.indexOf(id: string): number?
	return indexById[id]
end

-- The next organelle a cell should buy given how many it already owns
-- (purchasedCount), or nil if the path is complete. This is the ONLY purchasable
-- organelle at any time — the server enforces the order through this.
function OrganelleData.nextOrganelle(purchasedCount: number)
	return OrganelleData.ORGANELLES[purchasedCount + 1]
end

-- True once a cell with `purchasedCount` organelles has the whole path and has
-- become a Eukaryotic Cell.
function OrganelleData.isComplete(purchasedCount: number): boolean
	return purchasedCount >= OrganelleData.COUNT
end

return OrganelleData
