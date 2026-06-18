local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local GameConfig = require(ReplicatedStorage.GameConfig)
local Remotes = require(ReplicatedStorage.Remotes)

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

-- A random point within the spawn sphere, used when a collected mote respawns.
local function randomDustPosition()
	local dir = rng:NextUnitVector()
	local dist = rng:NextNumber(60, GameConfig.DUST_SPAWN_RADIUS)
	return dir * dist
end

-- Collect a mote for one player: award Matter, hide the mote, then bring it
-- back at a fresh random spot after DUST_RESPAWN_TIME.
local function collect(player, mote)
	if mote:GetAttribute("Collected") then return end
	mote:SetAttribute("Collected", true)
	mote.Transparency = 1
	local light = mote:FindFirstChildWhichIsA("PointLight")
	if light then light.Enabled = false end

	addMatter(player, 1)

	task.delay(GameConfig.DUST_RESPAWN_TIME, function()
		if not mote.Parent then return end
		local pos = randomDustPosition()
		mote.Position = pos
		mote:SetAttribute("BasePosition", pos)
		mote.Transparency = 0
		if light then light.Enabled = true end
		mote:SetAttribute("Collected", false)
	end)
end

-- Server-authoritative proximity collection. Distance checks (rather than
-- Touched events) reliably catch fast-moving fliers and tiny motes.
local function runCollection()
	RunService.Heartbeat:Connect(function()
		local motes = CollectionService:GetTagged(DUST_TAG)
		if #motes == 0 then return end

		for _, player in Players:GetPlayers() do
			if not profiles[player.UserId] then continue end
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if not hrp then continue end

			local pos = hrp.Position
			for _, mote in motes do
				if not mote:GetAttribute("Collected") then
					if (mote.Position - pos).Magnitude <= GameConfig.DUST_COLLECT_RADIUS then
						collect(player, mote)
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

	runCollection()
end

return PlayerManager
