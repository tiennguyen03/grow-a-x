# HANDOFF — Nova

Nova's active lane handoff. Fast-changing day-to-day notes. Global/integration
state lives in [`HANDOFF.md`](HANDOFF.md).

> Tien/Claude seeded this from what's known of Nova's work (PRs #7/#8/#9 + the Matter
> Core integration). Nova/Claude should keep it current while Nova works.

## Current Branch
`nova/epic3-reconciled` — the post-8C Epic 3 work (8D Cascade, 8E Biosphere View, the
microscope/organelle polish) reconciled on top of `origin/main`. → `main` via PR.
Sprint **1C (Multicellular Path + dynamic pricing)** and the **dev menu** sit on their own
branches (`nova/dynamic-pricing-1c`, `nova/dev-menu`), stacked on this one.

## Current Focus
**Epic 3 "From Archaea to Universe"** — 8C–8E shipped; **1C (Eukaryotic → Multicellular
Organism)** built on its branch. Next: tiers beyond Multicellular.

## Active Sprint / Ticket
- Epic 3: **8B** Archaea cells ✅, **8C** organelle path ✅ (in `main`), **8D** Eukaryotic
  Cascade + Dust Multiplier ✅, **8E** Biosphere View (Life Vessel + Microscope) ✅ — this
  branch → `main`. **1C** Multicellular Path + dynamic pricing ✅ on `nova/dynamic-pricing-1c`.
  All pending in-Studio playtest.

## Files I Am Touching
- `src/shared/OrganelleData.luau` — ordered organelle path (pure data; + `TOTAL_PRODUCTION_BONUS`).
- `src/client/CellInterventionUI.luau` — interactive cell/organelle UI in the inspect panel; now also shows Dust Value + (1C) the dynamic cell cost + the Multicellular Path section.
- `src/client/BiosphereView.client.luau` (NEW, 8E) — Life Vessel orb + Microscope `ViewportFrame` overlay + evolution/cascade celebration toasts. Toggle **M**/**Tab**.
- `src/server/PlayerManager.luau` — converter state + `CreateArchaea`/`PurchaseOrganelle`, 8D cascade + dust multiplier, (1C) dynamic cell cost + `PurchaseUpgrade`.
- **REMOVED:** `src/client/CellVisuals.client.luau` (orbiting planet cells → moved into Biosphere View) and `src/client/MatterConverterUI.luau` (C-key panel → obsolete). Their `Main.client` wiring is gone too.
- (1C, separate branch) NEW `src/shared/Pricing.luau`, `src/shared/MulticellularData.luau`.
- Shared (announce first): `src/shared/Remotes.luau` (added `CascadeTriggered`, 1C `PurchaseUpgrade`/`UpgradePurchased`), `src/shared/GameConfig.luau`, `src/client/Main.client.luau`.

## Files I Should Avoid
- Tien's inspect/traversal scripts: `PlanetInteraction.client.luau`, `PlanetStageVisuals.client.luau`, `PlanetMarker.client.luau`, `SpaceMovement.client.luau`.
- Don't reshape `PlanetInspectContext.luau` (shared seam) without coordinating with Tien.

## Recent Changes (this session, post-8C)
- **8D Eukaryotic Cascade + Dust Multiplier** — first Eukaryote evolves all cells at once + future cells born Eukaryotic; permanent dust multiplier `floor((tier+1)²/2)` (Tier 1 → ×2). New profile fields `cascadeTriggered`/`dustMultiplier`/`maxTierEvolved`; remote `CascadeTriggered`.
- **8E Biosphere View** — new `BiosphereView.client.luau`: Life Vessel orb (near camera, 1 speckle/cell) + Microscope `ViewportFrame` (population zoom progression; cells mirror real cells + draw only purchased organelles; cell divisions). Toggle **M**/**Tab**. Removed the orbiting planet cells (`CellVisuals`) and the C-key Matter Core panel (`MatterConverterUI`); celebration toasts moved into the vessel.
- **1C Multicellular Path + dynamic pricing** (branch `nova/dynamic-pricing-1c`) — dynamic cell cost `15·(1+0.08n+0.001n²)` + upgrade cost `base·(1+0.1·bought)`; six Eukaryotic→Multicellular upgrades (`MulticellularData`) with a UI section + per-upgrade visual layers in both biosphere views; remotes `PurchaseUpgrade`/`UpgradePurchased`.
- **Dev menu** (branch `nova/dev-menu`, ⚠️ remove before launch) — left-side GUI to grant Matter for testing (`DevGrantMatter`).

## How To Test My Work
1. Collect Matter, press **E** near your planet, **Create Cell** in the inspect panel (cost rises as you own more — 1C).
2. Buy organelles in order; on the first full Eukaryotic evolution the **Cascade** fires (all cells evolve, Dust Value → ×2).
3. Press **M** (or **Tab**) → the **Biosphere View**: Life Vessel orb + Microscope; create cells to watch the zoom progression + purchased organelles appear.
4. (1C) After Eukaryotic, the **Multicellular Path** section unlocks — buy the six upgrades and watch the microscope/vessel layer up.

## Open Questions / Blockers
- Persistence: cells reset on rejoin (waits on a DataStore epic).
- Tiers 2–9 + per-tier planet visuals not built yet (forward plan in `docs/EPICS/Epic3.md`).

## Next Safe Tasks
- Finish the upgrade-system doc, then implement the next evolution tier(s) on top of 8B.

## Notes For Tien
- **Epics were renumbered 7→2, 8→3** — my 8B section is now in `docs/EPICS/Epic3.md`.
- I consume `PlanetInspectContext.Changed` for the active planet name. If the seam's shape needs to change for tier upgrades, let's coordinate.
- Integration plan reference: [`docs/Plans/MatterCore-Inspect-Integration.md`](docs/Plans/MatterCore-Inspect-Integration.md).
