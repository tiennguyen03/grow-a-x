# Epic 7 — Complex Life & Species Direction

**Project:** Grow A [X]
**Epic Type:** Core Gameplay Progression / Species-Direction & Civilization-Identity Foundation
**Status:** 📋 Reframed to V3 vision (MVP built — see Implementation log). Forward-looking sections (K-Rating, World Direction Tree, planet influence, doctrine bridge) are design hooks, not all implemented.
**Primary owner:** Tien (intervention/UI/direction layer), with Nova coordination for the cell/Multicellular gate + shared economy files.
**Authored:** 2026-06-20 (Claude, from `GameplayProgressionVision_UPDATED_V2.md` §33/§35/§40).
**Reframed:** 2026-06-20 (Claude, from `GameplayProgressionVision_UPDATED_V3.md` + `Claude_Epic7_Fix_Request.md`). Prior version archived at `docs/PastEpics/Epic7.2026-06-20.md`; fix request at `docs/PastEpics/Epic7-V3-FixRequest.2026-06-20.md`.

---

## 0. Executive Summary

**This is the first true Species Direction epic — the opening of the World Direction Tree — not just another biology bar.** Cells were the origin/prologue; from here the game is about a *race with a future identity*.

Epic 6 gave the planet its first planet-level strategy: **Life Progress** and **Stability** (Nourish / Stabilize / Accelerate). Epic 7 is the next era of that chain — the bridge from biology to a **developing species and its civilization identity**.

Once life matures (Multicellular complete / Life Progress maxed), the planet enters **Complex Life** (around **K0.45** on the decimal Kardashev scale). Here the player stops only asking *"how fast does life grow?"* and starts asking the vision's central question:

```text
What KIND of species — and eventually civilization — am I creating?
```

Epic 7 introduces:

- **Sentience Progress** (0–100) — how close the dominant life is to tool use. It does **not** replace K-Rating; it pushes the player from Complex Life (K0.45) toward the **Tool Use** milestone (K0.70).
- **World Direction (Complex Life branches)** — the first version of the World Direction Tree. Five branches (Cooperation / Curiosity / Adaptation / Competition / Problem Solving) each spend Matter to raise Sentience Progress **and** push a long-term **tendency**. The MVP ships one node per branch; the tree can expand later.
- **Species Identity / Civilization Tendencies** — the foundational trait system. Early choices accumulate tendency points that surface as an **emerging Species Identity** (e.g. "Curious · Cooperative"). This is the seed for **Civilization Doctrine**, Planet Specialties (V2 §51), trade, and diplomacy in later epics.

**Built entirely on the Epic 5/6 framework** — new `InterventionData` entries + a few effect keys + new profile fields, applied through the existing server-authoritative `ApplyIntervention` pipeline. No new economy framework, no duplication of Nova's cell/organelle/Multicellular lane.

This epic does **not** build Tool Use gameplay, full Doctrine effects, Civilization Projects, Planet Identity modifiers, the global K-Rating formula, Cosmic Cycles, DataStore, or any multiplayer/contact/trade. It establishes Sentience + Species Direction + Tendencies + the Tool Use milestone, and **leaves clean hooks** so those later systems read it correctly.

---

## 1. K-Rating Connection

Epic 7 lives around the **K0.45–K0.70** band of the decimal Kardashev rating (the player's civilization-advancement rating).

- **K0.45** — Complex Life emerges (Sentience section unlocks).
- **K0.55** — Emerging Sentience becomes visible (identity starts forming).
- **K0.60** — Species Direction choices begin meaningfully shaping identity.
- **K0.70** — **Tool Use** milestone unlocks.

K-Rating is the player's civilization advancement rating; **Sentience Progress does not replace it** — it helps push the player from Complex Life toward Tool Use.

Suggested UI copy:

```text
K-Rating: K0.58
Era: Complex Life
Next Milestone: Tool Use at K0.70
Species Identity: Curious · Cooperative
```

**Implementation note (do NOT block Epic 7 on full Kardashev math):**
- For MVP, K-Rating can be **display-only or derived from milestones** (e.g. map Sentience Progress 0→100 across the K0.45→K0.70 band).
- If no global K-Rating system exists yet, add a **placeholder field / future hook** rather than forcing full implementation.
- Minimum design expectation: **the epic names where it sits on the Kardashev scale (K0.45–K0.70).**

---

## 2. Relationship To Existing Systems

| System (in `main`) | Epic 7 relationship |
|---|---|
| **Epic 6 ecosystem** (`InterventionData`, `EcosystemInterventionUI`, `onApplyIntervention`, `lifeProgress`/`stability`) | **Extends it.** New `category="Sentience"` interventions + effect keys; same pipeline + UI patterns. |
| **Nova's cells / organelles / 8C–8E** | Untouched. Sentience/Species Direction is planet-level, never touches cells. |
| **Nova's Multicellular Path (1C, `MulticellularData`)** | **Gate point.** Complex Life unlocks when the Multicellular path is complete (or Life Progress 100) — coordinate with Nova. No second multicellular path. |
| **`PlanetStageVisuals` / `BiosphereView`** | Read new attributes for light feedback; BiosphereView is Nova-owned (coordinate, optional). |

**Design rule (carried from Epic 6):** integrate with Nova, never duplicate. Species Direction is purely additive to the shared `PlayerManager` / `Remotes` / `ConverterUpdate`.

---

## 3. Design Pillars

1. **One question per era.** Epic 6 = "grow life safely or fast?" Epic 7 = "**what kind of species emerges, and where is it headed?**"
2. **The world is becoming a race, not filling a bar.** The panel should foreground *what the species is becoming*; cells/biology become supporting detail once past the origin phase.
3. **Choices create tendencies, not punishment.** Tendencies are pressure/history, not dead ends; hybrid identities are good and later projects/events can rebalance them.
4. **Server authority.** All Species Direction spends go through `ApplyIntervention`; the server owns Sentience Progress + tendency totals.
5. **Reveal stats only when usable.** Sentience Progress, Species Identity, and World Direction appear at Complex Life, not before.
6. **Small now, foundational later.** Tendencies are the seed for Doctrine / Planet Specialties / trade — keep them simple, data-driven, branch-shaped so later epics expand them.
7. **Casual inputs, big consequences.** One direction choice nudges both a bar and a long-term identity.
8. **Don't design into click-spam.** MVP uses cards, but the framing must stay compatible with future Cosmic-Cycle-resolved focuses / limited active direction slots (see §11).

---

## 4. Core Concepts

### 4.1 Sentience Progress
`0–100`, shown during **Complex Life**. Each World Direction choice raises it. At **100** → **Tool Use** milestone (K0.70; milestone-only this epic — Tool Use gameplay is a future epic). Distinct from Life Progress (biological maturity) and cell count. For MVP, K-Rating can be derived from this across the K0.45–K0.70 band.

### 4.2 Tendencies (the Trait foundation)
A profile map of points per tendency, raised by World Direction choices:

```text
Cooperative · Curious · Adaptive · Competitive · Strategic
```

(Later epics add Industrial / Diplomatic / Merchant / Secretive / Militarist from civilization-era choices.) The **top 1–2 tendencies** form the player-facing **Species Identity** (e.g. "Curious · Cooperative"), which later becomes **Civilization Doctrine** (see §10). Full doctrine effects are deferred; Epic 7 only accumulates + displays them.

### 4.3 World Direction choices (the branches)
New `category="Sentience"` definitions. Each: cost Matter → `addSentienceProgress` + `addTendency` (+ optional small `addStability` tradeoff). Framed as **branches of the World Direction Tree** (§5), not flat buttons.

---

## 5. World Direction Tree — Complex Life Branches

Epic 7 is the **first version of the World Direction Tree.** In this era, the branches represent what kind of species is emerging. The MVP ships **one node per branch**; the doc shows how each branch expands in later eras so the implementation never feels like an isolated biology feature.

### Cooperation Branch
```text
Encourage Cooperation → Social Bonds → Shared Survival
```
Long-term path:
```text
Cooperative Species → stable society → diplomacy bonuses → trade trust → alliance / protection-pact synergy
```

### Curiosity Branch
```text
Encourage Curiosity → Pattern Recognition → Experimental Instinct
```
Long-term path:
```text
Curious Species → science bias → observatory/scanner bonuses → probe / research advantages
```

### Adaptation Branch
```text
Encourage Adaptability → Harsh Climate Survival → Recovery Instinct
```
Long-term path:
```text
Adaptive Species → disaster recovery → offline resilience → survival / stealth / volatile-world synergy
```

### Competition Branch
```text
Encourage Competition → Rival Instincts → Predator Strategy
```
Long-term path:
```text
Competitive Species → defense / war bias → stronger militarist projects → lower trust unless balanced later
```

### Problem Solving Branch
```text
Nudge Problem Solving → Tool Curiosity → Early Engineering Bias
```
Long-term path:
```text
Strategic Species → faster project completion → industry / engineering / probe systems later
```

> **MVP:** one node per branch (the five interventions in §6.4). The branch structure is what later eras expand — don't flatten it back into a generic upgrade list.

---

## 6. Data Model (additive)

### 6.1 Player profile (`PlayerManager.createProfile`)
```lua
profile.sentienceProgress = 0          -- 0–100
profile.tendencies = {                 -- points per tendency (additive)
    cooperative = 0, curious = 0, adaptive = 0, competitive = 0, strategic = 0,
}
profile.toolUseReached = false         -- set true at Sentience 100 (milestone flag)
```

### 6.2 Optional / future fields (hooks, not required for MVP)
```lua
-- kRating: future/derived — for MVP can be computed from sentienceProgress across K0.45–K0.70,
-- or left nil until a global K-Rating system exists.
profile.kRating = 0.45
-- speciesIdentity: can be derived on the fly from top tendencies (no need to store).
profile.speciesIdentity = "Emerging"
-- activeWorldDirectionFocus: future Cosmic Cycle hook (see §11); nil in MVP.
profile.activeWorldDirectionFocus = nil
```
> Do not force full implementation of these unless the codebase already supports it. Minimum for this epic: use top tendencies to surface Species Identity, and name the Kardashev range.

### 6.3 `ConverterUpdate` payload (append)
```lua
sentienceProgress = profile.sentienceProgress,
sentienceProgressMax = 100,
tendencies = profile.tendencies,       -- table copy for the identity UI
complexLifeReached = <bool>,           -- gates the Species Direction section
-- optional: kRating = <derived>,
```

### 6.4 `InterventionData` entries (new, `category = "Sentience"`, `state = "Active"`)
Each is the **MVP node of its World Direction branch** (§5):

| id | branch | cost | effects | tendency |
|---|---|---|---|---|
| `encourage_cooperation` | Cooperation | 30 | `addSentienceProgress=15`, `addStability=+5` | cooperative |
| `encourage_curiosity` | Curiosity | 30 | `addSentienceProgress=15`, `addStability=-5` | curious |
| `encourage_adaptability` | Adaptation | 30 | `addSentienceProgress=12`, `addStability=+8` | adaptive |
| `encourage_competition` | Competition | 30 | `addSentienceProgress=18`, `addStability=-8` | competitive |
| `nudge_problem_solving` | Problem Solving | 35 | `addSentienceProgress=20` | strategic |

Requirements for all: `{ complexLife = true }` (Multicellular complete / Life Progress 100). New effect keys handled server-side: `addSentienceProgress` (clamp 0–100), `addTendency = "<id>"` (from the definition's `tendency` field; +1 per apply, or a tunable weight).

> Balance intent: a mix of ~6 choices reaches Sentience 100; the *blend* the player chooses determines their identity. Tune constants after playtest.

### 6.5 Planet attributes (mirror, for visuals/inspect)
```text
SentienceProgress · CivIdentity ("Curious · Cooperative" or "—")  [optional: KRating]
```

---

## 7. Server Implementation (extends Epic 6's `onApplyIntervention`)

The existing handler already looks up `InterventionData.get(id)`, checks `state=="Active"`, requirements, cost, deducts Matter, applies effects, clamps, syncs planet, pushes updates. Epic 7 adds:

1. **Requirement key `complexLife`** in `interventionRequirementsMet`: true when the Multicellular path is complete (`MulticellularData.isComplete(profile.multicellularUpgrades)`) **or** `lifeProgress >= 100`.
2. **Effect keys:** `addSentienceProgress` (clamp 0–100); `def.tendency` → `profile.tendencies[def.tendency] += 1`.
3. **Tool Use milestone:** when `sentienceProgress` reaches 100 and `not profile.toolUseReached`, set `profile.toolUseReached = true` and `planet:SetAttribute("EvolutionStage","ToolUse")` (milestone only; coordinate the stage string with Nova).
4. **Identity:** compute top-1/2 tendencies → `planet:SetAttribute("CivIdentity", ...)`.
5. Extend `fireConverterUpdate` payload (§6.3). No new remote — reuse `ApplyIntervention`.

---

## 8. Client UI — World Overview + World Direction first

The previous framing stacked `Life Interventions › Cell Cultures › Ecosystem Interventions › Sentience` in one column — the exact clutter problem the inspect panel had. **Prioritize what the world is *becoming* over biology stacking.**

**Recommended inspect priority:**
```text
1. World Overview          (name · K-Rating · Era · Next Milestone · Species Identity)
2. Current Goal / Next Milestone
3. World Direction         (the branch choices)
4. Biology Details         (Cell Cultures / Ecosystem / Life Progress / Stability) — collapsed/secondary
```

Example:
```text
PEPPERROCKET's World
K-Rating: K0.58   Era: Complex Life   Next Milestone: Tool Use
Species Identity: Emerging / Curious · Cooperative

World Direction — choose how your species develops:
  [Cooperation]  [Curiosity]  [Adaptation]  [Competition]  [Problem Solving]

Biology Details ▸  (Cell Cultures / Ecosystem / Life Progress / Stability)
```

**Rules:**
- **Cells become detail/supporting info** once the player is past the cell-origin phase. Do **not** delete Nova's cell UI in this epic, but future UI should not keep cells as the dominant menu forever.
- **Gated:** the Species Direction section is hidden/locked until `complexLifeReached`. Locked copy: "Reach Complex Life (complete the Multicellular path) to guide your species."
- **World Overview** line: name · K-Rating (display/derived) · Era · Next Milestone · Species Identity.
- **Sentience Progress bar** + **Species Identity** line (top tendencies, or "Emerging…").
- **Interactive branch cards** for the 5 choices (Available/Unaffordable/Maxed), firing `ApplyIntervention`. Card meta shows cost + effect + the tendency it builds (e.g. "→ Curious").
- **Tool Use milestone** banner at Sentience 100 ("Tool Use awakened — your species shapes its world").
- Refreshes from `MatterUpdate` / `ConverterUpdate`.

> **Tab note (post-inspect-redesign):** the inspect panel is now tabbed (Overview / Cells / Ecosystem / Sentience). To match this epic's framing, the **Sentience tab should read "World Direction"** and the Overview tab should surface K-Rating / Era / Next Milestone / Species Identity. (Light follow-up; see Implementation log.)

---

## 9. Starting Planet Influence

Starting planets should **softly** influence Species Direction — never hard-lock the player, but make certain paths feel natural. **Epic 7 does not need to implement archetype modifiers** (Planet Identity is a later epic); it should **leave clean hooks** so tendencies can later be weighted by archetype.

| Archetype | Natural synergy | Possible later effect |
|---|---|---|
| **Ocean** | Cooperation, Stability, Biodiversity, later diplomacy/trade reliability | +1 bonus tendency after repeated Cooperation/Stability; or lower Matter cost on cooperative/stable nodes |
| **Volcanic** | Adaptability, Competition, mutation pressure, risky evolution | Adaptation/Competition choices stronger but carry slightly more Stability risk |
| **Mineral-Rich** | Strategic / Problem Solving, later Industry / Defense | Problem-Solving branch grants early engineering bias → later reduces Industrial/Defense project costs |
| **Temperate** | Flexible / forgiving | No extreme bonuses, but better hybrid-identity stability |
| **Crystal / Exotic** | Curiosity, scanning, signal interpretation, later info-broker roles | Curiosity choices stronger; later information-broker synergy |

Suggested future hook (not required for MVP):
```lua
-- future hook, not required for MVP
PlanetArchetypeModifiers = {
    Ocean     = { cooperative = 1.1, adaptive = 0.95 },
    Volcanic  = { adaptive = 1.15, competitive = 1.1, stabilityRisk = 1.1 },
    Mineral   = { strategic = 1.1, competitive = 1.05 },
    Temperate = { hybridIdentityBonus = true },
    Crystal   = { curious = 1.15, strategic = 1.05 },
}
```

---

## 10. Species Identity → Civilization Doctrine Bridge

Epic 7 does **not** implement full Doctrine. It creates the early **Species Identity** that Doctrine will later read.

Flow:
```text
Complex Life choices → tendency points → Species Identity at Tool Use
→ Civilization Projects reinforce or rebalance identity → K1 era formalizes Doctrine
```

Examples:
```text
Curious + Cooperative   = Emerging Identity: Curious Cooperative
   → later reinforced by observatories/scholars/diplomacy = Doctrine: Scientific Diplomat

Competitive + Strategic = Emerging Identity: Strategic Rival
   → later reinforced by defense/industry               = Doctrine: Militarized Industry

Adaptive + (Secretive later) = Emerging Identity: Adaptive Survivor
   → later reinforced by signal discipline              = Doctrine: Silent / Isolationist Survivor
```

**Important:** tendencies are **not punishments** — they are pressure/history. Later projects and events can rebalance them.

---

## 11. Cosmic Cycle Compatibility

For Epic 7 MVP, World Direction choices are **immediate Matter spends through `ApplyIntervention`.** That's fine — but the design must stay compatible with future **Cosmic Cycles** and not bake in click-spam.

Future evolution (do **not** implement now unless trivial):
```text
World Direction choices can become active focuses.
A focus may resolve every Cosmic Cycle.
e.g. "Encourage Curiosity" active for 3 cycles → each cycle adds Sentience Progress + Curious tendency.
```

Suggested limited-slot model the MVP should not contradict:
```text
Complex Life Era:
  World Direction Focus: 1 active
  Optional instant interventions: small supporting actions
```

**Design warning:** do not make Complex Life progression feel like button spam. The MVP can use cards, but the long-term design should support cycle-resolved focuses, cooldowns, or limited active direction slots.

---

## 12. Sprint Breakdown

| Sprint | Goal |
|---|---|
| **7A** Audit & align | Confirm the Epic 6 pipeline + Multicellular completion signal; agree the Complex Life gate + Tool Use stage string with Nova. No code. |
| **7B** Data foundation | `sentienceProgress` + `tendencies` + `toolUseReached` profile fields; `complexLifeReached` + payload additions; planet attrs. |
| **7C** World Direction choices | Add the 5 `category="Sentience"` branch nodes; extend `onApplyIntervention` (requirement `complexLife`, effects `addSentienceProgress`/`addTendency`, Tool Use milestone, identity). |
| **7D** World Direction UI | Gated section: Sentience bar + Species Identity + interactive branch cards. |
| **7E** Tool Use milestone + feedback | Milestone banner at 100 (no Tool Use systems); success feedback; optional light planet pulse. |
| **7F** Identity surfacing | Show Species/Civilization Identity in the inspect Overview (reads `CivIdentity` attribute). |
| **7G** QA / docs / handoff | Regression (cells/organelles/Multicellular/ecosystem unchanged), tune constants, update docs. |
| **7H** (V3 follow-up, optional) | Reframe UI naming to **World Direction**; surface **K-Rating / Era / Next Milestone** on the Overview; verify branch framing reads as "species direction," not "another bar." |

(Optional stretch, defer if large: one Complex Life **event** — *Predator Explosion* — reusing the same effect keys. Mirrors Epic 6's deferred Mass Algae Bloom.)

---

## 13. Out Of Scope (future epics)

Still out of scope for Epic 7 implementation — but the doc must point to them so the feature isn't an isolated biology panel:

```text
Full Tool Use gameplay
Full Doctrine effects (tendencies only accumulate + display here)
Civilization Projects
Planet Identity / archetype modifier implementation
K-Rating global formula (MVP K-Rating is display-only / derived)
DataStore / offline progression
Marketplace / trade / probes / war / diplomacy
Full Cosmic Cycle system
```

Epic 7 deliberately leaves tendencies + branches + identity as clean data those systems will read.

---

## 14. Testing Plan

1. **Gate:** before Multicellular complete, the Species Direction section is locked. Complete the path (or hit Life Progress 100) → it unlocks (Complex Life, ~K0.45).
2. **Each branch choice:** Matter drops by cost; Sentience Progress rises by the effect; the matching tendency increments; the Species Identity line updates; Stability tradeoffs apply + clamp.
3. **Server authority:** unknown id / not Complex Life / not enough Matter → rejected, no state change.
4. **Milestone:** at Sentience 100, the Tool Use banner shows and the stage flips once (idempotent); K-Rating (if displayed) reads near K0.70.
5. **Regression:** cells / organelles / Multicellular / Ecosystem interventions / Biosphere View all unchanged; inspect panel still works; no duplicate UI on re-inspect.
6. **Multiplayer safety:** choices affect only the player's own planet.

---

## 15. Coordination Notes (Nova)

- Epic 7 extends the **shared** `PlayerManager` profile + `ConverterUpdate` payload + reuses `ApplyIntervention` — additive, like Epic 6. Expect a merge-union on those files.
- **Complex Life gate + Tool Use stage string** must be agreed: Complex Life keys off `MulticellularData.isComplete` (or a Life Progress threshold, or both); does `EvolutionStage="ToolUse"` fight any Nova stage logic? Decide before 7C.
- Don't edit `BiosphereView` / `CellInterventionUI` / `OrganelleData` / `MulticellularData` / `Pricing` without coordinating.

---

## 16. Definition Of Done

- Profile has `sentienceProgress` + `tendencies`; both ride `ConverterUpdate` + mirror to planet attrs.
- The 5 World Direction choices are live and server-authoritative, gated to Complex Life.
- Applying one raises Sentience Progress + the right tendency; Species Identity updates.
- Sentience 100 shows the Tool Use milestone (no duplicate evolution path).
- UI is gated, readable, consistent with the inspect panel; states (locked/unaffordable/maxed) work.
- Cells / organelles / Multicellular / Ecosystem / Biosphere all still work.
- Docs + handoff updated; tendencies left as clean data for Doctrine / Specialties / trade later.

**V3 vision-alignment checks (added):**
- The doc frames the feature as **Species Direction**, not just Sentience Progress.
- The epic identifies its **K-Rating range (~K0.45–K0.70)**, with Tool Use at K0.70.
- The UI plan prioritizes **World Overview + World Direction** over stacking Cell/Ecosystem/Sentience panels forever.
- The five interventions are documented as **branches of the World Direction Tree**.
- **Starting planet influence** is documented as a future hook / soft modifier.
- The **Species Identity → Civilization Doctrine** bridge is explained.
- The design stays **compatible with future Cosmic Cycles** and limited active focus slots.

---

## 17. Why This Is The Right Next Epic

It continues the vision's near-term chain exactly, reuses the Epic 5/6 framework with near-zero new infrastructure, and — most importantly — stands up the **Species Direction / Tendency / Identity** system that the entire mid/late game (Doctrine, Planet Specialties §51, Interstellar Marketplace §52, diplomacy, war) is built on. Small to ship, foundational for everything after.

---

## 18. Final Intended Player Feeling

After Epic 7, the player should **not** feel "I filled another bar after cells." They should feel:

```text
My world is developing a race.
That race has a direction.
My choices are shaping whether they become cooperative, curious, adaptive, competitive, or strategic.
This will matter when they become a civilization.
```

That is the key fix.

---

# Implementation — Epic 7 MVP (2026-06-20, Tien + Claude)

Built additively on the Epic 5/6 pipeline; Nova's cell/organelle/Multicellular lane untouched.

**Shipped (7B–7F):**
- **`InterventionData`**: 5 `category="Sentience"` interventions / World Direction branch nodes (`encourage_cooperation` 30→Sentience +15/Stab +5 `cooperative`; `encourage_curiosity` 30→+15/−5 `curious`; `encourage_adaptability` 30→+12/+8 `adaptive`; `encourage_competition` 30→+18/−8 `competitive`; `nudge_problem_solving` 35→+20 `strategic`), each `requirements={complexLife=true}`. New `getActiveByCategory`/`getSentienceActive`; `effectSummary` handles `addSentienceProgress`.
- **`PlayerManager`**: profile `sentienceProgress`/`tendencies`/`toolUseReached`; `complexLifeReached(profile)` = Multicellular complete **or** Life Progress 100; `civIdentity(profile)` = top-2 tendencies; `onApplyIntervention` extended (requirement `complexLife`; effects `addSentienceProgress` clamp 0–100 + `def.tendency` +1; Tool Use milestone at 100 → `EvolutionStage="ToolUse"` once; planet attrs `SentienceProgress`/`CivIdentity`). `ConverterUpdate` carries `sentienceProgress`/`sentienceProgressMax`/`tendencies`/`complexLifeReached`. **Reuses the `ApplyIntervention` remote** — none added.
- **`SentienceUI.luau`** (new): gated section — Sentience bar + Civilization/Species Identity + interactive cards + Tool Use milestone; mounted by `PlanetInteraction` (now in the **Sentience** tab of the redesigned inspect panel).

**Deferred:** the optional Complex Life event (Predator Explosion); full Tool Use/Doctrine systems (tendencies only accumulate + display).

**Coordination (Nova):** extends shared `PlayerManager`/`ConverterUpdate` (additive); the Complex Life gate keys off `MulticellularData.isComplete`, and Sentience 100 sets `EvolutionStage="ToolUse"` — confirm that doesn't fight his stage logic.

**Test:** complete the Multicellular path → Sentience section unlocks → apply choices (Matter drops, Sentience bar rises, identity updates, Stability tradeoffs clamp) → at 100 the Tool Use milestone shows. Cells/organelles/ecosystem unchanged.

**Polish (full DoD):** 7F — Identity now also surfaces in the top planet-info block (`rowCiv` reads `CivIdentity`). 7E — a brief bar pulse plays when Sentience Progress rises, plus the Tool Use milestone banner at 100.

## V3 reframe — follow-ups

The V3 reframe is documentation-level; the shipped MVP code satisfies the mechanical DoD. The visible UI-framing follow-up (**7H**) is now also shipped:

**Shipped (7H, 2026-06-20):**
- **Inspect "Sentience" tab → "World Direction"** (`PlanetInteraction`). `SentienceUI` header → "World Direction"; subtitle/locked copy reframed to species-direction; cards already show their tendency/branch (e.g. "→ Curious"); identity line → "Species Identity".
- **World Overview on the Overview tab** (`PlanetInteraction.updateInfoPanel`): **K-Rating · Era · Next Milestone · Species Identity** surfaced first, above planet identity/conditions. All **derived client-side** from mirrored attributes (`EvolutionStage`, `LifeProgress`/`LifeProgressMax`, `SentienceProgress`, `CivIdentity`) — no server change. K-Rating is display-only: Complex Life spans K0.45→K0.70 across Sentience Progress; Tool Use = K0.70.

**Still optional (not required to ship):**
- **Hooks only (no behavior yet):** add `kRating` / `speciesIdentity` / `activeWorldDirectionFocus` profile placeholders and a `PlanetArchetypeModifiers` stub for later Planet Identity weighting / Cosmic Cycle focuses.

**Status:** 7B–7H ✅ complete (pending in-Studio playtest sign-off + Nova gate confirmation). V3 reframe ✅ documented + UI-aligned.
