-- Multicellular data — the Tier 1C upgrade path: Eukaryotic Cell → Multicellular
-- Organism (Epic 3, Sprint 1C).
--
-- After a player reaches the Eukaryotic stage (the organelle path is complete and the
-- Eukaryotic Cascade has fired), they unlock six PLAYER-WIDE upgrades, bought in a
-- fixed order. Unlike organelles (per-cell, fixed price), these are global and use
-- DYNAMIC pricing — each one bought makes the next 10% pricier (see Pricing.upgradeCost).
--
-- Pure data shared by server (validates purchases) and client (renders the panel +
-- the Microscope/Life Vessel visual progression). Holds no Instances and no state.
-- `visual` is a key the client maps to a cosmetic layer in the biosphere views.

local MulticellularData = {}

-- The ordered Eukaryotic → Multicellular path. `baseCost` feeds Pricing.upgradeCost
-- with the running count of upgrades already purchased.
MulticellularData.UPGRADES = {
	{
		id = "adhesion",
		name = "Cell Adhesion Molecules",
		baseCost = 80,
		visual = "adhesion",
		description = "Cells grow sticky — tiny filaments form between them and they begin to cling together.",
	},
	{
		id = "signaling",
		name = "Intercellular Signaling",
		baseCost = 100,
		visual = "signaling",
		description = "Connected cells talk: signal pulses travel between them.",
	},
	{
		id = "matrix",
		name = "Extracellular Matrix",
		baseCost = 120,
		visual = "matrix",
		description = "A mesh-like scaffold forms around the cluster, binding it into one body.",
	},
	{
		id = "cellcycle",
		name = "Cell Cycle Coordination",
		baseCost = 150,
		visual = "cellcycle",
		description = "Division falls into step — cells split in coordinated waves.",
	},
	{
		id = "differentiation",
		name = "Early Differentiation",
		baseCost = 200,
		visual = "differentiation",
		description = "Cells begin to specialize, taking on different shapes and colors.",
	},
	{
		id = "tissue",
		name = "Tissue Scaffolding",
		baseCost = 250,
		visual = "tissue",
		description = "Specialized cells organize into defined tissue structures — a true Multicellular Organism.",
	},
}

MulticellularData.COUNT = #MulticellularData.UPGRADES -- 6

-- The upgrade at a 1-based step (1 = first), or nil past the end.
function MulticellularData.at(step: number)
	return MulticellularData.UPGRADES[step]
end

-- The next upgrade to buy given how many are already purchased, or nil if complete.
function MulticellularData.next(purchased: number)
	return MulticellularData.UPGRADES[purchased + 1]
end

-- True once all six upgrades are bought — the player is a Multicellular Organism.
function MulticellularData.isComplete(purchased: number): boolean
	return purchased >= MulticellularData.COUNT
end

return MulticellularData
