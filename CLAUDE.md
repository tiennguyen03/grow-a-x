# Grow A [X] — Claude Code Context

Working title is **Grow A [X]** (final name TBD). Developed by **Bread** and **Nova**.

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

These are set directly in Studio via MCP (not managed by Rojo — Studio owns them):

| Setting | Value | Reason |
|---|---|---|
| `Workspace.Gravity` | `0` | Players float in space |
| `Lighting.ClockTime` | `0` | Midnight → dark star sky |
| `Lighting.Brightness` | `1` | Low but not pitch black |
| `Lighting.Ambient` | `(5, 5, 15)` | Deep space blue tint |
| `Lighting.OutdoorAmbient` | `(5, 5, 15)` | Matches ambient |
| `Lighting.Atmosphere.Density` | `0` | No atmospheric haze |
| `Lighting.Bloom` | Intensity 0.4, Threshold 0.95 | Subtle space glow |
| Baseplate | Deleted | No ground in space |
| SpawnLocation | Deleted | Players spawn at origin |

> **Visual reference objects** (`workspace.SpaceEnvironment`: centerpiece star + star field) are NOT placed in the .rbxl — they are built from `src/server/WorldBuilder.luau` on server start so they stay reproducible from source. Star field uses a fixed seed (`20260618`) so both devs see an identical layout.

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
