# Grow A [X] — Claude Code Context

Working title is **Grow A [X]** (final name TBD). Developed by **Bread** and **Nova**.

> 📋 **Starting a session? Read [`HANDOFF.md`](HANDOFF.md) first** — current state, which files are safe to touch, which are shared coordination points, and what's NOT in source control.

---

## Game Concept

An idle/progression + civilization management game on Roblox. The player is a **Universe Architect** — a godlike entity who floats through space and guides the evolution of life and civilizations across planets.

The player is NOT a colonist or creature. They act from above, spending **Influence** to push civilizations forward through eras.

**Core fantasy:** Help tiny organisms evolve from primitive life into spacefaring societies that eventually build Dyson spheres.

---

## Core Loop

1. Player joins and receives a personal planet/system.
2. The planet passively generates **Influence** over time.
3. Player spends Influence on interventions: Guide Evolution, Stabilize Climate, Inspire Discovery, etc.
4. Interventions raise planet stats: Life, Technology, Stability.
5. Planet visually evolves through eras:
   - Barren Planet → Primitive Life → Early Civilization → Industrial Civilization → Space Age → Interplanetary Expansion
6. Random events occur: climate shifts, asteroid threats, plagues, wars, solar storms.
7. Player uses Influence to help civilizations survive events.
8. Late game: civilizations expand to moons/other planets, build Dyson Swarms/Spheres.

---

## Architecture

### Tech Stack
- **Rojo 7.4.4** via Rokit — syncs local files to Roblox Studio
- **Luau** for all game logic
- **Roblox Studio MCP** connected for AI-assisted development

### Folder → Roblox Service Mapping
| Local path | Roblox location |
|---|---|
| `src/server/` | `ServerScriptService` |
| `src/client/` | `StarterPlayer/StarterPlayerScripts` |
| `src/shared/` | `ReplicatedStorage` |
| `src/gui/` | `StarterGui` |

### File Naming Conventions
- `Main.server.luau` — server entry point Script
- `Main.client.luau` — client entry point LocalScript
- `*.luau` (no suffix) — ModuleScript, required explicitly
- Do NOT create `init.server.luau` or `init.client.luau` inside service-mapped folders — it breaks Rojo

### Module Pattern
All systems are ModuleScripts with an `.init()` function. Entry points (`Main.server.luau`, `Main.client.luau`) only call `.init()` on each system. Keep systems single-responsibility.

```
src/server/Main.server.luau          → requires and inits all server systems
src/server/WorldBuilder.luau         → builds centerpiece star + star field from script on server start
src/server/PlayerManager.luau        → player profiles, influence tick, remote firing
src/client/Main.client.luau          → requires and inits all client systems
src/client/InfluenceUI.luau          → builds HUD, listens to InfluenceUpdate remote
src/client/SpaceMovement.client.luau → standalone LocalScript; floaty space movement (no module pattern — runs itself)
src/shared/GameConfig.luau           → shared constants (BASE_INFLUENCE_PER_SEC, etc.)
src/shared/Remotes.luau              → creates RemoteEvents server-side, waits client-side
```

> **Note:** `SpaceMovement.client.luau` is a self-contained LocalScript, not a module. It does not follow the `Main → require → .init()` pattern because it has no dependencies and needs no coordination with other systems.

### RemoteEvents
All remotes are defined in `src/shared/Remotes.luau`. Server creates them on load; client waits for them. Never hardcode remote names elsewhere.

| Remote | Direction | Payload |
|---|---|---|
| `InfluenceUpdate` | Server → Client | `{ influence: number, influencePerSec: number }` |

---

## World / Environment State

**All of this is now built from source by `src/server/WorldBuilder.luau` on server start** — gravity, lighting, baseplate cleanup, and the visual objects. A blank baseplate place becomes the correct space environment on Play, so any dev can clone + serve without manual Studio setup.

| Setting | Value | Reason |
|---|---|---|
| `Workspace.Gravity` | `0` | Players float in space |
| `Lighting.ClockTime` | `0` | Midnight → dark star sky |
| `Lighting.Brightness` | `2` | Low but character stays visible |
| `Lighting.Ambient` | `(80, 80, 110)` | Soft blue fill so the avatar reads against the void |
| `Lighting.OutdoorAmbient` | `(20, 20, 40)` | Darker space-sky tint |
| `Lighting.Atmosphere.Density/Haze/Glare` | `0` | No atmospheric haze |
| `Lighting.SunRays` | Disabled | No sun in open space |
| `Lighting.Bloom` | Intensity 0.4, Size 24, Threshold 0.95 | Subtle space glow |
| `Lighting.DepthOfField` | Disabled | Keep distant stars crisp |
| Baseplate / SpawnLocation | Removed at runtime | No ground; players spawn at origin |
| `workspace.SpaceEnvironment` | Centerpiece star + 200-star field | Motion reference; fixed RNG seed `20260618` so both devs see an identical layout |

> To change the look, edit the constants at the top of `WorldBuilder.luau` (`GRAVITY`, `BRIGHTNESS`, `AMBIENT`, etc.) — don't set Lighting in Studio, it'll be overwritten on the next Play.

---

## Design Principles

- **One small thing at a time.** Don't build ahead of the current sprint.
- **No saving yet** until a DataStore epic is explicitly started.
- **No planet visuals yet** until the planet era epic is started.
- **No upgrades yet** until Epic 2.
- Server is the source of truth for all player data. Client only receives and displays.
- Movement is client-side prototype only — no server-authoritative movement yet.

---

## Running Locally

```bash
# Install tools
rokit install

# Start Rojo sync server (keep this running while in Studio)
rojo serve

# Connect in Studio: open Rojo plugin → Connect (auto-finds localhost:34872)
```

---

## Collaboration & Git Workflow

Two devs (**Bread** and **Nova**) run separate Rojo instances. To avoid clobbering each other's history, **never commit straight to `main`** — each dev works on a personal branch and merges to `main` via PR.

- **Bread:** `bread/world-feel`
- **Nova:** `nova/<topic>` (e.g. `nova/influence-upgrades`)

> Git branches don't affect Rojo — each dev serves their own files from their own branch. Branching only separates commit history.

```bash
git checkout <your-branch>   # confirm you're on YOUR branch, not main
# ...work...
git add <files>
git commit -m "..."
git push                     # goes to your branch

git fetch origin             # periodically pull in the other person's merged work:
git merge origin/main        # keeps the eventual PR small
```

Ship via PR: `https://github.com/tiennguyen03/grow-a-x/pull/new/<your-branch>`

**Shared coordination-point files** (conflict-prone — announce edits): `Main.server.luau`, `Main.client.luau`, `shared/Remotes.luau`, `shared/GameConfig.luau`. See `HANDOFF.md` for the full per-file touch-safety map.

---

## Epic Tracker

| Epic | Status |
|---|---|
| Epic 1: Core Influence Loop | In Progress |
| Epic 2: Planet Upgrade System | Not Started |
| Epic 3: Planet Era Visuals | Not Started |
| Epic 4: Events & Disasters | Not Started |
| Epic 5: DataStore / Saving | Not Started |
| Epic 6: Multi-Planet Expansion | Not Started |

See `docs/EPICS/` for detailed sprint breakdowns.
