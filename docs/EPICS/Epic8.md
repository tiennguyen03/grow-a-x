# Epic 8: From Archaea to Universe — Evolutionary Progression

**Status:** 📋 Planned / Not Started  
**Dependency:** Epic 1 (Matter Loop) must be complete (Sprint 1A ✅, Sprint 1B in progress)  
**Estimated Sprints:** 8 sprints (8A–8H)  
**Core Designer:** TBD (coordinate with Nova on Matter integration)

---

## One-Sentence Goal

Players spend Matter to guide their planet's life through **9 evolutionary tiers** — starting from single-celled archaea, advancing through complex life, tool use, civilization, space colonization, and ultimately universal mastery — with each tier unlocking new visual changes, passive bonuses, and Matter generation multipliers.

---

## Core Design Philosophy

1. **Evolution feels earned.** Each tier costs progressively more Matter and requires the previous tier. No skipping.

2. **Visual storytelling is primary.** The planet visibly changes at each tier — the player *sees* their investment pay off.

3. **Passive rewards reinforce active play.** Each tier increases the Matter collection rate (faster dust respawn, more dust, or higher-value dust) so the game accelerates naturally.

4. **9 tiers, each with a clear fantasy moment.** From "first life" to "Dyson sphere," each step should feel monumental.

5. **Symmetry with the Kardashev scale.** Later tiers map to the Kardashev scale:
   - Tier 1–3: Planetary civilization (Kardashev Type I)
   - Tier 4–6: Stellar civilization (Kardashev Type II)
   - Tier 7–9: Galactic/Universal civilization (Kardashev Type III+)

---

## The 9 Evolutionary Tiers

| Tier | Name | Matter Cost | Visual Effect | Passive Bonus | Unlock |
|------|------|-------------|---------------|---------------|--------|
| **1** | **Archaea** | 10 | Planet gains a faint green microbial glow | Dust respawn time: 4s → 3.5s | First Intervention |
| **2** | **Multicellular Life** | 25 | Small green patches appear (primitive plants) | +5% dust spawn rate | Tier 1 |
| **3** | **Complex Life** | 50 | Forests/reefs visible; atmosphere turns blue-green | +10% dust spawn rate | Tier 2 |
| **4** | **Tool Use / Early Civilization** | 100 | Tiny orange lights (campfires/settlements) at night | Matter collection radius +5 studs | Tier 3 |
| **5** | **Industrial Revolution** | 250 | Gray smog/industrial haze; glowing cities | Dust respawn time: 3.5s → 3s | Tier 4 |
| **6** | **Space Age** | 500 | Satellites orbit planet; rocket launch visuals | +25% dust spawn rate; magnet pull speed +5 | Tier 5 |
| **7** | **Interplanetary Expansion** | 1000 | Moons have colonies; glowing orbital rings | Dust spawn radius expands +200 studs | Tier 6 |
| **8** | **Dyson Swarm** | 2500 | Planet partially encased in energy collectors | Dust value: +1 → +3 per mote | Tier 7 |
| **9** | **Universal Mastery** | 10000 | Planet becomes a glowing cosmic artifact; universe-scale aura | Matter generation: passive +5/sec (stacks with collection) | Tier 8 |

---

## Sprint Breakdowns

---

### Sprint 8A: Tier Data Foundation

**Goal:** Create the data structures that define all 9 tiers. No visual changes yet — just the upgrade tree and cost table.

**Files:**
- `src/shared/EvolutionTiers.luau` (NEW)
- `src/shared/GameConfig.luau` (append constants)

**Tasks:**

- [ ] **8A-01** Create `EvolutionTiers.luau` with a table of all 9 tiers:
```luau
local EvolutionTiers = {
    TIER_ARCHAEA = {
        id = "archaea",
        name = "Archaea",
        cost = 10,
        visualEffect = "microbial_glow",
        passiveBonus = { dustRespawnMultiplier = 0.875 }, -- 4s → 3.5s
        unlockMessage = "The first spark of life appears on your world..."
    },
    TIER_MULTICELLULAR = {
        id = "multicellular",
        name = "Multicellular Life",
        cost = 25,
        visualEffect = "primitive_plants",
        passiveBonus = { dustSpawnMultiplier = 1.05 },
        unlockMessage = "Life grows complex. Cells begin to cooperate..."
    },
    -- ... repeat for all 9 tiers
}
```

---

### Sprint 8B: Matter Converter (Archaea Cell) ✅

**Goal:** First playable slice of Epic 8 — a toggleable GUI where the player spends collected Matter to create an **Archaea Cell**, the first life form, which then produces Matter passively. This is the seed of the full 9-tier tree above (8B implements only Tier 1 as a working loop; richer tiers/visuals come later).

**Owner/files:**
- `src/shared/GameConfig.luau` (⚠️ shared — appended constants)
- `src/shared/Remotes.luau` (⚠️ shared — added 2 remotes)
- `src/server/PlayerManager.luau` (Matter server logic — owns converter state + production)
- `src/client/MatterConverterUI.luau` (NEW — the converter panel)
- `src/client/Main.client.luau` (⚠️ shared — inits the new UI)

**Key constants (`GameConfig`):**
- `MATTER_CONVERTER_COST_ARCHAEA = 15` — Matter to create one Archaea Cell
- `ARCHAEA_PRODUCTION_INTERVAL = 5` — seconds between passive production ticks
- `ARCHAEA_PRODUCTION_AMOUNT = 1` — Matter per cell per tick

**Remotes (`Remotes.luau`):**
| Remote | Direction | Payload |
|---|---|---|
| `CreateArchaea` | Client → Server | *(none)* — request to spend Matter on one cell |
| `ConverterUpdate` | Server → Client | `{ archaeaCount: number }` |

**How it works:**
- The player presses **C** to toggle the Matter Converter panel (`MatterConverterUI`). The panel shows the live Matter balance, the Archaea Cell recipe (cost + production), how many cells are owned, and a Create button that greys out when Matter < cost.
- The Create button fires `CreateArchaea`. **The server is authoritative**: `PlayerManager.onCreateArchaea` re-checks affordability, deducts the cost, increments `profile.archaeaCount`, and pushes both `MatterUpdate` (balance) and `ConverterUpdate` (count). The client never decides a purchase — the button state is only a hint.
- A single shared timer (`PlayerManager.runProduction`) ticks every `ARCHAEA_PRODUCTION_INTERVAL` seconds and awards each player `archaeaCount × ARCHAEA_PRODUCTION_AMOUNT` Matter via the existing `addMatter` path (so passive income reuses the same `MatterUpdate` + "+N" popup feedback as dust collection).

**Not in scope for 8B:** persistence (cells reset on rejoin — waits on Epic 5 DataStore), planet visual changes per tier, and Tiers 2–9. The full tier table above is the forward plan.