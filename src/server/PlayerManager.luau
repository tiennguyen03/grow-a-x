local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local GameConfig = require(ReplicatedStorage.GameConfig)
local Remotes = require(ReplicatedStorage.Remotes)
local DustField = require(ReplicatedStorage.DustField)
local OrganelleData = require(ReplicatedStorage.OrganelleData)

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
	Remotes.ConverterUpdate:FireClient(player, {
		archaeaCount = #profile.cells,
		totalProduction = totalProduction(profile),
		cells = cells,
	})
end

local function createProfile(player)
	-- matter is a FLOAT now (production rates are fractional per second). cells is
	-- an array of per-cell tables; nextCellId hands out stable ids for the UI.
	local profile = { matter = 0, cells = {}, nextCellId = 1 }
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

	addMatter(player, 1)

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

	local cost = GameConfig.MATTER_CONVERTER_COST_ARCHAEA
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

	fireUpdate(player, profile)          -- Matter went down
	fireConverterUpdate(player, profile) -- this cell's state changed

	if evolved then
		-- One-shot announcement for the client celebration (green pulse, burst,
		-- "Eukaryotic Cell Unlocked!" toast). The authoritative state already went
		-- out via ConverterUpdate above; this is purely the feedback trigger.
		Remotes.CellEvolved:FireClient(player, { cellId = cell.id })
	end
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

	runCollection()
	runProduction()
end

return PlayerManager
