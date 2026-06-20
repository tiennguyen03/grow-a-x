-- World-level constants shared across traversal, world building, and (later)
-- planet interaction. Pure data — no services, no side effects.
--
-- Part of Epic 7: Procedural Planet Generation (Sprint 7A).

local WorldConfig = {}

-- Global salt mixed into per-world seeds so a given UserId maps to a stable
-- but project-specific planet. (Same salt both devs see identical worlds.)
WorldConfig.WORLD_SEED_SALT = 20260618

-- Home / starting planet identity
WorldConfig.HOME_PLANET_ID = "home"
WorldConfig.HOME_PLANET_NAME = "HomePlanet"          -- internal instance name
WorldConfig.HOME_PLANET_DISPLAY_NAME = "Origin World" -- player-facing name

-- ---------------------------------------------------------------------------
-- Star system composition — the single source of truth for scene geometry.
-- WorldBuilder builds the star here, PlayerPlanetService orbits planets around
-- it, and DustField centers the dust on the system. Tune these to reshape the
-- whole composition; nothing else hardcodes these positions.
-- ---------------------------------------------------------------------------

WorldConfig.PLAYER_START_POS = Vector3.new(0, 0, 0) -- where players spawn

-- Centerpiece star: big, dominant anchor sitting straight ahead on the scene
-- axis so the system reads as centered from spawn.
WorldConfig.CENTERPIECE_STAR_POS    = Vector3.new(0, 0, -900)
WorldConfig.CENTERPIECE_STAR_RADIUS = 200 -- dominant; ~1.7x the previous 116

-- Sun death: flying within (star radius + this margin) of the star center kills
-- the player. Normal flight never gets this close (spawn is ~900 studs out and
-- planets orbit hundreds of studs from the star), so it only triggers on a real
-- dive into the star. Bump this to make the danger zone bigger.
WorldConfig.SUN_KILL_MARGIN = 15 -- studs beyond the star surface (kill radius = 215)

-- Player-planet orbit (deterministic VISUAL orbit, not physics). Orbit radius is
-- small vs. the star distance, so a planet always reads as "near the star,
-- offset" from spawn regardless of its starting angle. Per-player variation in
-- angle/radius/height keeps multiple players' planets from stacking.
WorldConfig.PLANET_ORBIT_BASE_RADIUS      = 460 -- studs from the star center (raised from 340 so the planet isn't cramped against the sun)
WorldConfig.PLANET_ORBIT_RADIUS_VARIATION = 70  -- +/- spread so orbits differ
WorldConfig.PLANET_ORBIT_HEIGHT_VARIATION = 40  -- +/- vertical spread
WorldConfig.PLANET_ORBIT_PERIOD_SECONDS   = 900 -- one lap ~15 min (slow/celestial)

-- Return-home: drop the player just outside their planet, on the far side from
-- the star, so R always lands them looking back at the system.
WorldConfig.RETURN_HOME_CLEARANCE = 90  -- studs beyond the planet surface
WorldConfig.RETURN_HOME_FALLBACK  = Vector3.new(0, 20, -150) -- if planet missing
WorldConfig.INSPECT_DISTANCE      = 100

-- Seeding for the home planet. "UserId" later derives a per-player seed;
-- until then WorldBuilder uses FALLBACK_HOME_PLANET_SEED so both devs match.
WorldConfig.HOME_PLANET_SEED_MODE = "UserId"
WorldConfig.FALLBACK_HOME_PLANET_SEED = 20260618

-- Archetype pool the home/origin planet is allowed to roll. Must read as a
-- world that could develop life — no dead rocks, gas giants, or lava worlds.
WorldConfig.HOME_ARCHETYPE_POOL = { "Temperate", "Ocean", "YoungHabitable" }

return WorldConfig
