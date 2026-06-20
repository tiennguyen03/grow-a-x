# Grow A [X] — Claude Code Context

Working title is **Grow A [X]** (final name TBD). Developed by **Tien** and **Nova**.

> 📋 **Starting a session?** Read [`HANDOFF.md`](HANDOFF.md) first (global state), then the active developer's lane handoff:
> - Tien work → [`HANDOFF-TIEN.md`](HANDOFF-TIEN.md)
> - Nova work → [`HANDOFF-NOVA.md`](HANDOFF-NOVA.md)
>
> If the task touches shared files or the other developer's lane, also read their handoff before editing. `HANDOFF.md` tells you which files are safe to touch, which are shared coordination points, and what's NOT in source control.

---

## Claude Operating Rules

Claude should behave like a senior engineer on a two-person Roblox/Rojo project. Writing code is only part of the job — Claude must also preserve project context, reduce merge conflicts, and leave the next developer with a clean starting point.

**Before starting any task:**

1. Read `HANDOFF.md` (global state), then the active developer's lane handoff (`HANDOFF-TIEN.md` or `HANDOFF-NOVA.md`); read the other dev's handoff too if the task touches shared files or their lane.
2. Check the relevant epic doc in `docs/EPICS/`.
3. Identify the current sprint and the exact ticket/task being worked on.
4. Identify which developer is active / owns the task: **Tien** or **Nova**.
5. Identify the files that are safe to edit.
6. Identify files that are shared coordination points or conflict-prone.
7. Avoid touching shared coordination files unless the task explicitly requires it.
8. Confirm what is explicitly out of scope.
9. Keep the implementation small and aligned with the current sprint.
10. Identify which handoff file to update afterward, and whether `HANDOFF.md` needs a global update or only the per-developer file does (see [Handoff File Workflow](#handoff-file-workflow)).
11. Leave the next developer with a clean starting point.

**When finishing any task**, provide a handoff summary (see [Required Handoff Summary Format](#required-handoff-summary-format)) covering: what changed, files touched, how to test in Roblox Studio, known issues / unfinished work, what Tien or Nova should do next, and which handoff file (per-dev vs global) plus epic doc needs updating.

Handoff context is **mandatory after every implementation task** — Claude should not wait for the user to ask for it. If the task is unclear, ask for clarification before editing shared or high-risk files; if it's clear and low-risk, proceed without over-planning.

---

## Handoff File Workflow

The project uses **one global handoff file plus one per-developer lane file**, so Tien and Nova aren't constantly editing the same file for day-to-day updates (which caused merge conflicts).

- **`HANDOFF.md`** — the global integration snapshot (project status, integration/branch state, active-lanes table, global blockers, shared-coordination files, stable file map/ownership, merge/PR notes). **Not a daily scratchpad.**
- **`HANDOFF-TIEN.md`** — Tien's active-lane handoff (current branch, focus, files being touched, recent changes, blockers, next steps).
- **`HANDOFF-NOVA.md`** — Nova's active-lane handoff (same shape).

**Read order:** always read `HANDOFF.md` first, then the **active** developer's lane file, then the other developer's only if the task touches shared files or their lane.

**Update rules:**
- During normal implementation, update the **active developer's** lane file (Tien work → `HANDOFF-TIEN.md`; Nova work → `HANDOFF-NOVA.md`).
- Update **`HANDOFF.md`** *only* when global/integration state changes: a sprint completes, a branch merges, a new system/file is added, file ownership changes, a global blocker appears, or integration state moves.
- **Do not edit the other developer's lane file** unless explicitly asked, or the task is a coordination/merge task.

---

## Game Concept

An idle/progression + civilization management game on Roblox. The player is a **Universe Architect** — a godlike entity who floats through space and guides the evolution of life and civilizations across planets.

The player is NOT a colonist or creature. They act from above, spending **Matter** to push civilizations forward through eras.

**Core fantasy:** Help tiny organisms evolve from primitive life into spacefaring societies that eventually build Dyson spheres.

---

## Core Loop

1. Player joins and receives a personal planet/system.
2. The player gathers **Matter** by flying through glowing dust motes scattered across the void.
3. Player spends Matter on interventions: Guide Evolution, Stabilize Climate, Inspire Discovery, etc.
4. Interventions raise planet stats: Life, Technology, Stability.
5. Planet visually evolves through eras:
   - Barren Planet → Primitive Life → Early Civilization → Industrial Civilization → Space Age → Interplanetary Expansion
6. Random events occur: climate shifts, asteroid threats, plagues, wars, solar storms.
7. Player uses Matter to help civilizations survive events.
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
# Server
src/server/Main.server.luau          → requires and inits all server systems
src/server/WorldBuilder.luau         → builds the environment (gravity/lighting), centerpiece star, star field + collectible dust motes
src/server/PlayerPlanetService.luau  → builds one deterministic procedural planet per player on join; server-side orbit + spin (Epic 2)
src/server/PlayerManager.luau        → player profiles, dust collection + Matter awards, converter/cell state, organelle purchases, Eukaryotic Cascade + Dust Multiplier (Epic 1/3)

# Client
src/client/Main.client.luau          → requires and inits all client systems
src/client/MatterUI.luau             → builds HUD, listens to MatterUpdate remote, shows "+N" popup
src/client/SpaceMovement.client.luau → standalone LocalScript; floaty space movement (no module pattern — runs itself)
src/client/DustAnimator.client.luau  → standalone LocalScript; bobs the dust motes locally (no module pattern)
src/client/PlanetMarker.client.luau  → standalone LocalScript; screen-space marker pointing to the local player's orbiting planet (Epic 2)
src/client/PlanetInteraction.client.luau → standalone LocalScript; approach prompt + inspect camera + info panel; mounts the cell-intervention UI (Epic 4)
src/client/PlanetInspectContext.luau → client seam publishing the active inspected-planet context to other UIs (Epic 4)
src/client/PlanetStageVisuals.client.luau → standalone LocalScript; pulsing Archaea glow on the planet once life begins (Epic 4)
src/client/CellInterventionUI.luau   → cell list + per-cell organelle-upgrade UI, mounted into the inspect panel (Epic 3)
src/client/BiosphereView.client.luau → standalone LocalScript; Life Vessel orb (near camera, 1 speckle per cell) + Microscope ViewportFrame overlay (population zoom progression + fading organelles) + evolution/cascade celebration toasts; toggle M/Tab; client-only, no planet coupling (Epic 3)

# Shared (ReplicatedStorage)
src/shared/GameConfig.luau           → shared constants (DUST_* tuning, converter/organelle rates, etc.)
src/shared/Remotes.luau              → creates RemoteEvents server-side, waits client-side
src/shared/WorldConfig.luau          → world-level constants: star + planet/orbit composition; pure data (Epic 2)
src/shared/PlanetArchetypes.luau     → planet archetype definitions (trait ranges + color palettes the generator rolls within); pure data (Epic 2)
src/shared/PlanetGenerator.luau      → pure, deterministic planet descriptor generator (seed → archetype + traits); no Instances (Epic 2)
src/shared/DustField.luau            → universe-wide dust spawn helper (getSpawnPosition) used by WorldBuilder + PlayerManager (Epic 1/2)
src/shared/OrganelleData.luau        → ordered Tier 1 organelle path (cost/bonus/visual) + helpers; pure data (Epic 3)
```

> **Note:** the `*.client.luau` files marked "standalone LocalScript" (`SpaceMovement`, `DustAnimator`, `PlanetMarker`, `PlanetInteraction`, `PlanetStageVisuals`, `BiosphereView`) are self-contained — they do not follow the `Main → require → .init()` pattern because they need no coordination with other systems and run themselves.

### RemoteEvents
All remotes are defined in `src/shared/Remotes.luau`. Server creates them on load; client waits for them. Never hardcode remote names elsewhere.

| Remote | Direction | Payload |
|---|---|---|
| `MatterUpdate` | Server → Client | `{ matter: number }` (client shows a "+N" popup from the delta) |
| `CreateArchaea` | Client → Server | *(none)* — request to spend Matter on one new cell (Epic 3) |
| `ConverterUpdate` | Server → Client | `{ archaeaCount, totalProduction, cells = {…}, dustMultiplier }` — full converter/cell state (Epic 3) |
| `PurchaseOrganelle` | Client → Server | `{ cellId, organelleId }` — buy the next organelle for a cell; server validates order + cost (Epic 3) |
| `CellEvolved` | Server → Client | `{ cellId }` — a single cell became Eukaryotic; drives the unlock celebration (Epic 3) |
| `CascadeTriggered` | Server → Client | `{ triggerCellId, cellIds, count, dustMultiplier }` — one-time Eukaryotic Cascade celebration + Dust Multiplier unlock (Epic 3) |

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
| `workspace.SpaceEnvironment` | Centerpiece star + 200-star field + 80 collectible dust motes | Motion reference + Matter pickups; fixed RNG seeds (`20260618` stars, `20260619` dust) so both devs see an identical layout |

> To change the look, edit the constants at the top of `WorldBuilder.luau` (`GRAVITY`, `BRIGHTNESS`, `AMBIENT`, etc.) — don't set Lighting in Studio, it'll be overwritten on the next Play.

> **WorldBuilder is the source of truth for the environment.** If a visual/environment change is needed, edit `WorldBuilder.luau`; do not manually place objects or change Lighting in Studio unless explicitly prototyping. Studio-side changes are overwritten by `WorldBuilder.luau` on Play.

---

## Design Principles

- **One small thing at a time.** Don't build ahead of the current sprint.
- **No saving yet** until a DataStore epic is explicitly started.
- **No planet visuals yet** until the planet era epic is started.
- **No generic upgrade shop yet.** The first spend mechanic should be framed as a planet *intervention* (e.g. "First Intervention — Guide Evolution"), not a generic upgrade system. The mechanic can still be *Cost: 10 Matter → Effect: a richer dust field*, but the fantasy is "the player spends Matter to guide early life toward complexity," not "buys an upgrade."
- Server is the source of truth for all player data. Client only receives and displays.
- Movement is client-side prototype only — no server-authoritative movement yet.
- **A task is not done until the next developer can continue from it without asking what happened.**
- **Every completed task should end with a clear handoff summary** (see "Required Handoff Summary Format").

---

## File Touch Rules

Classify a file before editing it.

### Safe Solo Files
Feature-specific files owned by the current ticket are usually safe to edit. Only one developer should own a feature-specific file at a time.
```text
src/client/SpaceMovement.client.luau   (Tien — traversal)
src/server/WorldBuilder.luau           (Nova — environment)
src/server/PlayerManager.luau          (Matter server logic)
src/client/MatterUI.luau               (Matter UI)
```

### Shared Coordination Files
Conflict-prone. Only edit if the current ticket explicitly requires it, and **call it out in the handoff summary**:
```text
src/server/Main.server.luau
src/client/Main.client.luau
src/shared/Remotes.luau
src/shared/GameConfig.luau
default.project.json
CLAUDE.md
HANDOFF.md
docs/AI_CONTEXT.md   (if present)
```

### Forbidden Unless Explicitly Asked
Do not add or modify these unless the task explicitly asks:
```text
DataStore / saving
monetization
admin commands
large refactors
new epics
new game systems outside the current sprint
server-authoritative movement
complex multiplayer systems
```

### Conflict Prevention
Before coding, know: who owns this task, which branch is in use, which files are allowed, which are forbidden, and which could cause merge conflicts.

---

## Session Startup Checklist

At the start of a coding session, answer these internally before making changes:

- What sprint/ticket are we working on?
- Is this task owned by Tien or Nova?
- What files are allowed for this task?
- What files are conflict-prone?
- What is explicitly out of scope?
- What does "done" mean for this task?
- What should the other developer know after this task?
- Do any docs need updating after this task?

If the task is unclear, ask for clarification before editing shared or high-risk files. If it's clear and low-risk, proceed without over-planning.

---

## Required Handoff Summary Format

At the end of every implementation task, output this handoff block:

```markdown
## Handoff Summary

### Completed
-

### Files Changed
-

### How To Test
-

### Known Issues / Unfinished Work
-

### Safe Next Tasks
-

### Do Not Touch Yet
-

### Docs To Update
-

### Handoff File Updated
- HANDOFF-TIEN.md / HANDOFF-NOVA.md / HANDOFF.md / None
```

Rules:
- Keep it specific to the task that was just completed.
- Mention exact file paths.
- Mention exact Roblox Studio test steps.
- If no docs need updating, write `None`.
- If another developer should continue, say exactly where they should start.
- If a file is conflict-prone, explicitly warn the next developer.

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

Two devs (**Tien** and **Nova**) run separate Rojo instances. To avoid clobbering each other's history, **never commit straight to `main`** — each dev works on a personal branch and merges to `main` via PR.

- **Tien:** `tien/<topic>`
- **Nova:** `nova/<topic>` (e.g. `nova/matter-upgrades`)

> Some existing branches predate this naming: `feature/0d-boost-movement` (active sprint work) and `bread/world-feel`. New branches should follow `tien/<topic>` / `nova/<topic>`.

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

### Documentation Preservation on Merge (non-negotiable)

**The project goal is to preserve as much documentation as possible.** When merging branches or PRs, documentation is **unioned, never overwritten**. Tien's and Nova's docs are additive — neither dev's documentation should be lost because the other's branch didn't have it.

When resolving a merge (or reconciling two branches) that touches `CLAUDE.md`, `HANDOFF.md`, `docs/EPICS/*`, `docs/PastEpics/*`, `docs/PastSprints/*`, `README`s, or in-code doc comments:

- **Keep everything from both sides.** If one branch has a sprint section, epic doc, HANDOFF row, table entry, or note the other lacks, **carry it into the merged result** — do not drop it just because it's only on one side.
- **Union over replace.** When the same section was edited on both sides, merge the content (combine bullets/rows/paragraphs) rather than picking one version and discarding the other. Only the currency rename (`Influence` → `Matter`) and other agreed factual corrections may replace text outright.
- **Never delete docs to resolve a conflict.** If two versions genuinely can't coexist inline, keep both and reconcile, or archive the older one via the "Archive before you revise" convention below — deletion is not an acceptable conflict resolution.
- **When in doubt, keep it.** Extra documentation is cheaper than lost context. If unsure whether a doc is still relevant, preserve it (archive rather than remove).
- **Call out doc merges in the handoff summary** so the other dev can confirm nothing of theirs was lost.

---

## Epic Tracker

| Epic | Doc | Status |
|---|---|---|
| Epic 0: World Traversal | `docs/EPICS/Epic0.md` | In Progress |
| Epic 1: Core Matter Loop | `docs/EPICS/Epic1.md` | In Progress |
| Epic 2: Procedural Planet Generation _(formerly Epic 7)_ | `docs/EPICS/Epic2.md` | In Progress |
| Epic 3: Evolutionary Progression _(formerly Epic 8)_ | `docs/EPICS/Epic3.md` | In Progress (8B–8D built: converter, organelle path, Eukaryotic Cascade + Dust Multiplier; playtest pending) |
| Epic 4: Planet Interaction & Inspection | `docs/EPICS/Epic4.md` | In Progress (4A–4G built; 4H playtest pending) |
| Epic 5: Planet Upgrade System / Matter Core | `docs/EPICS/Epic5.md` | In Progress (5A audit done; MVP largely pre-built by Nova's Epic 3 — see 5A) |
| Epic 6: Planet Era Visuals | `docs/EPICS/Epic6.md` | Not Started |
| Epic 7: Events & Disasters | `docs/EPICS/Epic7.md` | Not Started |
| Epic 8: DataStore / Saving | `docs/EPICS/Epic8.md` | Not Started |
| Epic 9: Multi-Planet Expansion | `docs/EPICS/Epic9.md` | Not Started |

> **Numbering note:** epic docs run `0,1,2,3,…` with no gaps. The two built planet epics are **Epic 2** (was 7) and **Epic 3** (was 8); their sprint IDs keep their original `7x`/`8x` letters to stay aligned with git history. **Epic 4 is now the concrete "Planet Interaction & Inspection" spec** (Tien's lane — approach prompt, inspect camera, planet info panel, Matter Converter hook); the previously-reserved planned epics (Upgrade System, Era Visuals, Events, DataStore, Multi-Planet) shifted down one to **5–9**.

### Documentation convention (keep this consistent)

- **Incoming epic specs → save a reference copy to `docs/PastEpics/` (do this automatically).** When Tien hands you an epic spec — a file (e.g. in `Downloads/`) or pasted text — to work on, always do **both**: (1) place it as the live `docs/EPICS/Epic<N>.md`, and (2) save a verbatim reference snapshot to `docs/PastEpics/Epic<N>.<YYYY-MM-DD>.md` so the original brief is permanently available for context/reference even after the live doc evolves. Then update the Epic Tracker row. Do this without being reminded — it is the standing convention for every epic Tien or Nova sends.
- **One file per epic**, named generally: `docs/EPICS/Epic<N>.md`. Never create a separate file for a sprint or ticket.
- Each epic doc has an H1 title (`# Epic N: <Name>`) and one `## Sprint <N><letter>` section per sprint, appended in order.
- When you finish or change a sprint, **update that epic's existing file** — add/append a sprint section, don't spin off a new doc.
- Keep sprint sections substantive but not bloated: goal, owner/file, checklist, key constants, how-it-works notes. Leave generic process boilerplate (PR templates, one-off AI prompts) out of the epic docs.
- If a sprint spec arrives as its own file, fold its useful content into the relevant `Epic<N>.md` and delete the standalone file.
- **Archive before you revise.** Before meaningfully changing an epic doc, copy the *current* version into `docs/PastEpics/` as `Epic<N>.<YYYY-MM-DD>.md` (whole-epic changes: title, status, overview/tier tables, multiple sprints). If the edit is scoped to a single sprint section, instead copy just that section into `docs/PastSprints/` as `Epic<N>-Sprint<NX>.<YYYY-MM-DD>.md`. Git history remains the source of truth — these folders are a convenience mirror. See each folder's guide doc.
- **Folder guide docs, not `README.md`.** A folder's explainer is named for the folder, not the generic `README.md`: use `<FolderName>-Guide.md` (e.g. `docs/PastEpics/PastEpics-Guide.md`, `docs/PastSprints/PastSprints-Guide.md`). Follow this `<FolderName>-Guide.md` pattern for any new folder that needs an explainer, so guides are self-describing in search and file lists.
- **Cross-cutting plans live in `docs/Plans/`.** Implementation/coordination plans that span more than one epic (or that aren't a single sprint/epic) go in `docs/Plans/` with a descriptive kebab-case name, indexed in `docs/Plans/Plans-Guide.md` — not in `docs/EPICS/`. Example: `docs/Plans/MatterCore-Inspect-Integration.md` (unifying the Epic 4 inspect UI with Nova's Epic 3 Matter Converter).
