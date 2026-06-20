# Ecosystem Interventions Implementation Plan

**Project:** Grow A [X]  
**Plan Type:** UI / UX Clarification + Epic 5 → Epic 6 Bridge  
**Primary Goal:** Make Nova's current **Cell Cultures** system and Tien's **Future / Ecosystem Interventions** preview feel like one coherent biology progression pipeline instead of two disconnected upgrade menus.

---

## 0. Executive Summary

The current inspect panel is moving in the right direction:

```text
Inspect Origin World
→ Cell Cultures
→ Create / evolve cells
→ Future Interventions preview
```

But the current UI can read like two separate systems:

```text
Cell Cultures = one system
Future Interventions = another unrelated system
```

That is not the intended design.

The intended design is:

```text
Cell Cultures = microscopic life progression
Ecosystem Interventions = planet-level evolution strategy
```

These two systems should stay distinct, but they should be framed as two layers of the same early-life pipeline.

The immediate implementation should **not** add live Life Progress, Stability, generic purchase remotes, or a second upgrade pipeline. This is mainly a UI/copy/data cleanup pass that clarifies the relationship between the systems and prepares Epic 6.

---

## 1. Current Context

### 1.1 Existing Completed / Merged Systems

The game currently has:

```text
Fly through space
→ collect Matter
→ return to Origin World
→ inspect planet
→ create cells / Archaea
→ upgrade cells through organelles
→ evolve into Eukaryotic
→ Biosphere View visualizes the living system
```

The current inspect panel already includes:

- planet info,
- intervention area,
- Nova's Cell Cultures UI,
- read-only future intervention cards.

### 1.2 Nova's Current Lane

Nova's system handles:

- creating Archaea / cells,
- upgrading individual cells through organelles,
- Eukaryotic evolution,
- Eukaryotic cascade,
- dust multiplier,
- Biosphere View,
- future Multicellular Path work.

This is the **live biology/economy layer**.

Do not duplicate it.

### 1.3 Tien's Current Layer

Tien's Epic 5 additive layer added:

- generic `InterventionData`,
- read-only future cards,
- preview of upcoming Epic 6 interventions:
  - Nourish Microbes,
  - Stabilize Oceans,
  - Accelerate Mutation.

This is not a second economy system. It is a **preview of planet-level ecosystem strategy**.

---

## 2. Design Decision

### 2.1 Keep Both Systems

Do **not** remove Cell Cultures.

Do **not** remove Future Interventions.

Instead, clarify their roles:

```text
Cell Cultures
- What life exists?
- How many cells exist?
- How evolved are the cells?
- How much Matter do they produce?

Ecosystem Interventions
- What planet conditions support that life?
- Is the environment stable?
- Is evolution being pushed safely or aggressively?
- How does the planet move toward the next era?
```

### 2.2 Rename `Future Interventions`

The phrase **Future Interventions** is useful for development, but it is weak for player-facing UI.

It makes the section feel detached.

Rename it to:

```text
Ecosystem Interventions
```

Optional badge:

```text
Coming Soon · Epic 6
```

For internal/dev builds, the Epic label is okay.

For a public build, use only:

```text
Coming Soon
```

### 2.3 Add Bridge Copy

Under the `Ecosystem Interventions` header, add one sentence:

```text
Shape the planet conditions around your cells. These interventions will guide Life Progress and Stability in Epic 6.
```

Or a shorter player-facing version:

```text
Shape the world around your cells so life can grow, stabilize, and evolve.
```

This single line solves most of the confusion.

---

## 3. Target UI Hierarchy

### 3.1 Current Rough Structure

Current panel reads like:

```text
Intervention

Cell Cultures
Production 0.0/s  Dust Value ×1
[Create Archaea Cell]

Future Interventions
[Nourish Microbes]
[Stabilize Oceans]
[Accelerate Mutation]
```

### 3.2 Desired Structure

Target panel should read like:

```text
Life Interventions

Cell Cultures
Create and evolve cells. Cells generate Matter and unlock new life stages.
Production 0.0/s  Dust Value ×1
[Create Archaea Cell]

Ecosystem Interventions
Coming Soon · Epic 6
Shape the world around your cells so life can grow, stabilize, and evolve.

[Nourish Microbes]
[Stabilize Oceans]
[Accelerate Mutation]
```

### 3.3 Why This Works

This makes the hierarchy clear:

```text
Life Interventions
├── Cell Cultures
│   └── live microscopic progression
└── Ecosystem Interventions
    └── future planet-level strategy
```

The player understands:

```text
I create cells first.
Cells create life and Matter production.
Later I will guide the ecosystem around those cells.
```

---

## 4. Player-Facing Meaning Of Each Section

## 4.1 Life Interventions

This is the parent category.

It means:

```text
Everything in this section affects early life on the Origin World.
```

It should include both:

- Cell Cultures,
- Ecosystem Interventions.

Do not use `Upgrade Shop` language.

Use:

```text
Intervention
Life Interventions
Cell Cultures
Ecosystem Interventions
```

Avoid:

```text
Shop
Boosts
Buy upgrades
Generic multipliers
```

---

## 4.2 Cell Cultures

**Role:** microscopic life progression.

Player-facing meaning:

```text
Grow and evolve the first living cells on your world.
```

System meaning:

```text
Create cells
→ upgrade organelles
→ evolve cells
→ increase Matter production
→ unlock biological milestones
```

Recommended subtitle:

```text
Create and evolve cells. Cells generate Matter and unlock new life stages.
```

Shorter alternative:

```text
Grow the first cells living on your Origin World.
```

This section should remain the live interactive system Nova owns.

---

## 4.3 Ecosystem Interventions

**Role:** planet-level support and strategic direction around the cells.

Player-facing meaning:

```text
Shape the planet conditions around your cells so life can grow, stabilize, and evolve.
```

System meaning:

```text
Spend Matter
→ change Life Progress / Stability
→ influence evolution speed and risk
→ prepare for Multicellular Life and later complexity
```

This section should be preview-only for now.

No buttons yet.

No spend yet.

No remotes yet.

No `LifeProgress` / `Stability` implementation yet unless Epic 6 begins.

---

# 5. Detailed Card Copy

## 5.1 Nourish Microbes

### Current Design Role

This is the safe growth action.

It should teach:

```text
Matter can support life directly.
```

### Player-Facing Card

```text
Nourish Microbes
Coming Soon · Epic 6
Cost: 20 Matter · Life Progress +20
Feed fragile ecosystems with patient nutrients so early life can spread.
```

### Meaning

The player spends Matter to support early microbial life.

This should be the safest, clearest first ecosystem intervention.

### Future Live Effect

```text
LifeProgress += 20
```

No downside.

### Relationship To Cell Cultures

Cell Cultures create and evolve the actual cells.

Nourish Microbes supports the broader biosphere those cells live inside.

### Future Design Notes

When live, this can be repeatable until a Life Progress threshold is reached.

Possible future requirement:

```text
Requires EvolutionStage >= Archaea
```

---

## 5.2 Stabilize Oceans

### Current Design Role

This is the defensive / safe ecology option.

It should teach:

```text
Evolution depends on stable conditions.
```

### Player-Facing Card

```text
Stabilize Oceans
Coming Soon · Epic 6
Cost: 25 Matter · Stability +15
Calm the planet's oceans so fragile cells can survive and multiply.
```

### Meaning

The player spends Matter to improve the environment instead of rushing growth.

### Future Live Effect

```text
Stability += 15
```

### Relationship To Cell Cultures

As Cell Cultures become more advanced, ecosystem instability can become a risk.

Stabilize Oceans protects the world from risky evolution choices or biological events.

### Future Design Notes

This is the first step toward the Stability stat mattering.

Stability should eventually affect:

- extinction-event risk,
- mutation downsides,
- early ecosystem events,
- later civilization unrest,
- offline safety.

---

## 5.3 Accelerate Mutation

### Current Design Role

This is the first risky strategic choice.

It should teach:

```text
Fast progress has consequences.
```

### Player-Facing Card

```text
Accelerate Mutation
Coming Soon · Epic 6
Cost: 25 Matter · Life Progress +35 · Stability -10
Force rapid adaptation. Evolution moves faster, but the ecosystem becomes less stable.
```

### Meaning

The player spends Matter to push life forward faster, but destabilizes the ecosystem.

### Future Live Effect

```text
LifeProgress += 35
Stability -= 10
```

### Relationship To Cell Cultures

This should not replace organelle upgrades.

Instead, it supports the bigger biological era progression around the cell system.

Example future relationship:

```text
Organelle upgrades evolve individual cells.
Accelerate Mutation speeds the planet's broader path toward Multicellular Life.
```

### Future Design Notes

This card is strategically important because it introduces the future game pattern:

```text
More progress now
→ more risk later
```

That pattern should continue into industry, signal, diplomacy, and war.

---

# 6. Implementation Scope

## 6.1 In Scope

This implementation plan includes:

- renaming the preview section,
- adding bridge copy,
- improving future card wording,
- ensuring the UI visually reads as one biology pipeline,
- updating docs/handoff,
- avoiding live purchase logic.

## 6.2 Out Of Scope

Do **not** implement in this pass:

- `LifeProgress` profile field,
- `Stability` profile field,
- `ApplyIntervention` remote,
- server-side generic intervention purchase handler,
- actual Matter spending for Ecosystem Interventions,
- biological events,
- Multicellular Life stage transition,
- DataStore saving,
- player-to-player systems.

Those belong to Epic 6 or later.

---

# 7. Suggested Branch

Use a small, focused branch:

```bash
git checkout main
git pull
git checkout -b tien/ecosystem-interventions-ui-clarity
```

Alternative:

```bash
git checkout -b tien/epic5-ecosystem-interventions-bridge
```

---

# 8. Files Likely Touched

## 8.1 Safe / Expected Files

```text
src/shared/InterventionData.luau
src/client/InterventionPreviewUI.luau
src/client/PlanetInteraction.client.luau

docs/EPICS/Epic5.md
HANDOFF-TIEN.md
HANDOFF.md if global state changes
```

## 8.2 Files To Avoid Unless Coordinating With Nova

```text
src/server/PlayerManager.luau
src/shared/Remotes.luau
src/shared/GameConfig.luau
src/client/CellInterventionUI.luau
src/client/BiosphereView.client.luau
src/shared/OrganelleData.luau
src/shared/Pricing.luau
src/shared/MulticellularData.luau
```

### Why Avoid These?

Nova owns the live cell/organelle/progression economy lane.

This pass is not meant to change live biology logic. It is meant to clarify how the preview layer connects to it.

---

# 9. Step-By-Step Implementation Plan

## Step 1 — Audit Current UI Mounting

Find where the inspect panel mounts:

```text
CellInterventionUI
InterventionPreviewUI
```

Expected current behavior:

```text
CellInterventionUI mounts above preview cards.
InterventionPreviewUI renders Future Interventions below it.
```

Confirm layout order.

Expected order:

```text
CellInterventionUI layoutOrder ≈ 14
InterventionPreviewUI layoutOrder ≈ 30
```

Do not change the live cell UI internals unless needed.

---

## Step 2 — Update `InterventionData.luau`

Update future preview definitions so they describe **ecosystem interventions**, not generic future upgrades.

### Required Data Shape

Each future intervention should clearly include:

```lua
category = "Ecosystem"
state = "ComingSoon"
unlockEpic = 6
```

### Suggested Definitions

#### `nourish_microbes`

```lua
{
    id = "nourish_microbes",
    displayName = "Nourish Microbes",
    category = "Ecosystem",
    description = "Feed fragile ecosystems with patient nutrients so early life can spread.",
    flavor = "Patient nutrients turn a spark into an ecosystem.",
    cost = { Matter = 20 },
    repeatable = true,
    requirements = {
        evolutionStage = "Archaea",
    },
    effects = {
        addLifeProgress = 20,
    },
    state = "ComingSoon",
    unlockEpic = 6,
    sortOrder = 100,
}
```

#### `stabilize_oceans`

```lua
{
    id = "stabilize_oceans",
    displayName = "Stabilize Oceans",
    category = "Ecosystem",
    description = "Calm the planet's oceans so fragile cells can survive and multiply.",
    flavor = "A steady sea is a cradle, not a grave.",
    cost = { Matter = 25 },
    repeatable = true,
    requirements = {
        evolutionStage = "Archaea",
    },
    effects = {
        addStability = 15,
    },
    state = "ComingSoon",
    unlockEpic = 6,
    sortOrder = 110,
}
```

#### `accelerate_mutation`

```lua
{
    id = "accelerate_mutation",
    displayName = "Accelerate Mutation",
    category = "Ecosystem",
    description = "Force rapid adaptation. Evolution moves faster, but the ecosystem becomes less stable.",
    flavor = "Evolution loves a gamble — so do you.",
    cost = { Matter = 25 },
    repeatable = true,
    requirements = {
        evolutionStage = "Archaea",
    },
    effects = {
        addLifeProgress = 35,
        addStability = -10,
    },
    state = "ComingSoon",
    unlockEpic = 6,
    sortOrder = 120,
}
```

### Notes

The `effects` fields are future-facing.

They should be present as data, but no server code should apply them yet.

---

## Step 3 — Update `InterventionPreviewUI.luau`

### 3.1 Rename Header

Change header from:

```text
Future Interventions
```

to:

```text
Ecosystem Interventions
```

### 3.2 Add Bridge Subtitle

Add subtitle under the header:

```text
Shape the world around your cells so life can grow, stabilize, and evolve.
```

Dev-specific version if desired:

```text
Shape the planet conditions around your cells. These interventions will guide Life Progress and Stability in Epic 6.
```

Recommended player-facing version:

```text
Shape the world around your cells so life can grow, stabilize, and evolve.
```

### 3.3 Update Badge

Each preview card should still have:

```text
Coming Soon · Epic 6
```

But the section subtitle should make clear **what** is coming soon.

### 3.4 Effect Summary Formatting

Effects should read compactly:

```text
Cost 20 Matter · Life Progress +20
Cost 25 Matter · Stability +15
Cost 25 Matter · Life Progress +35 · Stability -10
```

Avoid overly technical formatting like:

```text
addLifeProgress: 20
addStability: -10
```

### 3.5 Card Styling

Keep cards visually related to the current inspect style:

- dark rounded cards,
- cyan border/rim,
- yellow/gold `Coming Soon` badge,
- muted body text,
- no interactive button.

Make it clear these are preview cards, not disabled broken buttons.

---

## Step 4 — Add A Parent `Life Interventions` Header If Needed

If the inspect panel currently says only:

```text
Intervention
```

Consider changing that to:

```text
Life Interventions
```

or:

```text
Interventions
```

with clearer hierarchy underneath.

### Option A — Minimal Change

Keep existing top header:

```text
Intervention
```

Rename only preview section:

```text
Ecosystem Interventions
```

This is safest.

### Option B — Better UX

Change top header to:

```text
Life Interventions
```

Then sections read:

```text
Cell Cultures
Ecosystem Interventions
```

This is clearer, but verify it does not duplicate or fight with labels inside `CellInterventionUI`.

### Recommendation

Use **Option B** if the UI still looks clean.

Use **Option A** if changing the parent label causes layout clutter.

---

## Step 5 — Do Not Touch Live Purchase Logic

This pass should not add:

```text
ApplyIntervention remote
lifeProgress profile field
stability profile field
server effect application
new Matter spending path
```

Reason:

Nova already has active progression work.

A generic live pipeline should be coordinated with him in Epic 6.

---

## Step 6 — Documentation Update

Update:

```text
docs/EPICS/Epic5.md
HANDOFF-TIEN.md
```

Only update `HANDOFF.md` if the branch lands or global state changes.

### Add To Epic 5

```markdown
## Ecosystem Intervention Preview Clarification

The preview cards below Cell Cultures are intentionally not a second upgrade system.
They are future planet-level ecosystem interventions that will support Nova's cell/evolution path in Epic 6.

Cell Cultures = microscopic life progression.
Ecosystem Interventions = planet condition strategy.

Current cards are preview-only:
- Nourish Microbes
- Stabilize Oceans
- Accelerate Mutation

They show future cost/effect/flavor but do not spend Matter yet.
```

### Add To Handoff

```markdown
## Recent Changes
- Renamed the read-only future intervention preview section to `Ecosystem Interventions`.
- Added bridge copy explaining that these cards shape planet conditions around cells.
- Updated future card copy/effect summaries to clarify their Epic 6 role.
- No remotes, server purchase logic, LifeProgress, or Stability implementation added.
```

---

# 10. Acceptance Criteria

Implementation is done when:

- Inspect panel no longer shows vague `Future Interventions` as the main label.
- Preview section is renamed to `Ecosystem Interventions` or equivalent.
- A bridge sentence explains how the section relates to cells.
- Cards clearly show:
  - cost,
  - future effect,
  - flavor,
  - `Coming Soon · Epic 6`.
- Cell Cultures still work exactly as before.
- Create Cell / organelle purchase behavior is unchanged.
- No new remotes are added.
- No server purchase code is changed.
- No Matter spending happens from preview cards.
- Docs / handoff are updated.
- No UI duplicates appear after entering/exiting inspect.
- Scroll behavior still works.

---

# 11. Testing Checklist

## 11.1 Visual Test

```text
1. Start game.
2. Collect Matter if needed.
3. Approach Origin World.
4. Press E to inspect.
5. Scroll to the intervention section.
6. Confirm Cell Cultures appears first.
7. Confirm Ecosystem Interventions appears below.
8. Confirm subtitle explains the relationship to cells.
9. Confirm preview cards are readable.
```

## 11.2 Non-Interaction Test

```text
1. Try clicking preview cards.
2. Confirm nothing spends Matter.
3. Confirm no server error appears.
4. Confirm no remote warning appears.
```

## 11.3 Regression Test — Nova's Cell UI

```text
1. Create a cell.
2. Confirm Matter decreases correctly.
3. Confirm cell count updates.
4. Buy organelles if enough Matter.
5. Confirm preview section did not break Cell Cultures.
6. Confirm Biosphere View still responds.
```

## 11.4 Inspect Regression

```text
1. Enter inspect mode.
2. Exit inspect mode.
3. Re-enter inspect mode.
4. Confirm no duplicate headers/cards.
5. Confirm scroll frame behaves normally.
```

---

# 12. Risk List

## Risk 1 — It Still Feels Like Two Menus

If the bridge copy is too small or hidden, players may still see two unrelated systems.

### Mitigation

Use a clear section title:

```text
Ecosystem Interventions
```

and a direct subtitle:

```text
Shape the world around your cells so life can grow, stabilize, and evolve.
```

---

## Risk 2 — It Looks Like Broken Disabled Buttons

If the preview cards look like disabled buttons, players may think something is bugged.

### Mitigation

Make them clearly read-only preview cards with:

```text
Coming Soon · Epic 6
```

Do not include disabled purchase buttons.

---

## Risk 3 — It Competes With Nova's Multicellular Path

Nova has or may soon have a live Multicellular Path.

### Mitigation

Do not describe Ecosystem Interventions as the only way to reach Multicellular Life.

Instead:

```text
Cell upgrades evolve the life forms.
Ecosystem interventions support the planet conditions around that evolution.
```

---

## Risk 4 — Scope Creep Into Epic 6

It may be tempting to make the preview cards live.

### Mitigation

Do not implement:

```text
LifeProgress
Stability
ApplyIntervention
server effect handling
```

until Epic 6 is intentionally started.

---

# 13. Future Epic 6 Connection

When Epic 6 begins, these preview cards can become live.

## 13.1 Required New Fields

Add to profile:

```lua
lifeProgress = 0
stability = 100
```

Possibly mirror to planet attributes:

```text
LifeProgress
Stability
```

## 13.2 Required Remote

Add one generic remote:

```text
ApplyIntervention
```

Client → Server payload:

```lua
{
    interventionId = "nourish_microbes"
}
```

## 13.3 Server Handler

Server should:

```text
look up InterventionData
reject ComingSoon / inactive definitions
check requirements
check Matter cost
apply effects
push MatterUpdate
push ConverterUpdate or a new InterventionUpdate
update planet attributes if needed
```

## 13.4 UI Upgrade Path

The current preview UI can become interactive by adding:

```text
Available / Unaffordable / Locked / Completed states
```

But do not do this in the current clarification pass.

---

# 14. Suggested Claude Prompt

Use this when asking Claude Code to implement the clarification pass:

```markdown
Task: Clarify the relationship between Nova's Cell Cultures and the future Ecosystem Interventions preview in the planet inspect panel.

Context:
Nova owns the live cell/organelle/progression system. Do not touch server purchase logic, remotes, PlayerManager, organelle data, BiosphereView, or Nova's active upgrade code unless absolutely necessary.

Goal:
The current UI makes Cell Cultures and Future Interventions look like two separate systems. They should read as two layers of one early-life pipeline:

- Cell Cultures = microscopic life progression
- Ecosystem Interventions = planet-level evolution strategy around those cells

Implementation:
1. Rename the read-only `Future Interventions` section to `Ecosystem Interventions`.
2. Add a short subtitle under the section header:
   `Shape the world around your cells so life can grow, stabilize, and evolve.`
3. Keep preview cards read-only. No buttons. No Matter spending.
4. Update the three card descriptions/effect summaries:
   - Nourish Microbes: `Cost 20 Matter · Life Progress +20`
   - Stabilize Oceans: `Cost 25 Matter · Stability +15`
   - Accelerate Mutation: `Cost 25 Matter · Life Progress +35 · Stability -10`
5. Keep `Coming Soon · Epic 6` badges.
6. If appropriate, change the parent intervention heading to `Life Interventions`, but only if it does not clutter the UI.
7. Update Epic 5 docs and HANDOFF-TIEN with what changed.

Constraints:
- Do not implement LifeProgress.
- Do not implement Stability.
- Do not add an ApplyIntervention remote.
- Do not change Nova's live Cell Cultures behavior.
- Do not create a competing upgrade framework.

Acceptance:
- Inspect panel clearly explains that Ecosystem Interventions support the cells/early biosphere.
- Cell Cultures still works exactly as before.
- Preview cards are readable and non-interactive.
- No server/economy behavior changed.
- Docs/handoff updated.
```

---

# 15. Final Thesis

This implementation should make the early-life UI communicate one simple idea:

```text
Cells are the life.
Ecosystem Interventions are the world around that life.
```

Together, they create the bridge from Nova's working cell upgrade system into Epic 6's broader evolution strategy.

The player should understand:

```text
First I grow cells.
Then I shape the planet so those cells can become something greater.
```

That is the correct relationship between the systems.
