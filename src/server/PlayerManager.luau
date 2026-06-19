local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local GameConfig = require(ReplicatedStorage.GameConfig)
local Remotes = require(ReplicatedStorage.Remotes)
local DustField = require(ReplicatedStorage.DustField)

local DUST_TAG = "DustParticle"

local PlayerManager = {}

local profiles = {}
local rng = Random.new()

local function fireUpdate(player, profile)
	Remotes.MatterUpdate:FireClient(player, {
		matter = profile.matter,
	})
end

-- Push the player's Matter Converter state (Archaea count, etc.) so the
-- converter UI can show how many cells they own.
local function fireConverterUpdate(player, profile)
	Remotes.ConverterUpdate:FireClient(player, {
		archaeaCount = profile.archaeaCount,
	})
end

local function createProfile(player)
	local profile = { matter = 0, archaeaCount = 0 }
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

-- Matter Converter: a player spends Matter to create one Archaea Cell. The
-- server is authoritative — it checks the player can afford it, deducts the
-- cost, and increments their cell count. Cheaters can't fake a cell because the
-- count never leaves the server.
local function onCreateArchaea(player)
	local profile = profiles[player.UserId]
	if not profile then return end

	local cost = GameConfig.MATTER_CONVERTER_COST_ARCHAEA
	if profile.matter < cost then return end -- can't afford it; ignore

	profile.matter -= cost
	profile.archaeaCount += 1

	-- First cell sparks life: flip the planet to the Archaea stage so the inspect
	-- panel reads "Archaea / Microbial" and PlanetStageVisuals shows the glow.
	-- (Server owns this; the client only ever requested the purchase.) We don't
	-- advance past tier 1 here — the full evolution tree is a later epic.
	if profile.archaeaCount == 1 then
		local planet = findPlayerPlanet(player)
		if planet then
			planet:SetAttribute("EvolutionTier", 1)
			planet:SetAttribute("EvolutionStage", "Archaea")
		end
	end

	fireUpdate(player, profile)          -- Matter went down
	fireConverterUpdate(player, profile) -- cell count went up
end

-- Passive Matter income: every ARCHAEA_PRODUCTION_INTERVAL seconds, each player
-- earns ARCHAEA_PRODUCTION_AMOUNT Matter per Archaea Cell they own. One shared
-- timer drives every player's production so it stays cheap as cells grow.
local function runProduction()
	task.spawn(function()
		while true do
			task.wait(GameConfig.ARCHAEA_PRODUCTION_INTERVAL)
			for _, player in Players:GetPlayers() do
				local profile = profiles[player.UserId]
				if profile and profile.archaeaCount > 0 then
					addMatter(player, profile.archaeaCount * GameConfig.ARCHAEA_PRODUCTION_AMOUNT)
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

	runCollection()
	runProduction()
end

return PlayerManager
