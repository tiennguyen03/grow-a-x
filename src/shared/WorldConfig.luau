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

-- Spawn composition (kept in sync with WorldBuilder + SpaceMovement)
WorldConfig.HOME_PLANET_POS = Vector3.new(0, 0, -180)
WorldConfig.RETURN_HOME_POS = Vector3.new(0, 20, -90)
WorldConfig.INSPECT_DISTANCE = 100

-- Seeding for the home planet. "UserId" later derives a per-player seed;
-- until then WorldBuilder uses FALLBACK_HOME_PLANET_SEED so both devs match.
WorldConfig.HOME_PLANET_SEED_MODE = "UserId"
WorldConfig.FALLBACK_HOME_PLANET_SEED = 20260618

-- Archetype pool the home/origin planet is allowed to roll. Must read as a
-- world that could develop life — no dead rocks, gas giants, or lava worlds.
WorldConfig.HOME_ARCHETYPE_POOL = { "Temperate", "Ocean", "YoungHabitable" }

return WorldConfig
