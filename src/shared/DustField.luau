-- Universe-wide dust spawn helper (Epic 1 + Epic 7 composition).
--
-- Returns positions spread across a large spherical field centered on the star
-- system, so Matter is found throughout the void rather than clustered on a
-- planet. Used by BOTH initial placement (WorldBuilder.buildDust) and respawn
-- (PlayerManager.collect), so the distribution rules live in exactly one place.
--
-- Server-only: it reads live planet models from workspace to avoid spawning dust
-- inside them. It is a ReplicatedStorage ModuleScript only so both server scripts
-- can require it; do not call it from the client.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldConfig = require(ReplicatedStorage.WorldConfig)
local GameConfig = require(ReplicatedStorage.GameConfig)

local DustField = {}

-- Center the field between spawn and the star so dust surrounds the whole area
-- the player actually traverses (not just the star's far side).
local FIELD_CENTER = (WorldConfig.PLAYER_START_POS + WorldConfig.CENTERPIECE_STAR_POS) * 0.5

local MAX_TRIES = 24 -- rejection-sampling cap before we fall back

-- Reject positions that land inside (or hugging) any live player planet.
local function tooCloseToPlanet(pos)
	local env = workspace:FindFirstChild("SpaceEnvironment")
	local planets = env and env:FindFirstChild("PlayerPlanets")
	if not planets then
		return false
	end
	for _, model in planets:GetChildren() do
		local body = model.PrimaryPart or model:FindFirstChild("PlanetBody")
		if body then
			local radius = model:GetAttribute("Radius") or 40
			if (pos - body.Position).Magnitude < radius + GameConfig.DUST_MIN_DISTANCE_FROM_PLANET then
				return true
			end
		end
	end
	return false
end

-- A single valid dust position in the universe field. `rng` is a Random so both
-- initial placement (fixed seed) and respawn (live seed) can drive it.
function DustField.getSpawnPosition(rng)
	local starPos = WorldConfig.CENTERPIECE_STAR_POS
	local minFromStar = WorldConfig.CENTERPIECE_STAR_RADIUS + GameConfig.DUST_MIN_DISTANCE_FROM_STAR_SURFACE
	local spawnPos = WorldConfig.PLAYER_START_POS

	for _ = 1, MAX_TRIES do
		-- Uniform within the sphere volume: cube-root keeps it from clumping at center.
		local dir = rng:NextUnitVector()
		local dist = GameConfig.DUST_FIELD_RADIUS * (rng:NextNumber() ^ (1 / 3))
		local pos = FIELD_CENTER + dir * dist

		if (pos - starPos).Magnitude >= minFromStar
			and (pos - spawnPos).Magnitude >= GameConfig.DUST_MIN_DISTANCE_FROM_SPAWN
			and not tooCloseToPlanet(pos)
		then
			return pos
		end
	end

	-- Fallback: a point safely outside the star if sampling kept failing.
	return starPos + rng:NextUnitVector() * (minFromStar + 50)
end

return DustField
