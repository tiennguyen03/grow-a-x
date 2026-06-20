# Epic 7 — Complex Life: Sentience Progress & Civilization Tendencies

**Project:** Grow A [X]
**Epic Type:** Core Gameplay Progression / Civilization-Identity Foundation
**Status:** 📋 Planned / Ready for implementation
**Primary owner:** Tien (intervention/UI/ecosystem layer), with Nova coordination for the cell/Multicellular gate + shared economy files.
**Authored:** 2026-06-20 (Claude, from `GameplayProgressionVision_UPDATED_V2.md` §33, §35.3–35.4, §40).

---

## 0. Executive Summary

Epic 6 gave the planet its first planet-level strategy: **Life Progress** and **Stability**, with the
fast-vs-stable tension (Nourish / Stabilize / Accelerate). Epic 7 is the next era of that chain — the
bridge from biology to **civilization identity**.

Once life matures (Multicellular complete / Life Progress maxed), the planet enters **Complex Life**.
Here the player stops only asking *"how fast does life grow?"* and starts asking the vision's central
question (§33.2):

```text
What KIND of intelligent civilization am I creating?
```

Epic 7 introduces:

- **Sentience Progress** (0–100) — how close the dominant life is to tool use / civilization. At 100 it
  unlocks the **Tool Use** milestone.
- **Sentience interventions** — Encourage Cooperation / Curiosity / Adaptability / Competition / Nudge
  Problem Solving. Each spends Matter to raise Sentience Progress **and** push a long-term **tendency**.
- **Civilization Tendencies / Identity** — the foundational trait system. Early choices accumulate
  tendency points that surface as an emerging identity (e.g. "Curious · Cooperative"). This is the seed
  for Doctrine, Planet Specialties (V2 §51), trade, and diplomacy in later epics.

**It is built entirely on the Epic 5/6 framework** — new `InterventionData` entries + a few new effect
keys + new profile fields, applied through the existing server-authoritative `ApplyIntervention`
pipeline. No new economy framework, no duplication of Nova's cell/organelle/Multicellular lane.

This epic does **not** build Tool Use systems, full Doctrine effects, Civilization Projects, DataStore,
or any multiplayer/contact/trade. It establishes Sentience + Tendencies and the Tool Use milestone.

---

## 1. Relationship To Existing Systems

| System (in `main`) | Epic 7 relationship |
|---|---|
| **Epic 6 ecosystem** (`InterventionData`, `EcosystemInterventionUI`, `onApplyIntervention`, `lifeProgress`/`stability`) | **Extends it.** New `category="Sentience"` interventions + effect keys; same pipeline + UI patterns. |
| **Nova's cells / organelles / 8C–8E** | Untouched. Sentience is planet-level, never touches cells. |
| **Nova's Multicellular Path (1C, `MulticellularData`)** | **Gate point.** Complex Life unlocks when the Multicellular path is complete (or Life Progress 100) — coordinate with Nova (see Ticket 7.7). No second multicellular path. |
| **`PlanetStageVisuals` / `BiosphereView`** | Read new attributes for light feedback; BiosphereView is Nova-owned (coordinate, optional). |

**Design rule (carried from Epic 6):** integrate with Nova, never duplicate. Sentience is purely
additive to the shared `PlayerManager` / `Remotes` / `ConverterUpdate` (like Epic 6).

---

## 2. Design Pillars

1. **One question per era.** Epic 6 = "grow life safely or fast?" Epic 7 = "what kind of mind emerges?"
2. **Choices create tendencies, not punishment** (§33.4). Hybrid identities are good; nothing is a dead end.
3. **Server authority.** All sentience spends go through `ApplyIntervention`; the server owns Sentience
   Progress + tendency totals.
4. **Reveal stats only when usable** (§38.3). Sentience Progress + Tendencies appear at Complex Life, not before.
5. **Small now, foundational later.** The tendency table is the seed for Doctrine / Planet Specialties /
   trade — keep it simple and data-driven so later epics read it.
6. **Casual inputs, big consequences** (§32.1). One card click nudges both a bar and a long-term identity.

---

## 3. Core Concepts

### 3.1 Sentience Progress
`0–100`, shown during **Complex Life**. Each sentience intervention raises it. At **100** → **Tool Use**
milestone (milestone-only this epic; Tool Use gameplay is a future epic). Distinct from Life Progress
(biological maturity) and cell count.

### 3.2 Tendencies (the Trait foundation)
A profile map of points per tendency, raised by sentience interventions:

```text
Cooperative · Curious · Adaptive · Competitive · Strategic
```

(Later epics add Industrial / Diplomatic / Merchant / Secretive / Militarist from civilization-era
choices.) The **top 1–2 tendencies** form the player-facing **Civilization Identity** (e.g.
"Curious · Cooperative"). Full doctrine effects are deferred; Epic 7 only accumulates + displays them.

### 3.3 Sentience Interventions
New `category="Sentience"` definitions (vision §33.3 / §35.4). Each: cost Matter → `addSentienceProgress`
+ `addTendency` (+ optional small `addStability` tradeoff). Examples below.

---

## 4. Data Model (additive)

### 4.1 Player profile (`PlayerManager.createProfile`)
```lua
profile.sentienceProgress = 0          -- 0–100
profile.tendencies = {                 -- points per tendency (additive)
    cooperative = 0, curious = 0, adaptive = 0, competitive = 0, strategic = 0,
}
profile.toolUseReached = false         -- set true at Sentience 100 (milestone flag)
```

### 4.2 `ConverterUpdate` payload (append)
```lua
sentienceProgress = profile.sentienceProgress,
sentienceProgressMax = 100,
tendencies = profile.tendencies,       -- table copy for the identity UI
complexLifeReached = <bool>,           -- gates the Sentience section
```

### 4.3 Planet attributes (mirror, for visuals/inspect)
```text
SentienceProgress · CivIdentity ("Curious · Cooperative" or "—")
```

### 4.4 `InterventionData` entries (new, `category = "Sentience"`, `state = "Active"`)
| id | cost | effects | tendency |
|---|---|---|---|
| `encourage_cooperation` | 30 | `addSentienceProgress=15`, `addStability=+5` | cooperative |
| `encourage_curiosity` | 30 | `addSentienceProgress=15`, `addStability=-5` | curious |
| `encourage_adaptability` | 30 | `addSentienceProgress=12`, `addStability=+8` | adaptive |
| `encourage_competition` | 30 | `addSentienceProgress=18`, `addStability=-8` | competitive |
| `nudge_problem_solving` | 35 | `addSentienceProgress=20` | strategic |

Requirements for all: `{ complexLife = true }` (i.e. Multicellular complete / Life Progress 100).
New effect keys handled server-side: `addSentienceProgress` (clamp 0–100), `addTendency = "<id>"`
(read from the definition's `tendency` field; +1 per apply, or a tunable weight).

> Balance intent (§20-style): a mix of ~6 interventions reaches Sentience 100; the *blend* the player
> chooses determines their identity. Tune constants in `InterventionData` after playtest.

---

## 5. Server Implementation (extends Epic 6's `onApplyIntervention`)

The existing handler already: looks up `InterventionData.get(id)`, checks `state=="Active"`,
requirements, cost, deducts Matter, applies effects, clamps, syncs planet, pushes updates. Epic 7 adds:

1. **Requirement key `complexLife`** in `interventionRequirementsMet`: true when the player's Multicellular
   path is complete (`MulticellularData.isComplete(profile.multicellularUpgrades)`) **or** `lifeProgress >= 100`.
2. **Effect keys** in the apply step: `addSentienceProgress` (clamp 0–100); `def.tendency` →
   `profile.tendencies[def.tendency] += 1`.
3. **Tool Use milestone:** when `sentienceProgress` reaches 100 and `not profile.toolUseReached`, set
   `profile.toolUseReached = true` and `planet:SetAttribute("EvolutionStage", "ToolUse")` (milestone only;
   no Tool Use gameplay yet — coordinate the stage string with Nova so it doesn't fight his stages).
4. **Identity:** compute the top-1/2 tendencies → `planet:SetAttribute("CivIdentity", ...)`.
5. Extend `fireConverterUpdate` payload (§4.2). No new remote — reuse `ApplyIntervention`.

---

## 6. Client UI

Mounted in the inspect panel **below** Ecosystem Interventions (which is below Cell Cultures), keeping
the hierarchy: `Life Interventions › Cell Cultures › Ecosystem Interventions › Sentience`. Either extend
`EcosystemInterventionUI` or add a sibling `SentienceUI.luau` (recommend a sibling for clarity; same
styling + remote pattern).

- **Gated:** hidden/locked until `complexLifeReached`. Locked copy: "Reach Complex Life (complete the
  Multicellular path) to guide sentience."
- **Sentience Progress bar** + **Civilization Identity** line (top tendencies, or "Emerging…").
- **Interactive cards** for the 5 sentience interventions (Available/Unaffordable/Maxed states), firing
  `ApplyIntervention`. Card meta shows cost + effect + the tendency it builds (e.g. "→ Curious").
- **Tool Use milestone** banner at Sentience 100 ("Tool Use awakened — your species shapes its world").
- Refreshes from `MatterUpdate` / `ConverterUpdate` (same as `EcosystemInterventionUI`).

---

## 7. Sprint Breakdown

| Sprint | Goal |
|---|---|
| **7A** Audit & align | Confirm the Epic 6 pipeline + Multicellular completion signal; agree the Complex Life gate + Tool Use stage string with Nova. No code. |
| **7B** Data foundation | `sentienceProgress` + `tendencies` + `toolUseReached` profile fields; `complexLifeReached` + payload additions; planet attrs. |
| **7C** Sentience interventions | Add the 5 `category="Sentience"` definitions; extend `onApplyIntervention` (requirement `complexLife`, effects `addSentienceProgress`/`addTendency`, Tool Use milestone, identity). |
| **7D** Sentience UI | Gated section: Sentience bar + Civilization Identity + interactive cards. |
| **7E** Tool Use milestone + feedback | Milestone banner at 100 (no Tool Use systems); success feedback; optional light planet pulse. |
| **7F** Identity surfacing | Show Civilization Identity in the inspect info panel (reads `CivIdentity` attribute). |
| **7G** QA / docs / handoff | Regression (cells/organelles/Multicellular/ecosystem unchanged), tune constants, update docs. |

(Optional stretch, defer if large: one Complex Life **event** — *Predator Explosion* (§39.2) — reusing
the same effect keys. Mirrors Epic 6's deferred Mass Algae Bloom.)

---

## 8. Out Of Scope (future epics)

Tool Use / Civilization gameplay, **Civilization Projects** (§36), full **Doctrine effects** (tendencies
only *accumulate + display* here), Technology / Industry / Culture stats, DataStore/saving, offline
progression, and all multiplayer (contacts, **Interstellar Marketplace** §52, **Planet Specialties** §51,
probes, trade, war). Epic 7 deliberately leaves tendencies as clean data those systems will read.

---

## 9. Testing Plan

1. **Gate:** before Multicellular complete, the Sentience section is locked. Complete the Multicellular
   path (or hit Life Progress 100) → it unlocks.
2. **Each intervention:** Matter drops by cost; Sentience Progress rises by the effect; the matching
   tendency increments; the Civilization Identity line updates; Stability tradeoffs apply + clamp.
3. **Server authority:** unknown id / not Complex Life / not enough Matter → rejected, no state change.
4. **Milestone:** at Sentience 100, the Tool Use banner shows and the stage flips once (idempotent).
5. **Regression:** cells / organelles / Multicellular / Ecosystem interventions / Biosphere View all
   unchanged; inspect panel still scrolls; no duplicate UI on re-inspect.
6. **Multiplayer safety:** interventions affect only the player's own planet.

---

## 10. Coordination Notes (Nova)

- Epic 7 extends the **shared** `PlayerManager` profile + `ConverterUpdate` payload + reuses
  `ApplyIntervention` — additive, like Epic 6. Expect a merge-union on those files.
- **Complex Life gate + Tool Use stage string** must be agreed (Ticket 7.7 / 7A): does Complex Life key
  off `MulticellularData.isComplete`, or a Life Progress threshold, or both? Does setting
  `EvolutionStage="ToolUse"` fight any Nova stage logic? Decide before 7C.
- Don't edit `BiosphereView` / `CellInterventionUI` / `OrganelleData` / `MulticellularData` / `Pricing`
  without coordinating.

---

## 11. Definition Of Done

- Profile has `sentienceProgress` + `tendencies`; both ride `ConverterUpdate` + mirror to planet attrs.
- The 5 sentience interventions are live and server-authoritative, gated to Complex Life.
- Applying one raises Sentience Progress + the right tendency; Civilization Identity updates.
- Sentience 100 shows the Tool Use milestone (no duplicate evolution path).
- UI is gated, readable, and consistent with the inspect panel; states (locked/unaffordable/maxed) work.
- Cells / organelles / Multicellular / Ecosystem / Biosphere all still work.
- Docs + handoff updated; tendencies left as clean data for Doctrine / Specialties / trade later.

---

## 12. Why This Is The Right Next Epic

It continues the vision's near-term chain exactly (§29, §45, §35.4), reuses the Epic 5/6 framework with
near-zero new infrastructure, and — most importantly — stands up the **Tendency/Identity** system that
the entire mid/late game (Doctrine, the new V2 **Planet Specialties** §51 and **Interstellar Marketplace**
§52, diplomacy, war) is built on. Small to ship, foundational for everything after.

---

# Implementation — Epic 7 MVP (2026-06-20, Tien + Claude)

Built additively on the Epic 5/6 pipeline; Nova's cell/organelle/Multicellular lane untouched.

**Shipped (7B–7F):**
- **`InterventionData`**: 5 `category="Sentience"` interventions (`encourage_cooperation` 30→Sentience +15/Stab +5 `cooperative`; `encourage_curiosity` 30→+15/−5 `curious`; `encourage_adaptability` 30→+12/+8 `adaptive`; `encourage_competition` 30→+18/−8 `competitive`; `nudge_problem_solving` 35→+20 `strategic`), each `requirements={complexLife=true}`. New `getActiveByCategory`/`getSentienceActive`; `effectSummary` handles `addSentienceProgress`.
- **`PlayerManager`**: profile `sentienceProgress`/`tendencies`/`toolUseReached`; `complexLifeReached(profile)` = Multicellular complete **or** Life Progress 100; `civIdentity(profile)` = top-2 tendencies; `onApplyIntervention` extended (requirement `complexLife`; effects `addSentienceProgress` clamp 0–100 + `def.tendency` +1; Tool Use milestone at 100 → `EvolutionStage="ToolUse"` once; planet attrs `SentienceProgress`/`CivIdentity`). `ConverterUpdate` carries `sentienceProgress`/`sentienceProgressMax`/`tendencies`/`complexLifeReached`. **Reuses the `ApplyIntervention` remote** — none added.
- **`SentienceUI.luau`** (new): gated section below Ecosystem — Sentience bar + Civilization Identity + interactive cards + Tool Use milestone; mounted by `PlanetInteraction` (`layoutOrder=40`).

**Deferred:** the optional Complex Life event (Predator Explosion); full Tool Use/Doctrine systems (tendencies only accumulate + display).

**Coordination (Nova):** extends shared `PlayerManager`/`ConverterUpdate` (additive); the Complex Life gate keys off `MulticellularData.isComplete`, and Sentience 100 sets `EvolutionStage="ToolUse"` — confirm that doesn't fight his stage logic.

**Test:** complete the Multicellular path → Sentience section unlocks → apply interventions (Matter drops, Sentience bar rises, identity updates, Stability tradeoffs clamp) → at 100 the Tool Use milestone shows. Cells/organelles/ecosystem unchanged.

**Status:** 7B–7F ✅ (pending in-Studio playtest); optional event deferred.
