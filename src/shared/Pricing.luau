-- Pricing — the dynamic cost formulas for cells and upgrades (Epic 3, Sprint 1C).
--
-- Shared by the SERVER (authoritative validation/deduction) and the CLIENT (live UI
-- display), so the number the player sees always equals the number the server charges.
-- Pure functions, no state, no Instances.

local Pricing = {}

-- Cost to create the NEXT cell, given how many the player already owns. The cost
-- grows gently then accelerates so building wide stays meaningful without becoming
-- punishing. (Matches the Sprint 1C balance table: 0→15, 1→16.2, 5→21, 10→28.5,
-- 20→45, 50→~113, 100→285.)
--
-- NOTE: the design brief also wrote this as `15 * (1 + n*0.08)^1.2`, but that form
-- does NOT reproduce the brief's own example table (it gives ~209 at 100 cells, not
-- 285). The quadratic below matches the worked examples, so it's the source of truth.
-- To switch to the literal power form, replace the body with:
--   return 15 * (1 + n * 0.08) ^ 1.2
function Pricing.cellCost(ownedCells: number): number
	local n = math.max(0, ownedCells)
	return 15 * (1 + 0.08 * n + 0.001 * n * n)
end

-- Cost of an upgrade given its base cost and how many upgrades the player has already
-- bought: each prior purchase adds 10%. (1C example: bases 80/100/120/150/200/250
-- bought in order → 80, 110, 144, 195, 280, 375.)
function Pricing.upgradeCost(baseCost: number, upgradesPurchased: number): number
	return baseCost * (1 + math.max(0, upgradesPurchased) * 0.1)
end

-- Costs are floats; the UI shows whole Matter. Round half-up for display.
function Pricing.display(cost: number): number
	return math.floor(cost + 0.5)
end

return Pricing
