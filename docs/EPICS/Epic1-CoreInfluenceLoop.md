# Epic 1: Core Matter Loop

The foundation of the game. Establishes that players earn Matter passively over time and can see it on screen. No upgrades, no saving, no planet visuals — just the raw loop.

---

## Sprints

### Sprint 1A: Matter Generation ✅ COMPLETE

**Goal:** Player joins → server creates profile → Matter ticks up every second → UI displays it.

**Scope (intentionally minimal):**
- [x] Server creates player profile on `PlayerAdded`
- [x] Profile starts with `matter = 0` and `matterPerSec = 1`
- [x] Server fires `MatterUpdate` RemoteEvent on join (HUD shows `Matter: 0` instantly) and every second after
- [x] Client HUD shows current Matter and +rate
- [ ] No upgrades
- [ ] No planet visuals
- [ ] No saving
- [ ] No events

**Files added:**
- `src/shared/GameConfig.luau` — `BASE_MATTER_PER_SEC = 1`
- `src/shared/Remotes.luau` — defines `MatterUpdate` RemoteEvent
- `src/server/PlayerManager.luau` — creates profiles, runs 1-second tick, fires remote
- `src/server/Main.server.luau` — calls `PlayerManager.init()`
- `src/client/InfluenceUI.luau` — builds dark HUD panel, updates on remote
- `src/client/Main.client.luau` — calls the HUD module's `init()`

**Constants:**
- `BASE_MATTER_PER_SEC = 1` (in `GameConfig.luau`)

---

### Sprint 1B: Upgrade — Boost Matter Rate (NOT STARTED)

Planned scope:
- Player can spend Matter to permanently increase `matterPerSec`
- First upgrade: costs 10 Matter, adds +1/sec
- UI shows a Buy button with cost
- No DataStore yet — resets on rejoin

---

### Sprint 1C: DataStore Save/Load (NOT STARTED)

Planned scope:
- Save `matter` and `matterPerSec` per player to DataStore
- Load on join, save on leave and periodically
- Handle DataStore failures gracefully (don't wipe data on error)
