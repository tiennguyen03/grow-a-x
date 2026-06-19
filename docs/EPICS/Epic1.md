# Epic 1: Core Matter Loop

The foundation of the game. Establishes that players earn **Matter** by flying
through glowing dust motes scattered across the void, and can see their total on
screen. No upgrades, no saving, no planet visuals — just the raw earn loop.

---

## Sprints

### Sprint 1A: Matter Collection ✅ COMPLETE

**Goal:** Player joins → server creates a profile → HUD shows `Matter: 0`
instantly → flying through a dust mote awards +1 Matter, the mote respawns
elsewhere, and a "+1" popup confirms the pickup.

**Scope (intentionally minimal):**
- [x] Server creates player profile on `PlayerAdded` (`matter = 0`)
- [x] Server fires `MatterUpdate` on join so the HUD shows `Matter: 0` instantly (no blank state)
- [x] `WorldBuilder` spawns a field of glowing dust motes, tagged `DustParticle`
- [x] Server detects collection by proximity and awards +1 Matter, then respawns the mote
- [x] Client HUD shows current Matter and a floating "+1" popup on pickup
- [x] Dust motes bob gently (client-side, so 80 motes cost no extra replication)
- [ ] No upgrades
- [ ] No planet visuals
- [ ] No saving
- [ ] No events

**Files:**
- `src/shared/GameConfig.luau` — `DUST_PARTICLE_COUNT`, `DUST_SPAWN_RADIUS`, `DUST_RESPAWN_TIME`, `DUST_COLLECT_RADIUS`
- `src/shared/Remotes.luau` — defines `MatterUpdate` RemoteEvent
- `src/server/WorldBuilder.luau` — spawns the tagged dust field (alongside the environment + stars)
- `src/server/PlayerManager.luau` — profiles, server-side proximity collection, respawn, fires remote
- `src/server/Main.server.luau` — calls `WorldBuilder.build()` and `PlayerManager.init()`
- `src/client/MatterUI.luau` — dark HUD panel, `Matter: N` label, floating "+N" popup
- `src/client/DustAnimator.client.luau` — bobs the dust motes locally
- `src/client/Main.client.luau` — inits the HUD module

**Constants (in `GameConfig.luau`):**
- `DUST_PARTICLE_COUNT = 80`
- `DUST_SPAWN_RADIUS = 400`
- `DUST_RESPAWN_TIME = 4`
- `DUST_COLLECT_RADIUS = 4`

> **Update (Epic 7 Sprint 7H):** dust is now a **universe field**, not a sphere around spawn. Placement moved into a shared `src/shared/DustField.luau` helper (`getSpawnPosition(rng)`) used by both `WorldBuilder` (initial) and `PlayerManager` (respawn); it spreads motes across `DUST_FIELD_RADIUS` (1200) centered between spawn and the star, rejecting spots inside the star/planets/spawn. `DUST_SPAWN_RADIUS` is replaced by `DUST_FIELD_RADIUS` + `DUST_MIN_DISTANCE_FROM_STAR_SURFACE/PLANET/SPAWN`; count raised to 200, and the magnet is stronger (`DUST_PULL_SPEED 48`, `DUST_MAGNET_RADIUS 42`).
>
> **Polish pass (2026-06-19):** Matter felt too sparse — bumped `DUST_PARTICLE_COUNT` 200→**360** and tightened `DUST_FIELD_RADIUS` 1200→**1050** for higher density near the play space. Tuning-only; no economy change.

> **Design note:** collection is server-authoritative (a distance check, not a
> Touched event) so fast fliers don't tunnel past tiny motes. The visual bob is
> client-only; the server keeps each mote at its `BasePosition` for collection
> and respawn.

---

### Sprint 1B: First Intervention — spend Matter (NOT STARTED)

Planned scope:
- Player can spend Matter on a framed planet *intervention* (not a generic upgrade)
- First intervention: costs Matter, produces a visible effect (e.g. a richer/denser dust field)
- UI shows the action with its cost
- No DataStore yet — resets on rejoin

---

### Sprint 1C: DataStore Save/Load (NOT STARTED)

Planned scope:
- Save `matter` per player to DataStore
- Load on join, save on leave and periodically
- Handle DataStore failures gracefully (don't wipe data on error)
