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

local function createProfile(player)
	local profile = { matter = 0 }
	profiles[player.UserId] = profile

	-- Push initial state immediately so the HUD shows "Matter: 0" right away.
	fireUpdate(player, profile)
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

function PlayerManager.init()
	Players.PlayerAdded:Connect(createProfile)
	Players.PlayerRemoving:Connect(removeProfile)

	for _, player in Players:GetPlayers() do
		createProfile(player)
	end

	runCollection()
end

return PlayerManager
