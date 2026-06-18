# Handoff / Current State

**Last updated:** 2026-06-18 by Bread (+ Claude)
**Branch:** `main` — clean, everything committed and pushed.

This is the "where are we right now" doc. Read this first, then `CLAUDE.md` for architecture and `docs/EPICS/` for detail.

---

## Getting Started (Nova — do this once)

```bash
git clone https://github.com/tiennguyen03/grow-a-x.git
cd grow-a-x
rokit install      # installs Rojo 7.4.4
rojo serve         # keep running; connect the Rojo Studio plugin to localhost:34872
```

> ⚠️ **Read the "Place-level settings" warning below before you playtest** — a fresh place will look wrong until those are applied.

---

## What's Done

| Sprint | What | Status |
|---|---|---|
| 1A | Matter generates +1/sec, shown on a HUD | ✅ Done |
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
| `src/server/PlayerManager.luau` | Player profiles + matter tick + fires `MatterUpdate` | ✅ Safe — owns the Matter server logic |
| `src/client/Main.client.luau` | Client entry point; inits client systems | ⚠️ **Shared** — same as server Main |
| `src/client/SpaceMovement.client.luau` | Floaty movement + soaring pose + banking | ✅ Safe — self-contained LocalScript |
| `src/client/InfluenceUI.luau` | Builds HUD, listens to `MatterUpdate` | ✅ Safe — owns the Matter UI |
| `src/shared/GameConfig.luau` | Shared tuning constants | ⚠️ **Shared** — append new keys, don't reorganize, to avoid conflicts |
| `src/shared/Remotes.luau` | Defines all RemoteEvents | ⚠️ **Shared** — add new remotes here; coordinate |

**Rule of thumb:** the ✅ files are owned by one feature and safe to work in solo. The ⚠️ files are coordination points — tell each other before restructuring them.

---

## ⚠️ Place-level settings NOT in source control

These were set directly in Studio via MCP and live in the **.rbxl place file**, not in the Rojo `src/`. A freshly opened place will NOT have them:

| Setting | Value |
|---|---|
| `Workspace.Gravity` | `0` |
| `Lighting.ClockTime` | `0` |
| `Lighting.Brightness` | `2` |
| `Lighting.Ambient` | `(80, 80, 110)` |
| `Lighting.OutdoorAmbient` | `(20, 20, 40)` |
| `Lighting.Atmosphere.Density` | `0` |
| Baseplate / SpawnLocation | deleted |

**To collaborate safely, both devs must work in the same shared place** (Team Create on placeId `80256981299890`, or open the same saved `.rbxl`). If you serve into a blank baseplate, expect full gravity + bright daylight until these are re-applied.

> 🔧 **Recommended cleanup (not done yet):** move gravity + lighting into `WorldBuilder.luau` so the whole world is reproducible from source. Until then, treat the above as manual setup. Ask Bread's Claude session to do this if it becomes annoying.

---

## Suggested Next Tasks (pick non-overlapping lanes)

To stay out of each other's files:

- **Bread's lane (traversal/world feel):** Sprint 0 polish — flying animation, dash/boost, camera FOV kick. Files: `SpaceMovement.client.luau`, `WorldBuilder.luau`.
- **Open lane for Nova (Matter systems):** Sprint 1B — spend Matter to buy an upgrade that raises `matterPerSec`. Files: `PlayerManager.luau`, `InfluenceUI.luau`, plus one new remote in `Remotes.luau` and one constant in `GameConfig.luau`.

Both lanes only collide in the ⚠️ shared files (`Remotes`, `GameConfig`, the two `Main` files) — a quick "hey I'm adding X" message avoids any conflict.

See `docs/EPICS/` for the full sprint breakdowns and tuning constants.

---

## Workflow Reminder

```bash
git pull           # ALWAYS before starting a session
# ...work...
git add <files>
git commit -m "..."
git push           # so the other person + their Claude has it
```

Update this file's "Last updated" line and the tables whenever you finish a sprint or start working in a new file.
