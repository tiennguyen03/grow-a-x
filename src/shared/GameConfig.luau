return {
	-- Dust collection (Matter is earned by flying through floating dust,
	-- not generated passively).
	DUST_PARTICLE_COUNT = 220,  -- how many dust motes float in the void (denser field)
	DUST_SPAWN_RADIUS   = 340,  -- studs; motes scatter within this sphere (tighter = denser)
	DUST_RESPAWN_TIME   = 4,    -- seconds before a collected mote returns

	-- Collection magnet: motes within DUST_MAGNET_RADIUS are pulled toward the
	-- player and collected once they reach DUST_COLLECT_RADIUS.
	DUST_MAGNET_RADIUS  = 42,   -- studs; motes within this range get pulled in (wider reach)
	DUST_COLLECT_RADIUS = 3,    -- studs; a mote is collected when it reaches here
	DUST_PULL_SPEED     = 48,   -- studs/sec; base speed a mote streaks toward the player
	DUST_PULL_FORCE     = 1.6,  -- extra pull acceleration as the mote nears the player
}
