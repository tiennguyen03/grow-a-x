# Claude Fix Request — Update Epic 7 To Match Latest Game Vision

**Project:** Grow A [X]  
**Target file to update:** `Epic7.md`  
**Vision source:** `GameplayProgressionVision_UPDATED_V3.md`  
**Purpose:** Fix the gaps in the current Epic 7 plan so it matches the newer game direction discussed after the previous V2 rewrite.

---

## 0. Context

The current `Epic7.md` is a solid shippable MVP for **Sentience Progress & Civilization Tendencies**, but it is still framed too narrowly around:

```text
Cell Cultures
→ Ecosystem Interventions
→ Sentience
→ Tool Use
```

That is technically useful, but the latest vision has moved wider.

The game is **not** a cell game. Cells are only the opening origin/prologue. The real game is:

```text
Start as life
→ develop a species / race
→ shape that species into a civilization
→ progress through a decimal Kardashev rating
→ unlock technology, trade, diplomacy, probes, war, stealth, and cosmic-scale survival
```

Epic 7 should still be implementable and scoped, but it must now communicate that this is the first true **species / civilization direction** epic, not just another biology panel.

---

## 1. High-Level Problem With Current Epic 7

The current plan is too focused on a Sentience bar and five repeatable intervention cards. It works as code, but it does not fully reflect the updated strategic vision.

Current missing pieces:

```text
1. No K-Rating / decimal Kardashev rating connection.
2. Too much UI emphasis on Cell Cultures → Ecosystem → Sentience stacking.
3. Sentience is framed as the whole epic instead of the bridge into race/civilization identity.
4. Starting planet influence is missing.
5. The five sentience interventions are too flat; they need to be framed as branches of a World Direction Tree.
6. Tendencies do not clearly bridge into Species Identity and later Civilization Doctrine.
7. Cosmic Cycle compatibility is not mentioned.
8. The epic title/framing should reflect “Species Direction,” not only “Sentience Progress.”
```

---

## 2. Required Rename / Reframe

Rename or reframe the epic from:

```text
Epic 7 — Complex Life: Sentience Progress & Civilization Tendencies
```

to something closer to:

```text
Epic 7 — Complex Life & Species Direction
```

or:

```text
Epic 7 — Emerging Species, Sentience, and Civilization Tendencies
```

Preferred title:

```text
Epic 7 — Complex Life & Species Direction
```

Reason: The player fantasy is not “fill another biology bar.” The player fantasy is:

```text
My world is developing a race with a future identity.
```

---

## 3. Add Kardashev / K-Rating Mapping

Epic 7 must mention the **decimal Kardashev rating** system.

Add a section such as:

```md
## K-Rating Connection

Epic 7 lives around the K0.45–K0.70 band.

- K0.45 — Complex Life emerges.
- K0.55 — Emerging Sentience becomes visible.
- K0.60 — Species Direction choices begin meaningfully shaping identity.
- K0.70 — Tool Use milestone unlocks.

K-Rating is the player's civilization advancement rating. Sentience Progress does not replace K-Rating; it helps push the player from Complex Life toward Tool Use.
```

Suggested UI copy:

```text
K-Rating: K0.58
Era: Complex Life
Next Milestone: Tool Use at K0.70
Species Identity: Curious · Cooperative
```

Implementation note:

- For MVP, K-Rating can be display-only or derived from milestones.
- If no K-Rating system exists yet, add a placeholder field / future hook rather than forcing full implementation.
- Do **not** block Epic 7 on full Kardashev math.

Minimum design expectation:

```text
Epic 7 should name where it sits on the Kardashev progression scale.
```

---

## 4. Replace Cluttered UI Hierarchy With World Overview + World Direction

The current doc says the Sentience UI is mounted below:

```text
Life Interventions › Cell Cultures › Ecosystem Interventions › Sentience
```

This is the exact clutter problem from the current inspect menu.

Update the UI direction to prioritize:

```text
1. World Overview
2. Current Goal / Next Milestone
3. World Direction Tree
4. Biology Details collapsed below
```

Recommended inspect hierarchy:

```text
PEPPERROCKET's World
K-Rating: K0.58
Era: Complex Life
Next Milestone: Tool Use
Species Identity: Emerging / Curious · Cooperative

World Direction
Choose how your species develops:
[Cooperation Branch]
[Curiosity Branch]
[Adaptation Branch]
[Competition Branch]
[Problem Solving Branch]

Biology Details
Cell Cultures / Ecosystem / Life Progress / Stability
```

Important rule:

```text
Cells should become detail/supporting information once the player is past the cell origin phase.
The main panel should focus on what the race/world is becoming.
```

Do not delete Nova's cell UI in this epic, but the doc should clearly state that future UI should not keep cells as the dominant menu forever.

---

## 5. Convert Five Sentience Cards Into World Direction Branches

The current five interventions are fine for MVP:

```text
Encourage Cooperation
Encourage Curiosity
Encourage Adaptability
Encourage Competition
Nudge Problem Solving
```

But they need to be framed as branches of the **World Direction Tree**, not just flat buttons.

Add a section:

```md
## World Direction Tree — Complex Life Branches

Epic 7 is the first version of the World Direction Tree. In this era, the branches represent what kind of species is emerging.
```

Suggested branches:

### Cooperation Branch

```text
Encourage Cooperation
→ Social Bonds
→ Shared Survival
```

Long-term path:

```text
Cooperative Species
→ stable society
→ diplomacy bonuses
→ trade trust
→ alliance / protection pact synergy
```

### Curiosity Branch

```text
Encourage Curiosity
→ Pattern Recognition
→ Experimental Instinct
```

Long-term path:

```text
Curious Species
→ science bias
→ observatory/scanner bonuses
→ probe / research advantages
```

### Adaptation Branch

```text
Encourage Adaptability
→ Harsh Climate Survival
→ Recovery Instinct
```

Long-term path:

```text
Adaptive Species
→ disaster recovery
→ offline resilience
→ survival / stealth / volatile world synergy
```

### Competition Branch

```text
Encourage Competition
→ Rival Instincts
→ Predator Strategy
```

Long-term path:

```text
Competitive Species
→ defense / war bias
→ stronger militarist projects
→ lower trust unless balanced later
```

### Problem Solving Branch

```text
Nudge Problem Solving
→ Tool Curiosity
→ Early Engineering Bias
```

Long-term path:

```text
Strategic Species
→ faster project completion
→ industry / engineering / probe systems later
```

MVP can still ship only one node per branch, but the doc should show that the branch can expand later.

---

## 6. Add Starting Planet Influence Hooks

The current Epic 7 does not mention starting planet identity enough.

Add a section:

```md
## Starting Planet Influence

Starting planets should softly influence Species Direction choices. They should not hard-lock the player, but they should make certain paths feel natural.
```

Examples:

### Ocean World

```text
Better synergy with Cooperation, Stability, Biodiversity, and later diplomacy/trade reliability.
```

Possible effect later:

```text
+1 bonus tendency point after repeated Cooperation/Stability choices
or lower Matter cost for stable/cooperative branch nodes.
```

### Volcanic World

```text
Better synergy with Adaptability, Competition, mutation pressure, and risky evolution.
```

Possible effect later:

```text
Adaptation/Competition choices are stronger but carry slightly more Stability risk.
```

### Mineral-Rich World

```text
Better synergy with Strategic / Problem Solving and later Industry / Defense.
```

Possible effect later:

```text
Problem Solving branch gives early engineering bias that later reduces Industrial/Defense project costs.
```

### Temperate World

```text
Flexible and forgiving. No extreme bonuses, but better hybrid identity stability.
```

### Crystal / Exotic World

```text
Better synergy with Curiosity, scanning, signal interpretation, and later information-broker roles.
```

Important implementation note:

```text
Epic 7 does not need to fully implement planet archetype modifiers if Planet Identity is a later epic.
But Epic 7 should leave clean hooks so tendencies can later be weighted by planet archetype.
```

Suggested future hook:

```lua
-- future hook, not required for MVP
PlanetArchetypeModifiers = {
    Ocean = { cooperative = 1.1, adaptive = 0.95 },
    Volcanic = { adaptive = 1.15, competitive = 1.1, stabilityRisk = 1.1 },
    Mineral = { strategic = 1.1, competitive = 1.05 },
    Temperate = { hybridIdentityBonus = true },
    Crystal = { curious = 1.15, strategic = 1.05 },
}
```

---

## 7. Define Species Identity → Doctrine Bridge

The current doc says tendencies become a player-facing identity, but it should more clearly define the bridge to later doctrine.

Add a section:

```md
## Species Identity To Civilization Doctrine Bridge

Epic 7 does not implement full Doctrine. It creates the early Species Identity that Doctrine will later read.
```

Flow:

```text
Complex Life choices
→ tendency points
→ Species Identity at Tool Use
→ Civilization Projects reinforce or rebalance identity
→ K1 era formalizes Doctrine
```

Examples:

```text
Curious + Cooperative
= Emerging Species Identity: Curious Cooperative
Later if reinforced by observatories, scholars, and diplomacy:
= Doctrine: Scientific Diplomat
```

```text
Competitive + Strategic
= Emerging Species Identity: Strategic Rival
Later if reinforced by defense and industry:
= Doctrine: Militarized Industry
```

```text
Adaptive + Secretive later
= Emerging Species Identity: Adaptive Survivor
Later if reinforced by signal discipline:
= Doctrine: Silent Survivor / Isolationist Survivor
```

Important:

```text
Tendencies are not punishments.
They are pressure/history.
Later projects and events can rebalance them.
```

---

## 8. Add Cosmic Cycle Compatibility

Epic 7 does not need to fully implement Cosmic Cycles, but it should avoid designing itself into click-spam.

Add a section:

```md
## Cosmic Cycle Compatibility

For Epic 7 MVP, Sentience interventions are immediate Matter spends through ApplyIntervention.
However, the design should remain compatible with future Cosmic Cycles.
```

Future evolution:

```text
World Direction choices can become active focuses.
A focus may resolve every Cosmic Cycle.
Example: Encourage Curiosity active for 3 cycles, each cycle adds Sentience Progress and Curious tendency.
```

Do not implement this now unless already easy.

But add design warning:

```text
Do not make Complex Life progression feel like button spam.
The MVP can use cards, but the long-term design should support cycle-resolved focuses, cooldowns, or limited active direction slots.
```

Suggested limited slot model:

```text
Complex Life Era:
World Direction Focus: 1 active
Optional instant interventions: small supporting actions
```

---

## 9. Update Data Model Notes

Current fields are fine:

```lua
sentienceProgress
tendencies
toolUseReached
```

Add optional/future fields or notes:

```lua
kRating = 0.45 -- future/derived, not required if global system not ready
speciesIdentity = "Emerging" -- can be derived from tendencies
activeWorldDirectionFocus = nil -- future Cosmic Cycle hook
```

Do not force full implementation unless the codebase already supports it.

Minimum for this epic:

```text
Use top tendencies to surface Species Identity / Civilization Identity.
Name the Kardashev range this epic represents.
```

---

## 10. Update Acceptance Criteria

Add to Definition of Done:

```text
- Epic 7 doc clearly frames the feature as Species Direction, not just Sentience Progress.
- The epic identifies its K-Rating range: roughly K0.45–K0.70.
- UI plan prioritizes World Overview + World Direction over stacking Cell/Ecosystem/Sentience panels forever.
- Sentience interventions are documented as branches of the World Direction Tree.
- Starting planet influence is documented as a future hook / soft modifier.
- Species Identity → Civilization Doctrine bridge is explained.
- The design remains compatible with future Cosmic Cycles and limited active focus slots.
```

---

## 11. Keep These Constraints

Do not blow up scope.

Still out of scope for Epic 7 implementation:

```text
Full Tool Use gameplay
Full Doctrine effects
Civilization Projects
Planet Identity implementation
K-Rating global formula
DataStore/offline progression
Marketplace/trade/probes/war
Full Cosmic Cycle system
```

But the doc must point to these systems correctly so the implementation does not feel like an isolated biology feature.

The MVP can remain small:

```text
Sentience Progress
Tendency points
Species Identity display
Tool Use milestone
World Direction framing
K-Rating range display or placeholder
```

---

## 12. Suggested Patch Summary For Epic7.md

Make these edits:

```text
1. Rename title to Epic 7 — Complex Life & Species Direction.
2. Rewrite executive summary to say this is the first World Direction Tree / species identity epic.
3. Add K-Rating section: K0.45–K0.70, Tool Use at K0.70.
4. Rename “Sentience Interventions” framing to “Complex Life World Direction Branches.”
5. Add branch tree examples for Cooperation / Curiosity / Adaptation / Competition / Problem Solving.
6. Update UI section to prioritize World Overview + World Direction and collapse Biology Details.
7. Add Starting Planet Influence section.
8. Add Species Identity → Doctrine Bridge section.
9. Add Cosmic Cycle Compatibility section.
10. Update Definition of Done with the new vision alignment checks.
```

---

## 13. Final Intended Player Feeling

After Epic 7, the player should not feel:

```text
I filled another bar after cells.
```

They should feel:

```text
My world is developing a race.
That race has a direction.
My choices are shaping whether they become cooperative, curious, adaptive, competitive, or strategic.
This will matter when they become a civilization.
```

That is the key fix.
