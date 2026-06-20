local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local GameConfig = require(ReplicatedStorage.GameConfig)
local Remotes = require(ReplicatedStorage.Remotes)
local DustField = require(ReplicatedStorage.DustField)
local OrganelleData = require(ReplicatedStorage.OrganelleData)
local MulticellularData = require(ReplicatedStorage.MulticellularData)
local Pricing = require(ReplicatedStorage.Pricing)
local InterventionData = require(ReplicatedStorage.InterventionData) -- Epic 6 ecosystem interventions

local DUST_TAG = "DustParticle"

local PlayerManager = {}

local profiles = {}
local rng = Random.new()

local function fireUpdate(player, profile)
	Remotes.MatterUpdate:FireClient(player, {
		matter = profile.matter,
	})
end

-- The Matter/sec a player produces across every cell they own.
local function totalProduction(profile)
	local sum = 0
	for _, cell in ipairs(profile.cells) do
		sum += cell.production
	end
	return sum
end

-- Production of a fully evolved (Eukaryotic) cell — its base rate plus every
-- organelle bonus. Used when a cell becomes Eukaryotic in one shot (the Cascade,
-- and post-cascade auto-Eukaryotic creation) instead of organelle-by-organelle.
local function fullyEvolvedProduction()
	return GameConfig.ARCHAEA_BASE_PRODUCTION + OrganelleData.TOTAL_PRODUCTION_BONUS
end

-- Turn a cell into a finished Eukaryotic Cell in place: mark every organelle owned,
-- set the Eukaryotic stage, and apply the full evolved production rate.
local function makeEukaryotic(cell)
	cell.purchased = {}
	for _, organelle in ipairs(OrganelleData.ORGANELLES) do
		cell.purchased[organelle.id] = true
	end
	cell.purchasedCount = OrganelleData.COUNT
	cell.stage = OrganelleData.STAGE_EUKARYOTIC
	cell.production = fullyEvolvedProduction()
end

-- Permanent Dust Multiplier earned for evolving a life form into a new tier for the
-- first time: floor((tier + 1)^2 / 2). Tier 1 (Eukaryotic) → 2, tier 2 → 4, tier 3
-- → 8, tier 4 → 12 … so each dust mote is worth that many Matter. (Only tier 1
-- exists today; the formula is ready for the higher tiers Epic 3+ will add.)
local function dustMultiplierForTier(tier)
	return math.floor(((tier + 1) ^ 2) / 2)
end

-- Record that the player evolved into `tier` for the first time and raise their
-- permanent Dust Multiplier accordingly. Monotonic — a higher tier never lowers it.
local function applyTierEvolution(profile, tier)
	if tier <= profile.maxTierEvolved then
		return
	end
	profile.maxTierEvolved = tier
	profile.dustMultiplier = math.max(profile.dustMultiplier, dustMultiplierForTier(tier))
end

-- A replication-safe snapshot of one cell (no functions; `purchased` is a plain
-- map of organelleId → true so the client can render slots in OrganelleData order).
local function serializeCell(cell)
	local purchased = {}
	for id in pairs(cell.purchased) do
		purchased[id] = true
	end
	return {
		id = cell.id,
		stage = cell.stage,
		purchased = purchased,
		purchasedCount = cell.purchasedCount,
		production = cell.production,
	}
end

-- Push the player's full converter state: how many cells they own, the summed
-- production, and each cell's per-organelle state. `archaeaCount` is kept for the
-- older read-only overview UI (it now means "number of cells").
local function fireConverterUpdate(player, profile)
	local cells = {}
	for _, cell in ipairs(profile.cells) do
		table.insert(cells, serializeCell(cell))
	end
	-- Dynamic next-cell cost (grows with cells owned) and next multicellular upgrade
	-- cost (grows with upgrades bought) so the UI can show live, server-matching prices.
	local nextUpgrade = MulticellularData.next(profile.multicellularUpgrades)
	Remotes.ConverterUpdate:FireClient(player, {
		archaeaCount = #profile.cells,
		totalProduction = totalProduction(profile),
		cells = cells,
		dustMultiplier = profile.dustMultiplier,   -- Matter awarded per dust mote (UI "Dust Value")
		cascadeTriggered = profile.cascadeTriggered, -- once true, new cells are born Eukaryotic (drives the Create button label)
		cellCost = Pricing.cellCost(#profile.cells), -- Matter for the NEXT cell (dynamic)
		multicellularUpgrades = profile.multicellularUpgrades, -- 0..6 player-wide upgrades bought
		nextUpgradeCost = nextUpgrade and Pricing.upgradeCost(nextUpgrade.baseCost, profile.multicellularUpgrades) or nil,
		-- Epic 6 ecosystem state (drives the Ecosystem Interventions UI).
		lifeProgress = profile.lifeProgress,
		lifeProgressMax = 100,
		stability = profile.stability,
	})
end

local function createProfile(player)
	-- matter is a FLOAT now (production rates are fractional per second). cells is
	-- an array of per-cell tables; nextCellId hands out stable ids for the UI.
	-- cascadeTriggered: has the one-time Eukaryotic Cascade fired yet? dustMultiplier:
	-- Matter awarded per dust mote (starts at 1, raised permanently by tier evolutions).
	-- maxTierEvolved: highest life-form tier the player has ever evolved into.
	-- (None of these persist yet — they reset on rejoin until the DataStore epic.)
	local profile = {
		matter = 0,
		cells = {},
		nextCellId = 1,
		cascadeTriggered = false,
		dustMultiplier = 1,
		maxTierEvolved = 0,
		multicellularUpgrades = 0, -- player-wide Eukaryotic→Multicellular upgrades bought (0..6)
		-- Epic 6 ecosystem progression (planet-level, distinct from the cell economy).
		-- Initialized here but only meaningful/shown once life exists. 0–100 each.
		lifeProgress = 0,
		stability = 75,
	}
	profiles[player.UserId] = profile

	-- Push initial state immediately so the HUD shows "Matter: 0" right away
	-- and the converter UI shows "0 cells" before any interaction.
	fireUpdate(player, profile)
	fireConverterUpdate(player, profile)
end

local function removeProfile(player)
	profiles[player.UserId] = nil
end

local function addMatter(player, amount)
	local profile = profiles[player.UserId]
	if not profile then return end
	profile.matter += amount
	fireUpdate(player, profile)
end

-- Collect a mote for one player: award Matter, hide the mote, then bring it
-- back at a fresh universe-wide spot after DUST_RESPAWN_TIME.
local function collect(player, mote)
	if mote:GetAttribute("Collected") then return end
	mote:SetAttribute("Collected", true)
	mote:SetAttribute("Pulling", false)
	mote.Transparency = 1
	local light = mote:FindFirstChildWhichIsA("PointLight")
	if light then light.Enabled = false end

	-- One mote is worth the player's permanent Dust Multiplier in Matter (1 until
	-- they first evolve a life form, then 2/4/8/… as they reach higher tiers).
	local profile = profiles[player.UserId]
	addMatter(player, profile and profile.dustMultiplier or 1)

	task.delay(GameConfig.DUST_RESPAWN_TIME, function()
		if not mote.Parent then return end
		local pos = DustField.getSpawnPosition(rng)
		mote.Position = pos
		mote:SetAttribute("BasePosition", pos)
		mote:SetAttribute("Pulling", false)
		mote.Transparency = 0
		if light then light.Enabled = true end
		mote:SetAttribute("Collected", false)
	end)
end

-- Server-authoritative magnet collection. Each frame, motes within
-- DUST_MAGNET_RADIUS of a player are pulled toward them (faster as they get
-- closer) and collected once they reach DUST_COLLECT_RADIUS. The server drives
-- the pulled mote's position (and flags it "Pulling") so the client bob yields
-- to it; motes that fall out of range are released back to their home spot.
local function runMagnet(dt)
	local motes = CollectionService:GetTagged(DUST_TAG)
	if #motes == 0 then return end

	-- Snapshot live player root positions once for this frame.
	local roots = {}
	for _, player in Players:GetPlayers() do
		if profiles[player.UserId] then
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if hrp then
				table.insert(roots, { player = player, pos = hrp.Position })
			end
		end
	end
	if #roots == 0 then return end

	for _, mote in motes do
		if mote:GetAttribute("Collected") then continue end

		-- Nearest player to this mote.
		local motePos = mote.Position
		local best, bestDist
		for _, r in roots do
			local d = (r.pos - motePos).Magnitude
			if not bestDist or d < bestDist then
				bestDist, best = d, r
			end
		end

		if bestDist <= GameConfig.DUST_COLLECT_RADIUS then
			collect(best.player, mote)
		elseif bestDist <= GameConfig.DUST_MAGNET_RADIUS then
			-- Pull toward the player, accelerating as it nears for a snappy magnet feel.
			mote:SetAttribute("Pulling", true)
			local closeness = 1 - (bestDist / GameConfig.DUST_MAGNET_RADIUS) -- 0 at edge → ~1 near player
			local speed = GameConfig.DUST_PULL_SPEED * (1 + GameConfig.DUST_PULL_FORCE * closeness)
			local step = math.min(speed * dt, bestDist)
			mote.Position = motePos + (best.pos - motePos).Unit * step
		elseif mote:GetAttribute("Pulling") then
			-- Player left magnet range before collecting; release the mote home.
			mote:SetAttribute("Pulling", false)
			local base = mote:GetAttribute("BasePosition")
			if base then mote.Position = base end
		end
	end
end

local function runCollection()
	RunService.Heartbeat:Connect(runMagnet)
end

-- Find a player's own planet model (built by PlayerPlanetService under
-- workspace.SpaceEnvironment.PlayerPlanets). Matched by the OwnerUserId attribute
-- so we never touch someone else's world.
local function findPlayerPlanet(player)
	local env = workspace:FindFirstChild("SpaceEnvironment")
	local folder = env and env:FindFirstChild("PlayerPlanets")
	if not folder then return nil end
	for _, model in folder:GetChildren() do
		if model:IsA("Model") and model:GetAttribute("OwnerUserId") == player.UserId then
			return model
		end
	end
	return nil
end

-- Matter Converter: a player spends Matter to create one basic Archaea Cell. The
-- server is authoritative — it checks the player can afford it, deducts the cost,
-- and appends a fresh cell to their list. There is NO cap on how many cells a
-- player may own; each one carries its own organelle upgrade path. Cheaters can't
-- fake a cell because the list never leaves the server.
local function onCreateArchaea(player)
	local profile = profiles[player.UserId]
	if not profile then return end

	-- Dynamic cell pricing: the cost of the next cell grows with how many the player
	-- already owns (Pricing.cellCost). Server is authoritative over the price.
	local cost = Pricing.cellCost(#profile.cells)
	if profile.matter < cost then return end -- can't afford it; ignore

	profile.matter -= cost

	local cell = {
		id = profile.nextCellId,
		stage = OrganelleData.STAGE_ARCHAEA,
		purchased = {},                              -- organelleId -> true
		purchasedCount = 0,
		production = GameConfig.ARCHAEA_BASE_PRODUCTION, -- Matter/sec; grows per organelle
	}
	profile.nextCellId += 1

	-- After the Eukaryotic Cascade, the player's lineage is "post-Archaea": every
	-- new cell is born already fully Eukaryotic (no need to re-walk the organelle
	-- path). They still pay the same creation cost — the Cascade is the reward.
	if profile.cascadeTriggered then
		makeEukaryotic(cell)
	end

	table.insert(profile.cells, cell)

	-- The very first cell sparks life: flip the planet to the Archaea stage so the
	-- inspect panel reads "Archaea / Microbial" and PlanetStageVisuals shows the
	-- glow. (Server owns this; the client only ever requested the purchase.) We
	-- don't advance the planet past tier 1 here — later tiers are a future epic.
	if #profile.cells == 1 then
		local planet = findPlayerPlanet(player)
		if planet then
			planet:SetAttribute("EvolutionTier", 1)
			planet:SetAttribute("EvolutionStage", "Archaea")
		end
	end

	fireUpdate(player, profile)          -- Matter went down
	fireConverterUpdate(player, profile) -- a new cell appeared
end

-- Find one of a player's cells by id, or nil.
local function findCell(profile, cellId)
	for _, cell in ipairs(profile.cells) do
		if cell.id == cellId then
			return cell
		end
	end
	return nil
end

-- Organelle upgrade: a player spends Matter to add the NEXT organelle to a
-- specific cell, raising that cell's production. The order is fixed (OrganelleData)
-- and enforced here — the request must name the exact next organelle for that
-- cell, so the client can never skip ahead or double-buy. When the final organelle
-- (the Nucleus) is bought, the cell evolves Archaea → Eukaryotic and we announce it.
local function onPurchaseOrganelle(player, payload)
	local profile = profiles[player.UserId]
	if not profile then return end
	if typeof(payload) ~= "table" then return end

	local cellId = payload.cellId
	local organelleId = payload.organelleId
	if typeof(cellId) ~= "number" or typeof(organelleId) ~= "string" then return end

	local cell = findCell(profile, cellId)
	if not cell then return end
	if OrganelleData.isComplete(cell.purchasedCount) then return end -- already a Eukaryote

	-- Must be exactly the next organelle in the path for this cell.
	local expected = OrganelleData.nextOrganelle(cell.purchasedCount)
	if not expected or expected.id ~= organelleId then return end
	if cell.purchased[organelleId] then return end -- defensive: never double-buy

	if profile.matter < expected.cost then return end -- can't afford it; ignore

	profile.matter -= expected.cost
	cell.purchased[organelleId] = true
	cell.purchasedCount += 1
	cell.production += expected.productionBonus

	-- Final organelle completes the evolution into a Eukaryotic Cell.
	local evolved = false
	if OrganelleData.isComplete(cell.purchasedCount) then
		cell.stage = OrganelleData.STAGE_EUKARYOTIC
		evolved = true
	end

	-- The FIRST time a player ever completes a Eukaryotic Cell, the Eukaryotic
	-- Cascade fires: every OTHER cell they own evolves to Eukaryotic instantly, and
	-- reaching Tier 1 permanently raises their Dust Multiplier. It happens once.
	local cascadeFired = false
	local cascadedIds = nil
	if evolved and not profile.cascadeTriggered then
		profile.cascadeTriggered = true
		cascadeFired = true

		cascadedIds = {}
		for _, other in ipairs(profile.cells) do
			if other.id ~= cell.id and other.stage ~= OrganelleData.STAGE_EUKARYOTIC then
				makeEukaryotic(other)
				table.insert(cascadedIds, other.id)
			end
		end

		applyTierEvolution(profile, 1) -- Eukaryotic is Tier 1 → Dust Multiplier becomes 2

		-- Reflect the leap on the planet itself (the inspect panel + glow read this).
		local planet = findPlayerPlanet(player)
		if planet then
			planet:SetAttribute("EvolutionStage", "Eukaryotic")
		end
	end

	fireUpdate(player, profile)          -- Matter went down
	fireConverterUpdate(player, profile) -- this cell (and any cascaded cells) changed

	if cascadeFired then
		-- One celebration for the whole moment: bursts across every cell that just
		-- turned Eukaryotic + the "Eukaryotic Evolution Cascade!" / "Dust Value ×N"
		-- announcement. Authoritative state already went out via ConverterUpdate.
		Remotes.CascadeTriggered:FireClient(player, {
			triggerCellId = cell.id,
			cellIds = cascadedIds,
			count = #cascadedIds,
			dustMultiplier = profile.dustMultiplier,
		})
	elseif evolved then
		-- A lone cell finishing the path after the cascade already happened. New cells
		-- are born Eukaryotic so this is unreachable in normal play, but kept so the
		-- single-cell "Eukaryotic Cell Unlocked!" feedback survives any future change.
		Remotes.CellEvolved:FireClient(player, { cellId = cell.id })
	end
end

-- Ecosystem interventions (Epic 6): a single server-authoritative path for the
-- planet-level interventions (Nourish Microbes / Stabilize Oceans / Accelerate
-- Mutation). Reads InterventionData; validates state/requirements/cost; applies the
-- LifeProgress / Stability effects (clamped 0–100); syncs the planet model and pushes
-- ConverterUpdate. It never touches cells, so it can't conflict with the cell economy.
local LIFE_PROGRESS_MAX = 100

local function interventionRequirementsMet(profile, player, def)
	local req = def.requirements or {}
	if req.lifeExists and #profile.cells <= 0 then
		return false
	end
	if req.minEvolutionTier then
		local planet = findPlayerPlanet(player)
		local tier = (planet and planet:GetAttribute("EvolutionTier")) or 0
		if tier < req.minEvolutionTier then
			return false
		end
	end
	return true
end

local function onApplyIntervention(player, payload)
	local profile = profiles[player.UserId]
	if not profile then return end

	local id = (typeof(payload) == "table" and payload.interventionId) or payload
	if typeof(id) ~= "string" then return end

	local def = InterventionData.get(id)
	if not def or def.state ~= "Active" then return end -- unknown or not live

	if not interventionRequirementsMet(profile, player, def) then return end

	local effects = def.effects or {}
	-- Don't run a Life-Progress action once maxed; don't run a pure Stability action at max.
	if (effects.addLifeProgress or 0) > 0 and profile.lifeProgress >= LIFE_PROGRESS_MAX then return end
	if (effects.addStability or 0) > 0 and not effects.addLifeProgress and profile.stability >= 100 then return end

	local cost = (def.cost and def.cost.Matter) or 0
	if profile.matter < cost then return end -- can't afford

	-- Validated → deduct, then apply (clamped). Never deduct before all checks pass.
	profile.matter -= cost
	if effects.addLifeProgress then
		profile.lifeProgress = math.clamp(profile.lifeProgress + effects.addLifeProgress, 0, LIFE_PROGRESS_MAX)
	end
	if effects.addStability then
		profile.stability = math.clamp(profile.stability + effects.addStability, 0, 100)
	end

	-- Mirror to the planet so the inspect UI / visuals can read it (own planet only).
	local planet = findPlayerPlanet(player)
	if planet then
		planet:SetAttribute("LifeProgress", profile.lifeProgress)
		planet:SetAttribute("Stability", profile.stability)
		planet:SetAttribute("LifeProgressMax", LIFE_PROGRESS_MAX)
	end

	fireUpdate(player, profile)          -- Matter changed
	fireConverterUpdate(player, profile) -- lifeProgress / stability changed
end

-- Multicellular upgrade (Tier 1C): a player spends Matter on the NEXT player-wide
-- Eukaryotic→Multicellular upgrade. Server-authoritative and order-enforced: only
-- available once the Eukaryotic stage is reached, bought strictly in order, priced
-- dynamically (each prior upgrade makes the next 10% costlier). One purchase per call.
local function onPurchaseUpgrade(player)
	local profile = profiles[player.UserId]
	if not profile then return end
	if not profile.cascadeTriggered then return end -- must be Eukaryotic first
	if MulticellularData.isComplete(profile.multicellularUpgrades) then return end -- already a Multicellular Organism

	local nextUpgrade = MulticellularData.next(profile.multicellularUpgrades)
	if not nextUpgrade then return end

	local cost = Pricing.upgradeCost(nextUpgrade.baseCost, profile.multicellularUpgrades)
	if profile.matter < cost then return end -- can't afford it; ignore

	profile.matter -= cost
	profile.multicellularUpgrades += 1
	local step = profile.multicellularUpgrades

	-- The final upgrade completes the Multicellular Organism stage.
	if MulticellularData.isComplete(profile.multicellularUpgrades) then
		local planet = findPlayerPlanet(player)
		if planet then
			planet:SetAttribute("EvolutionStage", "Multicellular")
		end
	end

	fireUpdate(player, profile)          -- Matter went down
	fireConverterUpdate(player, profile) -- upgrade count + next cost changed

	-- One-shot feedback: drives the biosphere visual progression + a toast.
	Remotes.UpgradePurchased:FireClient(player, { step = step, upgradeId = nextUpgrade.id })
end

-- Passive Matter income: every PRODUCTION_TICK_INTERVAL seconds, each player earns
-- their summed per-second production (across all cells) × the elapsed interval. One
-- shared timer drives every player's production so it stays cheap as cell counts
-- grow. Matter accrues as a float; the HUD floors it for display.
local function runProduction()
	task.spawn(function()
		local interval = GameConfig.PRODUCTION_TICK_INTERVAL
		while true do
			task.wait(interval)
			for _, player in Players:GetPlayers() do
				local profile = profiles[player.UserId]
				if profile and #profile.cells > 0 then
					local gain = totalProduction(profile) * interval
					if gain > 0 then
						addMatter(player, gain)
					end
				end
			end
		end
	end)
end

function PlayerManager.init()
	Players.PlayerAdded:Connect(createProfile)
	Players.PlayerRemoving:Connect(removeProfile)

	for _, player in Players:GetPlayers() do
		createProfile(player)
	end

	Remotes.CreateArchaea.OnServerEvent:Connect(onCreateArchaea)
	Remotes.PurchaseOrganelle.OnServerEvent:Connect(onPurchaseOrganelle)
	Remotes.PurchaseUpgrade.OnServerEvent:Connect(onPurchaseUpgrade)
	Remotes.ApplyIntervention.OnServerEvent:Connect(onApplyIntervention)

	-- ⚠️ DEV/TESTING ONLY — remove before launch (along with the DevGrantMatter remote
	-- and DevMenu.client.luau). Grants the requesting player Matter so we don't have to
	-- replay every stage to test late-game. Capped so a stray value can't break things.
	Remotes.DevGrantMatter.OnServerEvent:Connect(function(player, amount)
		if typeof(amount) ~= "number" or amount ~= amount then return end -- nil/NaN guard
		amount = math.clamp(math.floor(amount), 0, 1e9)
		if amount > 0 then
			addMatter(player, amount)
		end
	end)

	runCollection()
	runProduction()
end

return PlayerManager
