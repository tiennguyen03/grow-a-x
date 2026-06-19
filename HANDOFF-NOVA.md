# HANDOFF — Nova

Nova's active lane handoff. Fast-changing day-to-day notes. Global/integration
state lives in [`HANDOFF.md`](HANDOFF.md).

> Tien/Claude seeded this from what's known of Nova's work (PRs #7/#8/#9 + the Matter
> Core integration). Nova/Claude should keep it current while Nova works.

## Current Branch
`matter-converter` (+ `mute-footsteps`, `planet-marker-render-order`) — all **folded into
PR #10** (`tien/integration-matter-planets`). After #10 merges to `main`, start the next
lane from a fresh `nova/<topic>` branch off `main`.

## Current Focus
**Matter Core / upgrade system** — writing the upgrade-system documentation, then building
beyond Sprint 8B (Archaea) toward the evolution tiers.

## Active Sprint / Ticket
- Epic 3 (formerly Epic 8) **"From Archaea to Universe"** — 8B shipped; upgrade-system spec/docs in progress.

## Files I Am Touching
- `src/client/MatterConverterUI.luau` — the **Matter Core** panel (now a read-only overview: balance/owned/production + inspected-planet context).
- `src/server/PlayerManager.luau` — converter state: `CreateArchaea` handler + passive production loop.
- Shared (announce first): `src/shared/Remotes.luau` (`CreateArchaea`/`ConverterUpdate`), `src/shared/GameConfig.luau` (`MATTER_CONVERTER_*`, `ARCHAEA_*`), `src/client/Main.client.luau` (UI init).

## Files I Should Avoid
- Tien's inspect/traversal scripts: `PlanetInteraction.client.luau`, `PlanetStageVisuals.client.luau`, `PlanetMarker.client.luau`, `SpaceMovement.client.luau`.
- Don't reshape `PlanetInspectContext.luau` (shared seam) without coordinating with Tien.

## Recent Changes
- **Sprint 8B Matter Converter** — spend Matter → Archaea Cell; server-authoritative cost/deduct/count; passive +1 Matter / 5s per cell.
- **Footstep-mute fix** — robust re-mute that holds against the engine re-un-muting.
- **Marker render order** — `DisplayOrder = -1` so the planet marker sits under the HUD.
- **Folded into the Matter Core integration:** the converter panel became the read-only "Matter Core" overview; **Create Life is now a planet intervention in Tien's inspect panel** (still fires your `CreateArchaea`); on first cell the server sets `EvolutionTier=1`/`EvolutionStage="Archaea"`.

## How To Test My Work
1. Collect ≥15 Matter.
2. **Create Life** from the inspect panel (press **E** near your planet) → Matter drops 15, Owned→1.
3. Wait 5s → Matter ticks +1 per cell. Button greys out when you can't afford it.
4. **C** opens the Matter Core overview (balance/owned/production + planet context).

## Open Questions / Blockers
- Persistence: cells reset on rejoin (waits on a DataStore epic).
- Tiers 2–9 + per-tier planet visuals not built yet (forward plan in `docs/EPICS/Epic3.md`).

## Next Safe Tasks
- Finish the upgrade-system doc, then implement the next evolution tier(s) on top of 8B.

## Notes For Tien
- **Epics were renumbered 7→2, 8→3** — my 8B section is now in `docs/EPICS/Epic3.md`.
- I consume `PlanetInspectContext.Changed` for the active planet name. If the seam's shape needs to change for tier upgrades, let's coordinate.
- Integration plan reference: [`docs/Plans/MatterCore-Inspect-Integration.md`](docs/Plans/MatterCore-Inspect-Integration.md).
