# Epic 1: Core Influence Loop

The foundation of the game. Establishes that players earn Influence passively over time and can see it on screen. No upgrades, no saving, no planet visuals — just the raw loop.

---

## Sprints

### Sprint 1A: Influence Generation ✅ COMPLETE

**Goal:** Player joins → server creates profile → Influence ticks up every second → UI displays it.

**Scope (intentionally minimal):**
- [x] Server creates player profile on `PlayerAdded`
- [x] Profile starts with `influence = 0` and `influencePerSec = 1`
- [x] Server fires `InfluenceUpdate` RemoteEvent to each player every second
- [x] Client HUD shows current Influence and +rate
- [ ] No upgrades
- [ ] No planet visuals
- [ ] No saving
- [ ] No events

**Files added:**
- `src/shared/GameConfig.luau` — `BASE_INFLUENCE_PER_SEC = 1`
- `src/shared/Remotes.luau` — defines `InfluenceUpdate` RemoteEvent
- `src/server/PlayerManager.luau` — creates profiles, runs 1-second tick, fires remote
- `src/server/Main.server.luau` — calls `PlayerManager.init()`
- `src/client/InfluenceUI.luau` — builds dark HUD panel, updates on remote
- `src/client/Main.client.luau` — calls `InfluenceUI.init()`

**Constants:**
- `BASE_INFLUENCE_PER_SEC = 1` (in `GameConfig.luau`)

---

### Sprint 1B: Upgrade — Boost Influence Rate (NOT STARTED)

Planned scope:
- Player can spend Influence to permanently increase `influencePerSec`
- First upgrade: costs 10 Influence, adds +1/sec
- UI shows a Buy button with cost
- No DataStore yet — resets on rejoin

---

### Sprint 1C: DataStore Save/Load (NOT STARTED)

Planned scope:
- Save `influence` and `influencePerSec` per player to DataStore
- Load on join, save on leave and periodically
- Handle DataStore failures gracefully (don't wipe data on error)
