# Handoff / Current State

**Last updated:** 2026-06-18 by Tien (+ Claude) — Epic 7 planet-generator foundation in `main`; the Matter rework (currency rename + dust-mote collection) is rebased on top. **Sprint 7H (on `tien/integration-matter-planets`):** star-system composition in `WorldConfig`, planets orbit the star, universe-wide dust (`DustField`), planet marker, return-home tracks the orbit.
**Active branches:** Tien → `feature/7a-planet-generator-foundation` · Nova → his own `nova/*` branch · current Matter work → `matter-dust-collection` (rebased on latest `main`, **not yet merged**) · all merge to `main` via PR.

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
| — | Footstep sound muted | ✅ Done (in `main`) |

**Still pending:** Nova's Epic 0 home-planet (0D-01) is **not** in `main` yet. The Matter rework (1A dust collection) lives on `matter-dust-collection`, rebased on latest `main` and awaiting an in-Studio retest before merge — coordinate so 7B/0D-01 planet work doesn't collide with the dust field in `WorldBuilder.luau`.

---

## File Map — what each file does & how risky it is to touch

| File | Purpose | Touch safety |
|---|---|---|
| `src/server/Main.server.luau` | Server entry point; calls each system's init/build | ⚠️ **Shared** — both of us edit this when adding a system. Coordinate / expect merge conflicts. Keep edits to single lines. |
| `src/server/WorldBuilder.luau` | Builds environment (gravity/lighting), star + star field, and the collectible dust motes | ✅ Safe — self-contained |
| `src/server/PlayerManager.luau` | Player profiles + server-side dust collection + fires `MatterUpdate` | ✅ Safe — owns the Matter server logic |
| `src/client/Main.client.luau` | Client entry point; inits client systems | ⚠️ **Shared** — same as server Main |
| `src/client/SpaceMovement.client.luau` | Floaty movement + soaring pose + banking | ✅ Safe — self-contained LocalScript |
| `src/client/DustAnimator.client.luau` | Bobs the dust motes locally (cosmetic) | ✅ Safe — self-contained LocalScript |
| `src/client/MatterUI.luau` | Builds HUD, listens to `MatterUpdate`, shows "+N" popup | ✅ Safe — owns the Matter UI |
| `src/shared/GameConfig.luau` | Shared tuning constants | ⚠️ **Shared** — append new keys, don't reorganize, to avoid conflicts |
| `src/shared/Remotes.luau` | Defines all RemoteEvents | ⚠️ **Shared** — add new remotes here; coordinate. **Gotcha:** the runtime folder is named `RemoteEvents` (NOT `Remotes`) so it doesn't collide with this ModuleScript's name — don't rename it back. |
| `src/shared/WorldConfig.luau` | World/home-planet constants (Epic 7) | ⚠️ **Shared** — used by WorldBuilder + future planet scripts; append, don't reorganize |
| `src/shared/PlanetArchetypes.luau` | Planet archetype defs + trait ranges (Epic 7) | ✅ Safe — owned by planet-generation work |
| `src/shared/PlanetGenerator.luau` | Pure deterministic descriptor + surface/biome generator (Epic 7) | ✅ Safe — pure data, no Instances; don't reorder its rng calls |
| `src/server/PlayerPlanetService.luau` | Builds one per-player planet on join; server-side **orbit around the star + own-axis spin** (Epic 7) | ✅ Safe — owns per-player planets; orbit/spin lives here (authoritative, no client motion) |
| `src/shared/DustField.luau` | Universe-wide dust spawn helper (`getSpawnPosition`) used by WorldBuilder + PlayerManager (Epic 7/1) | ✅ Safe — server-only helper; pure-ish (reads planet positions to avoid them) |
| `src/client/PlanetMarker.client.luau` | Screen-space marker pointing to the local player's orbiting planet (Epic 7) | ✅ Safe — self-contained LocalScript |

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
