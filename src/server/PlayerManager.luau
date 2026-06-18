local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.GameConfig)
local Remotes = require(ReplicatedStorage.Remotes)

local PlayerManager = {}

local profiles = {}

local function fireUpdate(player, profile)
	Remotes.MatterUpdate:FireClient(player, {
		matter = profile.matter,
		matterPerSec = profile.matterPerSec,
	})
end

local function createProfile(player)
	local profile = {
		matter = 0,
		matterPerSec = GameConfig.BASE_MATTER_PER_SEC,
	}
	profiles[player.UserId] = profile

	-- Push initial state immediately so the HUD shows "Matter: 0"
	-- right away instead of waiting for the first tick.
	fireUpdate(player, profile)
end

local function removeProfile(player)
	profiles[player.UserId] = nil
end

local function runTick()
	while true do
		task.wait(1)
		for userId, profile in profiles do
			profile.matter += profile.matterPerSec
			local player = Players:GetPlayerByUserId(userId)
			if player then
				fireUpdate(player, profile)
			end
		end
	end
end

function PlayerManager.init()
	Players.PlayerAdded:Connect(createProfile)
	Players.PlayerRemoving:Connect(removeProfile)

	for _, player in Players:GetPlayers() do
		createProfile(player)
	end

	task.spawn(runTick)
end

return PlayerManager
