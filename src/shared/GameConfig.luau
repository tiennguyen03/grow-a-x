return {
	-- Dust collection (Matter is earned by flying through floating dust,
	-- not generated passively).
	DUST_PARTICLE_COUNT = 80,   -- how many dust motes float in the void
	DUST_SPAWN_RADIUS   = 400,  -- studs; motes scatter within this sphere
	DUST_RESPAWN_TIME   = 4,    -- seconds before a collected mote returns

	-- Collection magnet: motes within DUST_MAGNET_RADIUS are pulled toward the
	-- player and collected once they reach DUST_COLLECT_RADIUS.
	DUST_MAGNET_RADIUS  = 20,   -- studs; motes within this range get pulled in
	DUST_COLLECT_RADIUS = 3,    -- studs; a mote is collected when it reaches here
	DUST_PULL_SPEED     = 12,   -- studs/sec; base speed a mote moves toward the player
	DUST_PULL_FORCE     = 0.8,  -- extra pull acceleration as the mote nears the player
}
