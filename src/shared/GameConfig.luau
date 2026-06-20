return {
	-- Dust collection (Matter is earned by flying through floating dust,
	-- not generated passively). Dust is spread across a large UNIVERSE FIELD
	-- centered on the star system (see DustField.luau), not clustered on a planet.
	DUST_PARTICLE_COUNT = 360,  -- how many dust motes fill the void (raised from 200 — denser, easier to find)
	DUST_FIELD_RADIUS   = 1050, -- studs; radius of the spherical field (tightened from 1200 to concentrate dust near the play space)
	DUST_RESPAWN_TIME   = 4,    -- seconds before a collected mote returns

	-- Spawn keep-out distances so dust never lands inside the star/planets/spawn.
	DUST_MIN_DISTANCE_FROM_STAR_SURFACE = 80, -- added to star radius
	DUST_MIN_DISTANCE_FROM_PLANET       = 80, -- added to each planet's radius
	DUST_MIN_DISTANCE_FROM_SPAWN        = 60, -- keep the immediate spawn clear

	-- Collection magnet: motes within DUST_MAGNET_RADIUS are pulled toward the
	-- player and collected once they reach DUST_COLLECT_RADIUS.
	DUST_MAGNET_RADIUS  = 42,   -- studs; motes within this range get pulled in (wider reach)
	DUST_COLLECT_RADIUS = 3,    -- studs; a mote is collected when it reaches here
	DUST_PULL_SPEED     = 48,   -- studs/sec; base speed a mote streaks toward the player
	DUST_PULL_FORCE     = 1.6,  -- extra pull acceleration as the mote nears the player

	-- Matter Converter (Epic 8, Sprint 8B): spend collected Matter to create
	-- life forms that then produce Matter passively. The first life form is the
	-- Archaea Cell. Server is authoritative over cost, counts, and production.
	MATTER_CONVERTER_COST_ARCHAEA = 15, -- Matter to create one Archaea Cell
	ARCHAEA_PRODUCTION_INTERVAL   = 5,  -- (legacy display) seconds the inspect "Create Life" text references
	ARCHAEA_PRODUCTION_AMOUNT     = 1,  -- (legacy display) Matter a base cell makes over that interval (= 0.2/sec)

	-- Organelle upgrade path (Epic 3, Tier 1 — Archaea → Eukaryotic). Each player
	-- owns any number of cells; each cell upgrades its organelles individually (see
	-- OrganelleData.luau for the ordered path, costs, and per-organelle bonuses).
	-- Production is now PER SECOND and summed across every cell a player owns.
	PRODUCTION_TICK_INTERVAL = 1,   -- seconds between passive production ticks (per-second rates)
	ARCHAEA_BASE_PRODUCTION  = 0.2, -- Matter/sec a fresh, organelle-less Archaea Cell makes (= legacy 1 per 5s)
	-- A fully evolved cell makes ARCHAEA_BASE_PRODUCTION + 3.5 (sum of all organelle
	-- bonuses) ≈ 3.7 Matter/sec; the Nucleus is the big late jump that completes it.
}
