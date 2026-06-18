# Handoff / Current State

**Last updated:** 2026-06-18 by Bread (+ Claude)
**Active branches:** Bread → `bread/world-feel` · Nova → his own `nova/*` branch · both merge to `main` via PR.

This is the "where are we right now" doc. Read this first, then `CLAUDE.md` for architecture and `docs/EPICS/` for detail.

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
| 1A | Influence generates +1/sec, shown on a HUD | ✅ Done |
| 0A | Void environment + floaty 6-axis movement | ✅ Done |
| 0B | Centerpiece star + 200-star field (motion reference) | ✅ Done |
| 0C | Soaring flight pose + banking into turns | ✅ Done |
| — | Footstep sound muted | ✅ Done |

Nothing is mid-edit. All files below are committed and stable — safe to build on.

---

## File Map — what each file does & how risky it is to touch

| File | Purpose | Touch safety |
|---|---|---|
| `src/server/Main.server.luau` | Server entry point; calls each system's init/build | ⚠️ **Shared** — both of us edit this when adding a system. Coordinate / expect merge conflicts. Keep edits to single lines. |
| `src/server/WorldBuilder.luau` | Builds centerpiece star + star field from script | ✅ Safe — self-contained |
| `src/server/PlayerManager.luau` | Player profiles + influence tick + fires `InfluenceUpdate` | ✅ Safe — owns the Influence server logic |
| `src/client/Main.client.luau` | Client entry point; inits client systems | ⚠️ **Shared** — same as server Main |
| `src/client/SpaceMovement.client.luau` | Floaty movement + soaring pose + banking | ✅ Safe — self-contained LocalScript |
| `src/client/InfluenceUI.luau` | Builds HUD, listens to `InfluenceUpdate` | ✅ Safe — owns the Influence UI |
| `src/shared/GameConfig.luau` | Shared tuning constants | ⚠️ **Shared** — append new keys, don't reorganize, to avoid conflicts |
| `src/shared/Remotes.luau` | Defines all RemoteEvents | ⚠️ **Shared** — add new remotes here; coordinate |

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
- **Open lane for Nova (Influence systems):** Sprint 1B — spend Influence to buy an upgrade that raises `influencePerSec`. Files: `PlayerManager.luau`, `InfluenceUI.luau`, plus one new remote in `Remotes.luau` and one constant in `GameConfig.luau`.

Both lanes only collide in the ⚠️ shared files (`Remotes`, `GameConfig`, the two `Main` files) — a quick "hey I'm adding X" message avoids any conflict.

See `docs/EPICS/` for the full sprint breakdowns and tuning constants.

---

## Branching — work on your own branch, never commit straight to `main`

We each work on a personal branch so two live Rojo sessions don't fight over the same history. `main` is the integration branch — it only changes via pull request.

- **Bread:** `bread/world-feel`
- **Nova:** create your own — `git checkout -b nova/<topic>` (e.g. `nova/influence-upgrades`), then `git push -u origin nova/<topic>`

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
