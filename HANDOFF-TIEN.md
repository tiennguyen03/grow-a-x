# HANDOFF — Tien

Tien's active lane handoff. Fast-changing day-to-day notes. Global/integration
state lives in [`HANDOFF.md`](HANDOFF.md).

## Current Branch
`tien/epic7-sentience-tendencies` (off `main`). Epic 4/5/6 are all in `main` now.

## Current Focus
**Epic 7 — Complex Life: Sentience Progress & Civilization Tendencies.** Built additively on the
Epic 5/6 `InterventionData` + `ApplyIntervention` pipeline: profile `sentienceProgress`/`tendencies`,
5 Sentience interventions gated to Complex Life (Multicellular complete / Life Progress 100), the
Tendency→Civilization-Identity foundation, and a Tool Use milestone at Sentience 100. New `SentienceUI`
mounts below Ecosystem in the inspect panel. Extends shared `PlayerManager`/`ConverterUpdate` (additive
— coordinate with Nova; confirm the Complex Life gate + `EvolutionStage="ToolUse"` don't fight his stages).
Optional Complex Life event deferred.

## Active Sprint / Ticket
- **Epic 5 5A** ✅ audit + **5B/5G** ✅ additive layer (`InterventionData` + `InterventionPreviewUI` + extension docs). Pending in-Studio playtest.
- **Ecosystem-Interventions UI clarity pass** ✅ — renamed preview section `Future Interventions` → **Ecosystem Interventions** + bridge copy; parent header → **Life Interventions**; cards now `category="Ecosystem"`. No live logic (`docs/Plans/Ecosystem-Interventions-UI-Clarity.md`). Also fixed the inspect-panel overflow (capped height + scroll).
- (Carryover) Epic 4 **4H** playtest sign-off.

## Recent Changes
- **Epic 7 reframed to V3 vision** (doc-level; `docs/EPICS/Epic7.md`). Renamed **Complex Life & Species Direction** (was "Sentience Progress & Civilization Tendencies"). Added: K-Rating band (~K0.45–K0.70, Tool Use @ K0.70), the **World Direction Tree** framing (the 5 interventions are now Cooperation/Curiosity/Adaptation/Competition/Problem-Solving *branches* with long-term paths), **World Overview + World Direction**-first UI priority (biology becomes secondary), **Starting Planet Influence** hooks, **Species Identity → Civilization Doctrine** bridge, **Cosmic Cycle compatibility**, and V3 DoD checks. Archived prior doc → `docs/PastEpics/Epic7.2026-06-20.md`; fix request → `docs/PastEpics/Epic7-V3-FixRequest.2026-06-20.md`. CLAUDE.md tracker updated.
- **Epic 7 7H shipped (UI-aligned to V3)**: inspect **"Sentience" tab → "World Direction"** (`PlanetInteraction`); `SentienceUI` header → "World Direction", subtitle/locked copy + identity label reframed to *species direction* / *Species Identity*. Added a **World Overview** block on the Overview tab — **K-Rating · Era · Next Milestone · Species Identity** surfaced *above* planet conditions, all **derived client-side** from existing attributes (`EvolutionStage`, `LifeProgress`/`LifeProgressMax`, `SentienceProgress`, `CivIdentity`) — **no server/`PlayerManager` change**. K-Rating is display-only (Complex Life K0.45→K0.70, Tool Use @ K0.70). Still-optional: profile placeholder hooks (`kRating`/`speciesIdentity`/`activeWorldDirectionFocus`) + `PlanetArchetypeModifiers` stub.
- **Inspect panel redesigned → tabbed layout** (`PlanetInteraction.client.luau`). Was one ~316px-wide right column with everything stacked behind a single long scroll (cramped, lots of scrolling). Now a wider 430px panel (height 84% of viewport) with a fixed header (planet name + tab row) over a page area: **Overview** (archetype/stage/life/civ/water/clouds/atmosphere), **Cells** (CellInterventionUI), **Ecosystem** (EcosystemInterventionUI), **Sentience** (SentienceUI). Each system mounts into its own tab page — only the active page shows, and it scrolls only if that one section overflows. Sub-UI `.mount(parent, {layoutOrder})` contract unchanged. Inspect-panel chrome (bg/stroke/gradient/corner + fade) preserved.
- Renamed the read-only future-intervention preview section to **Ecosystem Interventions**; added bridge copy explaining it shapes planet conditions around the cells.
- Parent intervention header → **Life Interventions** (reads: Life Interventions › Cell Cultures [Nova] › Ecosystem Interventions [preview]).
- Finalized the three card descriptions/effect summaries; `category = "Ecosystem"`. **No** remotes / `LifeProgress` / `Stability` / Matter spend added.
- Inspect panel now scrolls + caps height (was overflowing the screen).

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
