local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.GameConfig)
local Remotes = require(ReplicatedStorage.Remotes)

local PlayerManager = {}

local profiles = {}

local function createProfile(player)
	profiles[player.UserId] = {
		influence = 0,
		influencePerSec = GameConfig.BASE_INFLUENCE_PER_SEC,
	}
end

local function removeProfile(player)
	profiles[player.UserId] = nil
end

local function runTick()
	while true do
		task.wait(1)
		for userId, profile in profiles do
			profile.influence += profile.influencePerSec
			local player = Players:GetPlayerByUserId(userId)
			if player then
				Remotes.InfluenceUpdate:FireClient(player, {
					influence = profile.influence,
					influencePerSec = profile.influencePerSec,
				})
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
