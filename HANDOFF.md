# HANDOFF — Global Project State

The stable, project-wide snapshot. Day-to-day active-lane notes live in the
per-developer handoffs so we're not both editing this file constantly.

## Read Order
1. Read this file first.
2. Read the **active developer's** lane handoff: [`HANDOFF-TIEN.md`](HANDOFF-TIEN.md) or [`HANDOFF-NOVA.md`](HANDOFF-NOVA.md).
3. Read the **other** developer's handoff only if the task touches shared files or their lane.
4. Read the relevant [`docs/EPICS/Epic<N>.md`](docs/EPICS/) for detail.

Then `CLAUDE.md` for architecture/rules.

---

## Current Integration State

**Already in `main`:** PR #10 (Epic 4 + Nova's #7/#8/#9 + Matter Core integration) and **PR #12 — Nova's Sprint 8C organelle upgrade path** (Archaea cells upgrade organelle-by-organelle into Eukaryotic cells; unlimited cells; the **whole intervention UI now lives in the inspect panel** via `CellInterventionUI`, making the old Matter Core panel obsolete).

**In flight (this branch → `main`):** the post-#10 commits that didn't make the #10 merge — **misc polish** (denser Matter 360/1050, planet orbit 340→**460**, **sun-death** at star radius + `SUN_KILL_MARGIN`) and the **handoff split** (this global file + `HANDOFF-TIEN.md`/`HANDOFF-NOVA.md` + the `CLAUDE.md` workflow). `origin/main` (incl. 8C) has been merged into this branch and reconciled (only `HANDOFF.md` needed manual union).

> After this lands, both devs branch off `main`. PRs #7/#8/#9 are superseded by #10 (close them).

---

## Active Lanes

| Developer | Current lane | Branch | Lane handoff |
|---|---|---|---|
| **Tien** | Epic 4 polish + handoff split → `main` (then 4H playtest) | `tien/integration-matter-planets` | [`HANDOFF-TIEN.md`](HANDOFF-TIEN.md) |
| **Nova** | Epic 3 organelle upgrades (8C shipped); next evolution tier | `nova/organelle-upgrades` (merged #12) | [`HANDOFF-NOVA.md`](HANDOFF-NOVA.md) |

---

## What Is Done (global)

| Sprint | What | Status |
|---|---|---|
| 0A–0D | Void environment, floaty 6-axis flight, soaring pose + banking, boost/FOV/VFX/return-home | ✅ in `main` |
| 0B | Centerpiece star + 200-star field | ✅ in `main` |
| 1A | Matter via dust motes; HUD + "+1" popup | ✅ (integrated) |
| 7A | Procedural planet **descriptor** foundation | ✅ in `main` |
| 7B–7H | Per-player procedural planets, noise continents, biomes, server orbit/spin, star-system composition, universe dust, planet marker | ✅ (in `main` / PR #10) |
| 4A–4G | Planet interaction (prompt, inspect camera, info panel, Converter seam, life-glow, coordination, own-planet-only) | ✅ in `main` (#10); 4H playtest pending |
| 8B | Matter Converter — Archaea Cell + passive income | ✅ in `main` (#10, Nova) |
| 8C | Organelle upgrade path — cells upgrade organelle-by-organelle into Eukaryotic cells; unlimited cells; per-cell planet visuals + evolution celebration; **all UI in the inspect panel** | ✅ in `main` (#12, Nova); playtest pending |
| 8D | Eukaryotic Cascade (first Eukaryote evolves all cells + future cells born Eukaryotic) + permanent Dust Multiplier (`floor((tier+1)²/2)` Matter/mote, Tier 1 → ×2) | 🔶 this branch → `main` (Nova); playtest pending |
| 8E | Biosphere View — Life Vessel orb + Microscope `ViewportFrame` overlay (zoom progression, purchase-gated organelles, cell divisions); toggle **M**/**Tab**. Replaced the orbiting planet cells (`CellVisuals`) + the C-key Matter Core panel (`MatterConverterUI`), both **removed** | 🔶 this branch → `main` (Nova); playtest pending |
| — | Footstep mute fix; marker render order | ✅ in `main` (#10, Nova) |
| — | Misc polish (denser Matter, planet farther from sun, sun-death) + handoff split | ✅ in `main` (#11) |
| 5A/5B | Epic 5 Matter Core: audit + additive intervention-definition format (`InterventionData`) + inspect-panel overflow fix | 🔶 on Tien branch; pending playtest |
| 6A–6F | Epic 6 Ecosystem Interventions: `lifeProgress`/`stability` profile + `ApplyIntervention` remote/handler (server-authoritative) + Life Progress/Stability bars + interactive Nourish/Stabilize/Accelerate cards. ⚠️ extends Nova's `ConverterUpdate` payload + profile (additive; coordinate with his unmerged 1C) | 🔶 `tien/epic6-ecosystem-interventions`; pending playtest |

---

## Current Global Blockers

- **In-Studio playtest sign-off pending** for the merged work (Epic 4 4H + 8C organelle flow + polish).
- The post-#10 polish + handoff-split (this branch) still needs to land on `main`.

---

## Shared Coordination Files (announce before restructuring)

`src/server/Main.server.luau` · `src/client/Main.client.luau` · `src/shared/Remotes.luau` ·
`src/shared/GameConfig.luau` · `src/shared/WorldConfig.luau` ·
`src/client/PlanetInspectContext.luau` (Tien↔Nova boundary — the inspect→converter seam).

> **Gotcha:** the runtime RemoteEvents folder is named **`RemoteEvents`** (NOT `Remotes`) so it doesn't collide with the `Remotes` ModuleScript — don't rename it back.

---

## File Map / Ownership Summary

| File | Purpose | Touch safety |
|---|---|---|
| `src/server/Main.server.luau` | Server entry point; inits systems | ⚠️ **Shared** — keep edits to single lines |
| `src/server/WorldBuilder.luau` | Environment (gravity/lighting), star + star field, dust motes | ✅ Safe — self-contained |
| `src/server/PlayerManager.luau` | Matter profiles + dust collection + `MatterUpdate`; **converter:** `CreateArchaea` + production (Nova); **ecosystem (Epic 6):** `lifeProgress`/`stability` profile fields + `onApplyIntervention` handler | ⚠️ **Shared lane** — Nova owns the cell economy; Epic 6 added ecosystem fields/handler additively, coordinate on merge |
| `src/server/PlayerPlanetService.luau` | Builds per-player planet on join; server-side **orbit + spin**; exposes descriptor attributes (incl. `CloudCoverage`) | ✅ Safe — owns per-player planets |
| `src/client/Main.client.luau` | Client entry point; inits client systems | ⚠️ **Shared** |
| `src/client/SpaceMovement.client.luau` | Floaty movement + pose + banking; honors `PlanetInspectLocked` (rides the orbit during inspect); **sun-death** kill check | ✅ Safe — self-contained (Tien) |
| `src/client/DustAnimator.client.luau` | Bobs dust motes locally (cosmetic) | ✅ Safe — self-contained |
| `src/client/MatterUI.luau` | HUD, listens to `MatterUpdate`, "+N" popup | ✅ Safe — Matter UI |
| `src/client/CellInterventionUI.luau` | Interactive cell-list + per-cell organelle-detail UI (create cells, buy organelles in order, progress-to-Eukaryotic bar). **Mounted into the inspect panel** by `PlanetInteraction`; server-authoritative via `PurchaseOrganelle` (Epic 3 / 8C) | ✅ Safe — self-contained (Nova) |
| `src/client/BiosphereView.client.luau` | Biosphere View — always-on Life Vessel orb (grows with cell count) + Microscope `ViewportFrame` overlay (toggle **M**/**Tab**), both driven by `ConverterUpdate`; evolution/cascade celebration toasts. Replaced `CellVisuals` + the C-key Matter Core panel (Epic 3 / 8E) | ✅ Safe — self-contained LocalScript (Nova) |
| `src/client/PlanetMarker.client.luau` | Screen marker to the local orbiting planet; hides during prompt/inspect (`PlanetPromptVisible`/`InspectingPlanet`) | ✅ Safe — self-contained (Tien) |
| `src/client/PlanetInteraction.client.luau` | Approach prompt + inspect camera + info panel; **mounts `CellInterventionUI`** so the full organelle/cell UI lives in the inspect panel (Epic 4 + 8C) | ⚠️ **Tien file, edited cross-lane by Nova (8C)** — coordinate before further edits |
| `src/client/PlanetInspectContext.luau` | Seam: publishes active planet context + `Changed`/`OpenRequested` (no economy logic) | ⚠️ **Tien↔Nova boundary** — coordinate before changing its shape |
| `src/client/PlanetStageVisuals.client.luau` | Archaea life-glow when `EvolutionTier≥1`/`EvolutionStage=="Archaea"` | ✅ Safe — self-contained (Tien) |
| `src/shared/OrganelleData.luau` | Ordered Tier-1 organelle path (Archaea → Eukaryotic): id/name/cost/bonus/visual + helpers (`TOTAL_COST`=240). Pure data (Epic 3 / 8C) | ✅ Safe — pure data (Nova) |
| `src/shared/InterventionData.luau` | Generic intervention definition format (id/cost/requirements/effects/state); `create_life` reference + the **live** Epic 6 `category="Ecosystem"` interventions. Read by both `onApplyIntervention` (server) and `EcosystemInterventionUI` (Epic 5/6) | ✅ Safe — pure data (Tien) |
| `src/client/EcosystemInterventionUI.luau` | Interactive Ecosystem Interventions: Life Progress + Stability bars + cards that fire `ApplyIntervention`; mounted in the inspect panel below Cell Cultures (Epic 6) | ✅ Safe — self-contained module (Tien) |
| `src/shared/GameConfig.luau` | Shared tuning constants (`DUST_*`, `MATTER_CONVERTER_*`, `ARCHAEA_*`) | ⚠️ **Shared** — append, don't reorganize |
| `src/shared/Remotes.luau` | All RemoteEvents (`MatterUpdate`, `CreateArchaea`, `ConverterUpdate`, `PurchaseOrganelle`, `CascadeTriggered`, `ApplyIntervention`) | ⚠️ **Shared** — add remotes here |
| `src/shared/WorldConfig.luau` | World/star/orbit constants + `SUN_KILL_MARGIN` | ⚠️ **Shared** — append, don't reorganize |
| `src/shared/PlanetArchetypes.luau` | Archetype defs + trait ranges | ✅ Safe — planet-gen |
| `src/shared/PlanetGenerator.luau` | Pure deterministic descriptor + surface/biome generator | ✅ Safe — don't reorder its rng calls |
| `src/shared/DustField.luau` | Universe-wide dust spawn helper (`getSpawnPosition`) | ✅ Safe — server-only helper |

**Rule of thumb:** ✅ files are owned by one feature and safe solo; ⚠️ files are coordination points.

---

## Merge / PR Notes

- **PR #10** is the live integration branch → `main`. Merge it first; then Nova rebases onto the new base (note: epics were renumbered **7→2, 8→3**, so his 8B docs now live in `Epic3.md`).
- Documentation is **unioned, never overwritten** on merge (see CLAUDE.md "Documentation Preservation on Merge").

---

## Getting Started (once)

```bash
git clone https://github.com/tiennguyen03/grow-a-x.git
cd grow-a-x
rokit install      # installs Rojo 7.4.4
rojo serve         # keep running; connect the Rojo Studio plugin (localhost:34872)
```

> ✅ A blank baseplate place works — `WorldBuilder.luau` builds gravity/lighting/objects on Play. Connect Rojo (in **Edit** mode first), then hit **Play**.

**World is fully reproducible from source:** gravity, lighting, baseplate removal, and visuals are built by `WorldBuilder.luau` on server start — no manual Studio setup. Tune via the constants at the top of `WorldBuilder.luau`; don't change Lighting in Studio (it's overwritten on Play).

---

## Branching — never commit straight to `main`

Each dev works on a personal branch; `main` changes only via PR.

- **Tien:** `tien/<topic>` · **Nova:** `nova/<topic>`

```bash
git checkout <your-branch>   # confirm you're on YOUR branch
# ...work...
git add <files> && git commit -m "..." && git push
git fetch origin && git merge origin/main   # pull in merged work periodically
```

Ship via PR. The ⚠️ shared files are where conflicts show up — resolve carefully (union docs).

---

## Maintenance Rules

- **Update `HANDOFF.md` only when global/integration state changes:** a branch merges, a sprint completes, a new system/file is added, ownership changes, a global blocker appears, or integration state moves.
- **Day-to-day active work goes in the per-dev file** (`HANDOFF-TIEN.md` / `HANDOFF-NOVA.md`): current branch, focus, files being touched, recent changes, blockers, next steps.
- Don't edit the other dev's lane handoff unless explicitly asked or it's a coordination/merge task.
