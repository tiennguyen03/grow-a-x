# HANDOFF — Tien

Tien's active lane handoff. Fast-changing day-to-day notes. Global/integration
state lives in [`HANDOFF.md`](HANDOFF.md).

## Current Branch
`tien/epic5-matter-core` (off `main`). Epic 4 + the Matter Core integration + polish all merged to
`main` (#10/#11). Now on **Epic 5 — Planet Upgrade System / Matter Core**.

## Current Focus
**Epic 5.** 5A audit found the MVP is ~80% already built by Nova's Epic 3 (server-authoritative
Create Life + organelles + inspect UI). Executing it **additively** (per the chosen scope): a
generic intervention-definition format + read-only "Coming Soon" preview cards, **without** touching
Nova's organelle code. Live generic purchase pipeline (5C–5F) deferred to coordinate with Nova / Epic 6.

## Active Sprint / Ticket
- **Epic 5 5A** ✅ audit + **5B/5G** ✅ additive layer (`InterventionData` + `InterventionPreviewUI` + extension docs). Pending in-Studio playtest.
- (Carryover) Epic 4 **4H** playtest sign-off.

## Files I Am Touching
- `src/client/PlanetInteraction.client.luau` (prompt + inspect camera + info panel + Create Life intervention)
- `src/client/PlanetInspectContext.luau` (⚠️ seam shared with Nova)
- `src/client/PlanetStageVisuals.client.luau` (Archaea glow)
- `src/client/PlanetMarker.client.luau`, `src/client/SpaceMovement.client.luau` (traversal + sun-death + inspect lock)
- `src/server/PlayerPlanetService.luau` (planet build/orbit; `CloudCoverage` attr)
- Shared (light touches): `WorldConfig.luau` (orbit/star/`SUN_KILL_MARGIN`), `GameConfig.luau` (`DUST_*`)

## Files I Should Avoid
- Nova's economy internals: `MatterConverterUI.luau` panel logic, `PlayerManager` converter/cost/production, `Remotes`/`GameConfig` converter keys — coordinate before touching.
- Don't reshape `PlanetInspectContext`'s payload/signals without telling Nova (he consumes it).

## Recent Changes
- **Epic 4 4A–4G** built: approach prompt (keycap pill), inspect camera (player rides along with the orbit), info panel from model attributes, Archaea glow hook, marker/prompt no-overlap, own-planet-only.
- **Matter Core integration (v0):** Create Life moved into the inspect panel (fires `CreateArchaea`); server sets `EvolutionTier=1`/`EvolutionStage="Archaea"` on first cell.
- **Polish:** denser Matter (`DUST_PARTICLE_COUNT` 360, `DUST_FIELD_RADIUS` 1050); planet farther from sun (`PLANET_ORBIT_BASE_RADIUS` 460); **sun-death** (kill within star radius + `SUN_KILL_MARGIN` 15 = 215 studs).
- **Terrain-variation experiment reverted** — original clean tiled surface kept.

## How To Test My Work
1. Fly from spawn → dust is dense/easy to find.
2. Approach planet → `[E] Inspect` pill → **E** → camera frames the orbiting planet; you ride along (no drift). WASD doesn't fly you off.
3. Info panel shows real archetype/water/clouds/atmosphere. **Create Life** (≥15 Matter) → Matter drops, Owned→1, Stage→Archaea/Microbial, teal glow appears.
4. **C** → "Matter Core" overview shows balance/owned/production + planet name (no create button there).
5. **R** return-home and the **planet marker** still work. Dive into the sun → die/respawn.

## Open Questions / Blockers
- PR #10 needs a playtest sign-off before merge.
- Camera framing multipliers (`CAMERA_DIST_MULT`/`HEIGHT_MULT`/`SMOOTH` in `PlanetInteraction`) may want a taste tweak after playtest.

## Next Safe Tasks
- Epic 4 Sprint 4H final regression + 2-player check.
- Post-merge: tune sun-death/orbit/dust values if playtest suggests.

## Notes For Nova
- **Epics renumbered 7→2, 8→3.** Your Sprint 8B docs now live in `docs/EPICS/Epic3.md`; target that going forward.
- Your **Matter Converter UI** is reused as the "Matter Core" overview; **Create Life now lives in the inspect panel**. Consume `PlanetInspectContext` (`Changed` for the active planet name; `OpenRequested` is vestigial). Don't reshape the seam without a heads-up.
- The Matter Core unification plan: [`docs/Plans/MatterCore-Inspect-Integration.md`](docs/Plans/MatterCore-Inspect-Integration.md).
