# Epic 3: From Archaea to Universe — Evolutionary Progression

> **Formerly Epic 8** (file was `Epic8.md`) — renumbered to close the old `0,1,7,8` gap. Sprint IDs keep their original `8A`–`8H` labels; only the epic number changed.

**Status:** 🔶 In Progress — Tier 1 organelle path (8C) + Eukaryotic Cascade & Dust Multiplier (8D) + Biosphere View (8E) built, pending in-Studio playtest  
**Dependency:** Epic 1 (Matter Loop) must be complete (Sprint 1A ✅, Sprint 1B in progress)  
**Estimated Sprints:** 8 sprints (8A–8H)  
**Core Designer:** Nova (Matter / economy lane)

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

> **Update (2026-06-19, Matter Core integration):** the converter was unified with the Epic 4 planet inspect UI (`docs/Plans/MatterCore-Inspect-Integration.md`). **Create Life** is now a planet intervention inside the inspect panel (server-authoritative spend unchanged); the standalone GUI was renamed **"Matter Core"** and is now a read-only overview (balance / owned / production + inspected-planet context). On the first cell, `PlayerManager` sets `EvolutionTier=1`/`EvolutionStage="Archaea"` on the planet so the inspect panel + Archaea glow update automatically. The server logic below is unchanged.

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

---

### Sprint 8C: Organelle Upgrade Path (Archaea → Eukaryotic)

**Goal:** Turn Tier 1 into the game's main early loop. A basic Archaea Cell is upgraded one **organelle** at a time, in a fixed order, each raising that cell's passive production. Buying the final organelle (the Nucleus) evolves the cell into a **Eukaryotic Cell**. Players may own **any number** of cells, each with its own independent organelle path — build wide (many basic cells) or deep (fully evolve one). All UI lives in the **planet inspect panel**; the old Matter Core panel is obsolete.

**Owner/files (Nova):**
- `src/shared/OrganelleData.luau` (NEW) — ordered organelle path: id, name, cost, productionBonus, visual key, description + helpers (`nextOrganelle`, `isComplete`, `indexOf`, `TOTAL_COST`).
- `src/shared/GameConfig.luau` (⚠️ shared — appended) — `PRODUCTION_TICK_INTERVAL`, `ARCHAEA_BASE_PRODUCTION`.
- `src/shared/Remotes.luau` (⚠️ shared — appended) — `PurchaseOrganelle` (C→S), `CellEvolved` (S→C).
- `src/server/PlayerManager.luau` — per-cell state, `onPurchaseOrganelle`, summed per-second production.
- `src/client/CellInterventionUI.luau` (NEW) — cell list + per-cell organelle detail UI, mounted into the inspect panel.
- `src/client/CellVisuals.client.luau` (NEW) — per-cell, per-organelle planet visuals + evolution celebration + "Eukaryotic Cell Unlocked!" toast.
- `src/client/PlanetInteraction.client.luau` (⚠️ **Tien's file** — cross-lane, by direction "do it all in the inspect panel") — replaced the inline "Create Life" block with a `CellInterventionUI.mount(...)`.

**The organelle path (ordered; costs sum to 240 Matter):**

| # | Organelle | Cost | +Production/sec | Visual layer |
|---|---|---|---|---|
| 1 | Cell Membrane | 5 | +0.2 | faint outer shell glow |
| 2 | Cytoplasm | 10 | +0.2 | filled inner body |
| 3 | Ribosomes | 15 | +0.3 | tiny green dots |
| 4 | Nucleoid | 25 | +0.4 | brighter dense core |
| 5 | Plasmids | 40 | +0.6 | ring of beads |
| 6 | Mitochondria | 60 | +0.8 | warm orange-gold glow |
| 7 | **Nucleus** | 85 | +1.0 | bright central core → **Eukaryotic** |

**Key constants (`GameConfig`):**
- `ARCHAEA_BASE_PRODUCTION = 0.2` — Matter/sec a fresh, organelle-less cell makes (= the legacy 1-per-5s feel).
- `PRODUCTION_TICK_INTERVAL = 1` — production now ticks per second and sums fractional per-cell rates.
- A fully evolved cell ≈ `0.2 + 3.5 = 3.7` Matter/sec (organelle bonuses sum to 3.5; "around 3.5").

**How it works:**
- Each player's profile now holds `cells = { { id, stage, purchased, purchasedCount, production }, … }` instead of a scalar count (`matter` is now a float for fractional production). `ConverterUpdate` carries `{ archaeaCount (= #cells, back-compat), totalProduction, cells }`.
- `CreateArchaea` appends a fresh Archaea Cell (base production, no organelles) — no cap. The first ever cell still flips the planet to `EvolutionTier=1 / Archaea`.
- `PurchaseOrganelle { cellId, organelleId }` is **server-authoritative and order-enforced**: the request must name the exact next organelle for that cell (`OrganelleData.nextOrganelle`), the server re-checks affordability, deducts, marks it, and raises that cell's production. The 7th purchase sets `stage = "Eukaryotic"` and fires `CellEvolved` for the client celebration.
- `runProduction` ticks every second, summing each cell's `production` across all the player's cells.
- `CellVisuals` renders each cell as a small glowing body orbiting the planet, adding a cosmetic layer per organelle; on `CellEvolved` it plays a green pulse + particle burst and floats the "Eukaryotic Cell Unlocked!" notification (capped at `MAX_RENDERED_CELLS` drawn cells for performance — the economy still counts them all).

**Not in scope for 8C:** persistence (cells reset on rejoin — waits on the DataStore epic), Tier 2 (Bacteria) and beyond, and advancing the *planet* past Archaea when a cell becomes Eukaryotic (the planet-stage ladder is a later sprint). The Matter Core panel (`MatterConverterUI`) is left in place but vestigial.

---

### Sprint 8D: Eukaryotic Cascade + Dust Multiplier

**Goal:** Make the first Eukaryotic evolution a watershed moment with two permanent, tightly-linked rewards — an instant **Eukaryotic Cascade** (every cell evolves at once and all future cells are born Eukaryotic) and a permanent **Dust Multiplier** that raises the Matter value of every dust mote. Both fire together the first time a player completes a Eukaryotic Cell.

**Owner/files (Nova):**
- `src/server/PlayerManager.luau` — cascade + dust-multiplier logic; new profile fields; dust award now scales.
- `src/shared/OrganelleData.luau` (⚠️ shared — appended) — `TOTAL_PRODUCTION_BONUS` (sum of organelle bonuses ≈ 3.5) for one-shot full evolution.
- `src/shared/Remotes.luau` (⚠️ shared — appended) — `CascadeTriggered` (S→C).
- `src/client/CellVisuals.client.luau` — cascade celebration (multi-cell bursts + big two-line toast).
- `src/client/MatterConverterUI.luau` — "Dust Value: ×N" indicator.
- `src/client/CellInterventionUI.luau` (⚠️ **Nova/progression file** — added a "Dust Value ×N" readout to the summary line).

**Eukaryotic Cascade (one-time, per player):**
- Triggered when a player completes their **first** Eukaryotic Cell (buys the Nucleus on any cell). The server sets `profile.cascadeTriggered = true`, then loops every **other** cell and calls `makeEukaryotic` on it (all organelles owned, stage = Eukaryotic, full production) in one shot.
- From then on, `onCreateArchaea` spawns each new cell **already Eukaryotic** (same creation cost — the cascade is the reward). `ConverterUpdate` carries `cascadeTriggered` so the inspect panel's create button relabels from **"Create Archaea Cell"** to **"Create Eukaryotic Cell"** once the cascade has fired (otherwise it kept saying "Archaea" while actually spawning Eukaryotes).
- Fires `CascadeTriggered { triggerCellId, cellIds (the others), count, dustMultiplier }`. `CellVisuals` plays a green pulse + particle burst on every affected cell and shows a big two-line **"Eukaryotic Evolution Cascade!"** toast listing how many cells evolved. The planet's `EvolutionStage` attribute flips to `"Eukaryotic"`.
- If the player had only the one cell, the cascade still fires (marking the milestone + dust multiplier) and the toast reads **"First Eukaryotic Cell!"**.

**Dust Multiplier (permanent, grows per tier):**
- Formula: `dustMultiplier = floor((tier + 1)^2 / 2)`, where `tier` is the life-form tier just evolved into for the first time. **Tier 1 (Eukaryotic) → ×2**, tier 2 → ×4, tier 3 → ×8, tier 4 → ×12. Monotonic — a higher tier never lowers it.
- `PlayerManager.collect` now awards `profile.dustMultiplier` Matter per mote instead of a hardcoded `1`.
- Exposed via `ConverterUpdate.dustMultiplier`; shown as **"Dust Value: ×N"** in the Matter Core panel and the inspect panel's summary line. Only Tier 1 exists today; `applyTierEvolution(profile, tier)` + `dustMultiplierForTier(tier)` are ready for higher tiers.

**New profile fields:** `cascadeTriggered` (bool), `dustMultiplier` (number, starts 1), `maxTierEvolved` (number, starts 0).

**Not in scope for 8D:** persistence (all three new fields reset on rejoin — waits on the DataStore epic), Tier 2+ evolutions (the formula is wired but no tier-2 life form exists yet), and removing the vestigial Matter Core panel.

---

### Sprint 8E: Biosphere View (Life Vessel + Microscope)

**Goal:** Give the player a dedicated, planet-independent way to *see* their biosphere with two togglable modes that share the same data (total cell count + dominant life form, derived client-side from `ConverterUpdate`).

**Owner/files (Nova):**
- `src/client/BiosphereView.client.luau` (NEW) — self-contained LocalScript; owns both modes. No `Main.client` wiring, no server changes, and **it never touches the planet visuals**.

**Life Vessel (always active):**
- A glass `Part` orb (`Material = Glass` + inner `PointLight` + a trail `ParticleEmitter` + a one-shot burst emitter) that floats at a fixed camera-relative offset (lower-right companion orb), eased toward its spot each `RenderStepped`.
- Richness scales through **7 tiers by cell count** (0 / 1–9 / 10–99 / 100–999 / 1e3–1e6 / 1e6–1e9 / 1e9+): more internal neon "speckles", brighter glow, and stronger swirl as the population climbs. Speckles only rebuild when the tier changes (perf).
- Gentle **heartbeat pulse** (size + glow), **tints toward the dominant life form** (Archaea teal → Eukaryotic green), trails subtle particles, and **bursts** when a cell is created (count increases), on `CellEvolved`, and on `CascadeTriggered`.

**Microscope View (toggleable overlay):**
- A `ScreenGui` + `ViewportFrame` "drop of water" panel. Cells swim with **Brownian motion** inside a bounded box, each a translucent body + bright nucleus (+ orange organelle specks once the dominant form is Eukaryotic).
- Displayed cell count scales **log-ically** with population (`~4·(log10(n)+1)`, capped at 50) so it grows dense; the viewport camera **pulls back** as population rises to show a larger sample. A readout shows population / shown / dominant form.

**Toggle + transition:** **M** (or **Tab**) toggles the microscope. Opening tweens the panel up from the vessel's on-screen position (a "zoom in"); closing shrinks it back to the vessel ("zoom out"). The vessel keeps running underneath, so the two modes stay continuous.

**Not in scope for 8E:** persistence, any server change (purely a client visualization of existing `ConverterUpdate` data), and real per-cell identity in the microscope (it's a representative sample, not a 1:1 render of owned cells). The high tiers (1e3+) are forward-looking — current play only reaches the low tiers.