# Handoff / Current State

**Last updated:** 2026-06-19 by Nova (+ Claude) — **branch `nova/dev-menu`** (⚠️ **NOT in `main`** — its own branch) adds a **DEV/TESTING dev menu**: a small left-side pop-up GUI (`src/client/DevMenu.client.luau`) with buttons to grant the player Matter (+100 / +1K / +10K / +100K / +1M) so we don't have to replay every stage to test late-game. Server-authoritative via a new `DevGrantMatter` remote + a capped handler in `PlayerManager.init`. **Remove before launch** — delete `DevMenu.client.luau`, the `DevGrantMatter` remote in `Remotes.luau`, and the handler in `PlayerManager.init` (all marked "DEV/TESTING ONLY"). Separately, **branch `nova/dynamic-pricing-1c`** holds Sprint 1C (Multicellular Path + dynamic pricing) — also not in `main` yet. See the microscope note below.

**Before that (in `main`):** **branch `nova/microscope-organelles`** made the Microscope cells accurate to the upgrade path and tidier: each microscope cell now **mirrors a real cell** (by index) and shows **only the organelles that cell has purchased** — a fresh Archaea Cell is a bare blob, organelles appear as they're bought (each cell rebuilds in place, new parts fade in). The cell layout was **redone for neatness** — removed the protruding flagella tail + oversized membrane; everything now sits inside the body (membrane = thin surface rim, cytoplasm fills the body, ribosomes a golden-angle scatter, plasmids a tidy ring). Organelles still also hide past per-organelle **zoom ceilings** (ribo/plasmid ≤20, nucleoid/mito ≤50, nucleus ≤60, membrane/cytoplasm ≤200). All in `BiosphereView.client.luau`; no server change. Pending in-Studio playtest. See the zoom-progression note below.

**Before that:** **branch `nova/microscope-zoom`** (folded into local `main`) gave the Microscope View a **dynamic zoom progression**: the viewport camera pulls back as the population grows (TweenService-animated log curve, ~9→140 studs), the swim region grows sub-linearly so cells pack denser as you zoom out, visible-cell cap raised 50→**200**, and new cells **animate as divisions** (1:1 with real cells — no phantoms).

**Before that:** **branch `nova/trim-redundant-visuals`** (folded into local `main`) trimmed now-redundant cell UI in favor of the Biosphere View (8E): **(1)** deleted the C-key **Matter Core panel** (`MatterConverterUI.luau`) and its `Main.client` wiring (Dust Value still shows in the inspect panel); **(2)** deleted the **orbiting planet cells** (`CellVisuals.client.luau`) — those cells are now represented only in the Life Vessel + Microscope; its evolution/cascade **celebration toasts moved into `BiosphereView`**; **(3)** the Life Vessel + Microscope show **exactly the real cell count (capped), never inflated**.

**Before that:** **branch `nova/biosphere-view`** (folded into local `main`) added Epic 3 **Sprint 8E: Biosphere View** — one self-contained client script `src/client/BiosphereView.client.luau` with two togglable, data-sharing modes: a **Life Vessel** (glass orb floating near the camera; grows richer/glows/swirls with total cell count, heartbeat-pulses, tints to the dominant life form, bursts on create/evolve) and a **Microscope View** (a `ViewportFrame` "drop of water" overlay where cells swim with Brownian motion). Toggle with **M** (or **Tab**) — open/close zooms in/out from the vessel. Pure client visualization of `ConverterUpdate` data: **no server change, never touches planet visuals**. See Sprint 8D below.

**Before that:** **branch `nova/eukaryotic-cascade`** (folded into local `main`) added Epic 3 **Sprint 8D: Eukaryotic Cascade + Dust Multiplier**. The first time a player completes a Eukaryotic Cell, **all their other cells evolve to Eukaryotic at once** and every **future** cell is born Eukaryotic (one-time `CascadeTriggered` celebration: multi-cell green bursts + "Eukaryotic Evolution Cascade!" toast). The same moment unlocks a permanent **Dust Multiplier** — each dust mote is now worth `floor((tier+1)^2/2)` Matter (Tier 1 → ×2; shown as "Dust Value: ×N" in the Matter Core panel and the inspect summary). New server profile fields `cascadeTriggered` / `dustMultiplier` / `maxTierEvolved` (reset on rejoin — no DataStore yet). Also: the obsolete top-right **"Matter Core" banner button was removed** (panel still toggles with **C**). Pending in-Studio playtest. See the Sprint 8C note below.

**Before that:** Sprint 8C (**branch `nova/organelle-upgrades`**, also in local `main`) added the Epic 3 / Tier 1 **organelle upgrade path**: each Archaea Cell is upgraded organelle-by-organelle (Membrane → … → Nucleus) until it evolves into a **Eukaryotic Cell**; players own any number of cells, each with its own path; **all UI now lives in the planet inspect panel** (the Matter Core panel is obsolete). See the prior integration note below.

**Earlier:** **integration branch `tien/integration-matter-planets` combines both devs' work:** Tien's **Epic 4 Planet Interaction** (Sprints 4A–4G: approach prompt, inspect camera with player ride-along, info panel, Matter Converter seam, Archaea life-glow, marker/prompt coordination, own-planet-only) + Nova's **Sprint 8B Matter Converter** (spend Matter on Archaea Cells for passive income; on-screen "Create Life" button / **C**) + Nova's **footstep-mute fix**. Nice tie-in: Epic 4's `PlanetInspectContext` seam ("Open Matter Converter" button) is built to hand off to Nova's `MatterConverterUI`. Prior: Epic 7 planet-generator foundation + **Sprint 7H** star-system composition in `WorldConfig`, planets orbit the star, universe-wide dust (`DustField`), planet marker, return-home tracks the orbit.
**Active branches:** Tien → `tien/integration-matter-planets` (this combined branch) · Nova → `matter-converter` / `mute-footsteps` / `planet-marker-render-order` (PRs #7/#8/#9, now folded in here) · all merge to `main` via PR.

This is the "where are we right now" doc. Read this first, then `CLAUDE.md` for architecture and `docs/EPICS/` for detail.

---

## Current Branch & Recent Changes

The currency/earn loop was reworked on the active Matter branch (see "Active branches" above). It's **rebased onto the latest `main`** but **not merged yet** — the remote copy of the branch still holds the older pre-rebase commits, so syncing it will need a force-push (`git push --force-with-lease`).

What changed:
- **Renamed the currency to `Matter`** everywhere (code, UI label, docs). The remote is `MatterUpdate`, the HUD module is `MatterUI.luau`, and the constant prefix is `DUST_*`.
- **Replaced passive +1/sec generation with dust collection.** `WorldBuilder` spawns 80 glowing motes (tagged `DustParticle`); `PlayerManager` awards +1 by a server-side proximity check and respawns the mote after `DUST_RESPAWN_TIME`. `DustAnimator.client.luau` bobs them locally (no per-frame replication).
- **Fixes after the first playtest:**
  - HUD took ~10s to appear → the runtime remotes folder was named `Remotes`, colliding with the `Remotes` ModuleScript. Folder renamed to **`RemoteEvents`** (see gotcha in the File Map).
  - HUD now builds *before* resolving the remote, so `Matter: 0` shows instantly.
  - Motes were too small/dim/far to see → now bigger (1.8–2.6 studs), brighter (PointLight 5 / range 30), and spawn from 30 studs out.

⚠️ **Needs an in-Studio retest to confirm:** `Matter: 0` shows immediately, motes are visible, and flying through one awards +1 with a "+1" popup. Tuning knobs: `DUST_*` in `GameConfig.luau`, mote size/glow in `WorldBuilder.buildDust`, `BOB_AMPLITUDE` in `DustAnimator`.

---

## Getting Started (Nova — do this once)

```bash
git clone https://github.com/tiennguyen03/grow-a-x.git
cd grow-a-x
rokit install      # installs Rojo 7.4.4
rojo serve         # keep running; connect the Rojo Studio plugin to localhost:34872
```

> ✅ A blank baseplate place works fine — `WorldBuilder.luau` sets gravity, lighting, and removes the baseplate on Play. Just connect Rojo and hit **Play**.

---

## What's Done

| Sprint | What | Status |
|---|---|---|
| 1A | Matter collected by flying through dust motes; HUD + "+1" popup | ✅ Done (on `matter-dust-collection`) |
| 0A | Void environment + floaty 6-axis movement | ✅ Done (in `main`) |
| 0B | Centerpiece star + 200-star field (motion reference) | ✅ Done (in `main`) |
| 0C | Soaring flight pose + banking into turns | ✅ Done (in `main`) |
| 0D | Boost, look-based 3D flight, FOV, boost VFX, return-home | ✅ Done (in `main`) |
| 7A | Procedural planet **descriptor** foundation (data only) | ✅ Done (in `main`) |
| 4A–4G | Planet interaction: approach prompt, inspect camera (+ player ride-along), info panel, Matter Converter seam, life-stage glow, marker/prompt coordination, own-planet-only | 🔶 Integrated here; pending in-Studio playtest (4H) |
| 8B | Matter Converter — spend Matter on an Archaea Cell (passive Matter income); on-screen "Create Life" button + **C** | ✅ Integrated here (Nova, PR #7) |
| 8C | Organelle upgrade path — upgrade each Archaea Cell organelle-by-organelle into a Eukaryotic Cell; unlimited cells; per-cell planet visuals + evolution celebration; **all UI in the inspect panel** | 🔶 In local `main` (`nova/organelle-upgrades`); pending in-Studio playtest |
| 8D | Eukaryotic Cascade (first Eukaryote evolves all cells at once + future cells born Eukaryotic) + permanent Dust Multiplier (`floor((tier+1)^2/2)` Matter/mote, Tier 1 → ×2) | 🔶 In local `main` (`nova/eukaryotic-cascade`); pending in-Studio playtest |
| 8E | Biosphere View — Life Vessel orb (near camera, scales with cell count) + Microscope ViewportFrame overlay (Brownian cells); toggle **M**/**Tab**. Client-only, no server change | 🔶 In local `main` (`nova/biosphere-view`); pending in-Studio playtest |
| — | Footstep sound muted | ✅ Fixed — robust re-mute that holds against the engine re-un-muting (Nova, PR #8); integrated here |

**Still pending:** Nova's Epic 0 home-planet (0D-01) is **not** in `main` yet. The Matter rework (1A dust collection) lives on `matter-dust-collection`, rebased on latest `main` and awaiting an in-Studio retest before merge — coordinate so 7B/0D-01 planet work doesn't collide with the dust field in `WorldBuilder.luau`.

> **Matter Core ↔ Inspect integration — ✅ v0 done (2026-06-19), pending playtest.** Unified the two flows into one planet-contextual path: **Create Life** is now an Intervention in the inspect panel (the old "Open Matter Converter" button is gone); the global button is renamed **"Matter Core"** and its panel is a read-only overview that shows the inspected planet's name (consumes `PlanetInspectContext`). On first Create Life the server sets `EvolutionTier=1`/`EvolutionStage="Archaea"` so the glow + panel update fire automatically. Full plan + status: [`docs/Plans/MatterCore-Inspect-Integration.md`](docs/Plans/MatterCore-Inspect-Integration.md).

---

## File Map — what each file does & how risky it is to touch

| File | Purpose | Touch safety |
|---|---|---|
| `src/server/Main.server.luau` | Server entry point; calls each system's init/build | ⚠️ **Shared** — both of us edit this when adding a system. Coordinate / expect merge conflicts. Keep edits to single lines. |
| `src/server/WorldBuilder.luau` | Builds environment (gravity/lighting), star + star field, and the collectible dust motes | ✅ Safe — self-contained |
| `src/server/PlayerManager.luau` | Player profiles + server-side dust collection + fires `MatterUpdate` | ✅ Safe — owns the Matter server logic |
| `src/client/Main.client.luau` | Client entry point; inits client systems | ⚠️ **Shared** — same as server Main |
| `src/client/SpaceMovement.client.luau` | Floaty movement + soaring pose + banking. Also honors the `PlanetInspectLocked` player attribute (set by `PlanetInteraction`) — when set it carries the player along with the orbiting planet (rides the orbit, stays framed) and skips input (Epic 4 inspect mode) | ✅ Safe — self-contained LocalScript |
| `src/client/DustAnimator.client.luau` | Bobs the dust motes locally (cosmetic) | ✅ Safe — self-contained LocalScript |
| `src/client/MatterUI.luau` | Builds HUD, listens to `MatterUpdate`, shows "+N" popup | ✅ Safe — owns the Matter UI |
| `src/client/MatterConverterUI.luau` | **REMOVED** (was the C-key "Matter Core" panel). Deleted once the inspect panel + Biosphere View covered everything; its `Main.client` init was removed too. Dust Value lives in the inspect panel. | — gone |
| `src/shared/OrganelleData.luau` | Ordered Tier 1 organelle path (Archaea → Eukaryotic): id/name/cost/productionBonus/visual + helpers (`nextOrganelle`, `isComplete`, `indexOf`, `TOTAL_COST`=240). Pure data (Epic 3 / 8C) | ✅ Safe — pure data, owned by progression work |
| `src/client/CellInterventionUI.luau` | The interactive cell-list + per-cell organelle-detail UI (create cells, buy organelles in order, progress-to-Eukaryotic bar). **Mounted into the inspect panel** by `PlanetInteraction`; server-authoritative spends via `PurchaseOrganelle` (Epic 3 / 8C) | ✅ Safe — self-contained module (Nova) |
| `src/client/CellVisuals.client.luau` | **REMOVED** (was the cells orbiting the planet + evolution/cascade celebrations). Deleted — cells are now shown only in the Life Vessel + Microscope; the celebration toasts moved into `BiosphereView`. | — gone |
| `src/client/BiosphereView.client.luau` | Dual-mode biosphere visualization + evolution/cascade **celebration toasts**: Life Vessel orb (camera-relative; **one speckle per actual cell**, cap 120) + Microscope `ViewportFrame` overlay (Brownian cells; **exactly the real cell count**, cap 200) with a **TweenService zoom progression** (camera pulls back on a log curve as population grows); each microscope cell **mirrors a real cell and draws only its purchased organelles** (neatly laid out inside the body), hidden past per-organelle zoom ceilings; new cells animate as **divisions**. Toggle **M**/**Tab**. Derives data from `ConverterUpdate`; **no server change, never touches planet visuals**. Self-contained LocalScript, no Main wiring (Epic 3 / 8E) | ✅ Safe — self-contained LocalScript (Nova) |
| `src/server/PlayerManager.luau` (converter) | Also owns converter state: `CreateArchaea` handler + passive Archaea production loop (8B). On the first Archaea Cell it sets `EvolutionTier=1`/`EvolutionStage="Archaea"` on the player's planet (Matter Core integration) | ✅ Safe — same owner as Matter logic |
| `src/shared/GameConfig.luau` | Shared tuning constants | ⚠️ **Shared** — append new keys, don't reorganize, to avoid conflicts |
| `src/shared/Remotes.luau` | Defines all RemoteEvents | ⚠️ **Shared** — add new remotes here; coordinate. **Gotcha:** the runtime folder is named `RemoteEvents` (NOT `Remotes`) so it doesn't collide with this ModuleScript's name — don't rename it back. |
| `src/shared/WorldConfig.luau` | World/home-planet constants (Epic 7) | ⚠️ **Shared** — used by WorldBuilder + future planet scripts; append, don't reorganize |
| `src/shared/PlanetArchetypes.luau` | Planet archetype defs + trait ranges (Epic 7) | ✅ Safe — owned by planet-generation work |
| `src/shared/PlanetGenerator.luau` | Pure deterministic descriptor + surface/biome generator (Epic 7) | ✅ Safe — pure data, no Instances; don't reorder its rng calls |
| `src/server/PlayerPlanetService.luau` | Builds one per-player planet on join; server-side **orbit around the star + own-axis spin** (Epic 7). Exposes planet descriptor data as model attributes (incl. `CloudCoverage`, added for the Epic 4 inspect panel) | ✅ Safe — owns per-player planets; orbit/spin lives here (authoritative, no client motion) |
| `src/shared/DustField.luau` | Universe-wide dust spawn helper (`getSpawnPosition`) used by WorldBuilder + PlayerManager (Epic 7/1) | ✅ Safe — server-only helper; pure-ish (reads planet positions to avoid them) |
| `src/client/PlanetMarker.client.luau` | Screen-space marker pointing to the local player's orbiting planet (Epic 7). Hides while the Epic 4 approach prompt or inspect mode is active (reads `PlanetPromptVisible` / `InspectingPlanet` player attributes) | ✅ Safe — self-contained LocalScript |
| `src/client/PlanetInteraction.client.luau` | Approach prompt + inspect camera + info panel + **Intervention section** — `[E] Inspect <planet>`, E enters a scriptable inspect camera that tracks the orbit, shows the planet info panel; the old inline "Create Life" button was replaced by a `CellInterventionUI.mount(...)` so the **full organelle/cell-management UI lives here** (Epic 4 4A–4F + Epic 3 / 8C). E/Backspace exits | ⚠️ **Tien-owned file edited cross-lane (8C)** — Nova mounted the organelle UI here per the "do it all in the inspect panel" directive. Coordinate before further edits |
| `src/client/PlanetInspectContext.luau` | Client seam between Tien's inspect mode and Nova's Matter Converter — publishes the active planet context + `OpenRequested`/`Changed` signals (no economy logic) (Epic 4, Sprint 4D) | ⚠️ **Boundary with Nova** — Nova's Converter UI consumes this; coordinate before changing its shape |
| `src/client/PlanetStageVisuals.client.luau` | Early life-stage visual hook — adds a pulsing teal Archaea glow to the local planet when `EvolutionTier`≥1 / `EvolutionStage=="Archaea"` (Epic 4, Sprint 4E) | ✅ Safe — self-contained LocalScript |

**Rule of thumb:** the ✅ files are owned by one feature and safe to work in solo. The ⚠️ files are coordination points — tell each other before restructuring them.

---

## ✅ World is fully reproducible from source

Gravity, lighting, baseplate removal, and all visual objects are built by
`src/server/WorldBuilder.luau` on server start. There is **no manual Studio
setup** — clone, `rojo serve`, hit Play, and any place becomes the correct
space environment.

To tweak the look, edit the constants at the top of `WorldBuilder.luau`
(`GRAVITY`, `BRIGHTNESS`, `AMBIENT`, `OUTDOOR_AMBIENT`, star settings).
Don't change Lighting in Studio directly — it gets overwritten on the next Play.

---

## Suggested Next Tasks (pick non-overlapping lanes)

To stay out of each other's files:

- **Bread's lane (traversal/world feel):** Sprint 0 polish — flying animation, dash/boost, camera FOV kick. Files: `SpaceMovement.client.luau`, `WorldBuilder.luau`.
- **Open lane for Nova (Matter systems):** Sprint 1B — spend Matter on the first planet *intervention* (e.g. a richer dust field). Files: `PlayerManager.luau`, `MatterUI.luau`, plus one new remote in `Remotes.luau` and a constant in `GameConfig.luau`.

Both lanes only collide in the ⚠️ shared files (`Remotes`, `GameConfig`, the two `Main` files) — a quick "hey I'm adding X" message avoids any conflict.

See `docs/EPICS/` for the full sprint breakdowns and tuning constants.

---

## Branching — work on your own branch, never commit straight to `main`

We each work on a personal branch so two live Rojo sessions don't fight over the same history. `main` is the integration branch — it only changes via pull request.

- **Bread:** `bread/world-feel`
- **Nova:** create your own — `git checkout -b nova/<topic>` (e.g. `nova/matter-upgrades`), then `git push -u origin nova/<topic>`

> Git branches don't affect Rojo — each of you serves your own files from your own branch. Branching only separates the commit history.

### Daily workflow (on your own branch)

```bash
git checkout bread/world-feel   # make sure you're on YOUR branch, not main
# ...work...
git add <files>
git commit -m "..."
git push                        # goes to your branch
```

### Pull in the other person's merged work (do this periodically)

```bash
git fetch origin
git merge origin/main           # bring main's latest into your branch; keeps the eventual PR small
```

### Ship your work to `main`

Open a PR: `https://github.com/tiennguyen03/grow-a-x/pull/new/<your-branch>`.
The ⚠️ shared files (`Remotes`, `GameConfig`, the two `Main` files) are where conflicts show up — resolve those carefully when merging.

---

> 🛠️ **Maintenance:** update this file's "Last updated" line, the **What's Done** table, and the **File Map** whenever you finish a sprint or start working in a new file.
