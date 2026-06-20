# Epic 5 — Planet Upgrade System / Matter Core

**Project:** Grow A [X]  
**Epic Type:** Core Gameplay Framework  
**Status:** Planned / Ready for detailed implementation planning  
**Primary Goal:** Turn the current Matter / upgrade work into a coherent, server-authoritative, inspect-integrated **Planet Upgrade System** that supports present gameplay and future civilization progression without becoming an endless generic upgrade shop.

---

## 0. Executive Summary

Epic 5 defines the next major gameplay layer after the current Matter + Create Life prototype.

The game already has the foundation:

```text
Fly through space
→ collect Matter
→ return to Origin World
→ inspect planet
→ Create Life / begin Archaea
→ planet reacts visually
```

The current risk is that upgrades become endless number boosts:

```text
+5% Matter
+10% Matter
+15% Matter
+20% Matter
```

Epic 5 exists to prevent that.

Instead of a generic upgrade shop, this epic turns the upgrade system into the **Matter Core**, a planet-centered intervention system where the player spends Matter to guide their Origin World through meaningful milestones.

The first version should stay simple:

```text
Matter Core
→ shows available planet interventions
→ validates purchases on the server
→ deducts Matter
→ updates player/planet state
→ triggers visual feedback
→ prepares the game for future Life Progress, Stability, Projects, and Civilization systems
```

This epic is not the full evolution system, not the full tech tree, not offline saving, not player-to-player trade, and not war.

It is the **upgrade framework** that future systems will plug into.

---

## 1. Design Intent

### 1.1 Player Fantasy

The player is a **Universe Architect** guiding an **Origin World**.

The player does not buy random upgrades from a shop. They perform **Interventions** through the Matter Core.

Player-facing fantasy:

```text
I collect Matter from space.
I return to my Origin World.
I open the Matter Core.
I choose how to intervene.
My planet changes because of my choice.
```

The Matter Core should feel like a cosmic control panel for shaping a world, not a normal tycoon upgrade menu.

---

### 1.2 Why This Epic Matters

Without a structured upgrade system, the game risks becoming:

```text
collect resource
buy multiplier
collect faster
buy bigger multiplier
repeat forever
```

That is not enough for the long-term game.

The upgrade system must become the foundation for:

- biological evolution,
- planet milestones,
- future civilization projects,
- technology paths,
- visual era changes,
- future contact/trade/war requirements,
- future offline progression calculations.

Epic 5 should make upgrades meaningful by attaching them to:

```text
Era
Requirement
Cost
Effect
Planet state
Visual feedback
Future unlocks
```

---

## 2. Relationship To Current Game State

### 2.1 Current Working Systems

The current project already has several systems that Epic 5 should respect:

- Player has Matter.
- Matter can be collected from the world.
- The player has an Origin World.
- The Origin World can be inspected.
- Create Life / Archaea exists as the first meaningful intervention.
- Archaea can produce passive Matter.
- Planet attributes like `EvolutionTier` and `EvolutionStage` are used for stage/visual logic.
- Planet visuals can react to stage state.
- Nova has been working on the upgrade / Matter Core direction.

Epic 5 should integrate and organize this work, not rewrite everything from scratch.

---

### 2.2 Current Problem

The current upgrade flow risks feeling disconnected or unclear if:

- Matter Core appears as a generic global button.
- Create Life appears separately from planet inspect.
- Upgrade buttons do not explain why they matter.
- Upgrades only increase Matter production.
- The player does not see what changed on the planet.
- Future systems do not have a clean upgrade definition format.

Epic 5 should solve this by establishing:

```text
Inspect Origin World
→ Matter Core / Interventions section
→ choose planet intervention
→ server validates purchase
→ planet state updates
→ UI and visuals react
```

---

## 3. Epic Scope

### 3.1 In Scope

Epic 5 includes:

- Matter Core / Planet Upgrade UI structure.
- Upgrade/intervention definition format.
- Server-authoritative purchase validation.
- Matter cost deduction.
- Owned/purchased upgrade tracking.
- Basic unlock requirements.
- Upgrade state updates to the client.
- Planet attribute updates from upgrades.
- Feedback when an upgrade succeeds or fails.
- Inspect panel integration.
- Documentation updates.
- Testing checklist.

---

### 3.2 Out Of Scope

Epic 5 does **not** include:

- Full Life Progress / Stability progression system.
- Full Sentience Progress system.
- Civilization Projects.
- Tech tree.
- Doctrine system.
- DataStore saving.
- Offline progress.
- Nearby Worlds / First Contact.
- Trade routes.
- Probes.
- War.
- Dark Forest late-game systems.
- Full redesign of procedural planet generation.

Those are future epics.

Epic 5 should make those future systems easier to build, but it should not try to build them all now.

---

## 4. Terminology

### 4.1 Matter

Matter is the primary early-game resource.

It is collected by flying through space and is spent through the Matter Core.

Matter should remain the first universal resource because it is already implemented and easy for players to understand.

---

### 4.2 Matter Core

The **Matter Core** is the player-facing upgrade/intervention interface.

It should be framed as the system that allows the player to spend Matter to shape their planet.

Matter Core should eventually support multiple categories:

```text
Life Interventions
Planet Stabilization
Civilization Projects
Technology Paths
Defense / Signal Systems
Trade / Diplomacy Systems
```

But Epic 5 should only fully implement the first simple category:

```text
Life Interventions
```

---

### 4.3 Intervention

An **Intervention** is a player action that directly shapes the planet.

Examples:

```text
Create Life
Nourish Microbes
Stabilize Oceans
Accelerate Mutation
Encourage Cooperation
Build Observatory Network
Broadcast Beacon
```

In code, these may be called upgrades, but player-facing text should prefer **Intervention** when the action is planet/evolution focused.

---

### 4.4 Upgrade

An **Upgrade** is the technical/backend concept.

An upgrade has:

```text
id
name
description
category
cost
requirements
effects
repeatability
owned state
```

The code can call these upgrades, but UI should use more flavorful names.

---

### 4.5 Project

A **Project** is a larger, timed civilization effort. Projects are future-facing and should not be fully implemented in Epic 5.

Examples:

```text
Observatory Network
Industrial Base
Starport
Defense Grid
```

Epic 5 should design the upgrade data model flexibly enough that Projects can be added later.

---

## 5. Design Pillars

### Pillar 1 — Upgrades Must Unlock Meaning, Not Just Numbers

Every upgrade should answer:

```text
What changed about my planet?
Why does this matter for progression?
What new option does this unlock?
```

Bad upgrade:

```text
Matter Boost I
+5% Matter
```

Better intervention:

```text
Nourish Microbes
Cost: 20 Matter
Effect: Life Progress +20
Flavor: Feed the first fragile ecosystems on your world.
```

---

### Pillar 2 — Server Authority

All Matter spending and upgrade ownership must be validated server-side.

The client may request an upgrade.

The server decides:

- whether the upgrade exists,
- whether the player can afford it,
- whether requirements are met,
- whether it has already been purchased,
- what state changes happen.

The client should never directly deduct Matter or grant upgrades.

---

### Pillar 3 — Inspect Integration

Planet upgrades should feel tied to the Origin World.

The best default flow:

```text
Approach Origin World
→ press E to inspect
→ inspect panel opens
→ Matter Core / Interventions section appears
→ choose intervention
```

A global Matter Core button can exist later, but if the player is not inspecting their planet, it should either:

- show read-only overview, or
- tell the player to inspect their Origin World to apply interventions.

---

### Pillar 4 — Small Now, Flexible Later

Epic 5 should not become a huge tech tree.

It should implement enough structure for future systems.

Start with a few interventions:

```text
Create Life
Nourish Microbes / placeholder
Stabilize Oceans / future locked
Accelerate Mutation / future locked
```

Then future epics can expand.

---

### Pillar 5 — Player Feedback Is Required

When an upgrade is purchased, the player should get clear feedback:

- Matter decreases.
- Button state changes.
- Planet stage or stat updates.
- Visual effect plays if applicable.
- UI shows success message.

The player should never wonder whether the button worked.

---

## 6. Target Player Flow

### 6.1 First-Time Player Flow

```text
1. Player spawns in space.
2. Player collects Matter.
3. Player returns to Origin World.
4. Player inspects planet.
5. Inspect panel shows planet state: Prebiotic.
6. Matter Core section shows Create Life.
7. Player buys Create Life.
8. Server validates Matter cost.
9. Matter is deducted.
10. Planet becomes Archaea.
11. Planet visuals update.
12. UI shows Archaea is active.
13. Passive Archaea Matter production begins if implemented.
```

---

### 6.2 Returning Player Flow During Current Session

```text
1. Player opens inspect panel.
2. Matter Core shows current owned interventions.
3. Create Life is marked owned/completed.
4. Next intervention is visible but may be locked.
5. UI explains what requirement is missing.
```

Example:

```text
Nourish Microbes
Locked
Requirement: Archaea stage active
Cost: 20 Matter
```

or:

```text
Stabilize Oceans
Coming Soon
Unlocks in Epic 6: Early Evolution Progression
```

---

## 7. MVP Feature Set

Epic 5 MVP should include the following core pieces.

### 7.1 Matter Core UI Section

A player-facing panel or section that shows available interventions.

Minimum UI data per intervention:

```text
Name
Cost
Description
Effect summary
Requirement / locked reason
Owned state
Purchase button
```

Example card:

```text
Create Life
Cost: 15 Matter
Effect: Sparks the first Archaea Cell on your Origin World.
Status: Available
[Create Life]
```

After purchase:

```text
Create Life
Completed
Your world now contains Archaea.
```

---

### 7.2 Upgrade Definition Table

Upgrades should be defined in one central config/module if possible.

Example conceptual schema:

```lua
return {
    create_life = {
        id = "create_life",
        name = "Create Life",
        category = "Life",
        description = "Spark the first Archaea Cell on your Origin World.",
        cost = {
            Matter = 15,
        },
        repeatable = false,
        requirements = {
            evolutionStage = "Prebiotic",
        },
        effects = {
            evolutionTier = 1,
            evolutionStage = "Archaea",
            archaeaCountDelta = 1,
        },
    },
}
```

The actual implementation should match existing project style, but the important idea is:

```text
Upgrade definitions should be data-driven, not hardcoded into random UI buttons.
```

---

### 7.3 Server Purchase Handler

There should be a single clear server flow for buying upgrades.

Conceptual flow:

```text
Client requests purchase upgradeId
→ Server looks up upgrade definition
→ Server loads player profile
→ Server checks requirements
→ Server checks cost
→ Server checks ownership/repeatability
→ Server applies effects
→ Server deducts Matter
→ Server updates planet attributes
→ Server sends updated state to client
```

---

### 7.4 Upgrade State Tracking

The player profile needs a way to track owned upgrades.

In current session memory, this may look like:

```lua
profile.Upgrades = {
    create_life = true,
}
```

or:

```lua
profile.PurchasedUpgrades = {
    ["create_life"] = {
        purchasedAt = os.time(),
        count = 1,
    },
}
```

For Epic 5, the simpler boolean model is fine unless Nova’s current work already uses a more flexible structure.

Future repeatable upgrades may need counts.

---

### 7.5 Planet Attribute Updates

Purchasing certain upgrades should update planet attributes.

For Create Life:

```text
EvolutionTier = 1
EvolutionStage = "Archaea"
```

Potential future attributes:

```text
LifeProgress
Stability
SentienceProgress
Doctrine
Signal
```

Epic 5 should not fully implement all of these, but it should avoid making the current system hard to expand.

---

### 7.6 Client Feedback

On success:

```text
- button changes to completed
- Matter HUD updates
- planet panel updates
- success toast/message appears
- optional visual effect plays
```

On failure:

```text
- insufficient Matter message
- locked requirement message
- already purchased message
- server rejected purchase safely
```

Failure should be clear, not silent.

---

## 8. Suggested Interventions For Epic 5

Epic 5 should focus on a small set of interventions.

### 8.1 Create Life

**Status:** Required MVP  
**Era:** Prebiotic  
**Cost:** 15 Matter, or current tuned cost  
**Repeatable:** No  
**Effect:** Begins Archaea stage  
**Planet Attribute Effects:**

```text
EvolutionTier = 1
EvolutionStage = "Archaea"
```

**Player-facing description:**

```text
Spark the first Archaea Cell on your Origin World.
```

**Visual feedback:**

```text
Microbial glow appears around the planet.
A small orbiting life indicator may appear.
Inspect panel updates from Prebiotic to Archaea.
```

---

### 8.2 Nourish Microbes

**Status:** Optional MVP / Good stretch  
**Era:** Archaea  
**Cost:** 20 Matter  
**Repeatable:** Maybe repeatable in Epic 6, but can be one-time or placeholder in Epic 5  
**Effect:** Prepares future Life Progress system  

If Life Progress is not implemented yet, this can be shown as locked/coming soon.

**Player-facing description:**

```text
Feed the first fragile ecosystems and prepare the planet for more complex life.
```

**Future effect:**

```text
LifeProgress +20
```

---

### 8.3 Stabilize Oceans

**Status:** Future locked card  
**Era:** Archaea / Multicellular  
**Cost:** 25 Matter  
**Effect:** Future Stability increase  

**Player-facing description:**

```text
Calm violent oceans so fragile life can endure.
```

**Future effect:**

```text
Stability +15
```

This card can appear as a preview of future depth, but should not be interactive unless Epic 6 is being implemented.

---

### 8.4 Accelerate Mutation

**Status:** Future locked card  
**Era:** Multicellular / Complex Life  
**Cost:** 25 Matter  
**Effect:** Faster Life Progress with Stability tradeoff  

**Player-facing description:**

```text
Push life to change faster. Progress comes quickly, but fragile ecosystems may become unstable.
```

**Future effect:**

```text
LifeProgress +35
Stability -10
```

This is a future strategic upgrade. Epic 5 should only prepare for this style of definition.

---

## 9. UI Design Direction

### 9.1 Matter Core Should Use Inspect Panel Style

The Matter Core should feel visually connected to the existing planet inspect UI.

Preferred layout:

```text
[Planet Info]
Name: Tien's World
Stage: Archaea
Matter: 42

[Interventions]
Create Life         Completed
Nourish Microbes    Cost: 20 Matter
Stabilize Oceans    Locked / Coming Soon
```

---

### 9.2 Avoid Competing UI Entry Points

Avoid having:

```text
Top-right Create Life button
AND
Inspect panel Open Matter Converter button
AND
Separate Matter Core menu
```

That creates confusion.

Preferred rule:

```text
Planet interventions live in planet inspect.
```

If a global Matter Core button exists, it should behave as overview unless the player is inspecting their planet.

Example global behavior:

```text
Matter Core
Inspect your Origin World to apply interventions.
```

---

### 9.3 Card States

Every intervention card should have a clear state.

Possible states:

```text
Available
Affordable
Unaffordable
Locked
Completed
Coming Soon
```

Example UI text:

```text
Create Life
Completed
Your world now contains Archaea.
```

```text
Nourish Microbes
Cost: 20 Matter
Not enough Matter.
```

```text
Stabilize Oceans
Locked
Requires Multicellular Life.
```

```text
Accelerate Mutation
Coming Soon
Part of Epic 6: Early Evolution Progression.
```

---

## 10. Suggested File / System Responsibilities

This section is conceptual. Actual file names should match the repo’s current structure.

### 10.1 Shared Upgrade Definitions

Possible responsibility:

```text
src/shared/UpgradeDefinitions.luau
```

or similar.

Purpose:

- stores upgrade/intervention definitions,
- costs,
- labels,
- requirement metadata,
- effect metadata.

This keeps UI and server using the same upgrade IDs.

---

### 10.2 Server Upgrade Service

Possible responsibility:

```text
src/server/UpgradeService.luau
```

or integrate into existing PlayerManager if that is the current architecture.

Purpose:

- handles purchase requests,
- validates costs,
- validates requirements,
- applies effects,
- updates player profile,
- updates planet attributes,
- fires client updates.

If Nova’s current upgrade work already has a server file, use that rather than creating a competing service.

---

### 10.3 Client Matter Core UI

Possible responsibility:

```text
src/client/MatterCoreUI.luau
```

or extend existing `MatterConverterUI.luau` if that is the current file.

Purpose:

- renders intervention cards,
- shows costs/states,
- sends purchase requests,
- receives updates,
- refreshes UI when Matter or upgrade state changes.

---

### 10.4 Remotes

Use existing remotes if Nova already created them.

Possible remote names:

```text
RequestUpgrade
UpgradeUpdate
UpgradeResult
```

If current code already uses:

```text
CreateArchaea
ConverterUpdate
```

then Epic 5 can either:

1. keep those for now and wrap them later, or
2. migrate carefully to a more generic upgrade request if safe.

Do not create duplicate flows that do the same thing unless necessary.

---

## 11. Server Validation Rules

The server must reject unsafe requests.

### 11.1 Invalid Upgrade ID

If client sends unknown upgrade ID:

```text
Reject request.
Do not deduct Matter.
Return error: Unknown upgrade.
```

---

### 11.2 Insufficient Matter

If player cannot afford:

```text
Reject request.
Do not deduct Matter.
Return error: Not enough Matter.
```

---

### 11.3 Requirement Not Met

If upgrade requires a stage or previous upgrade:

```text
Reject request.
Return locked reason.
```

Example:

```text
Nourish Microbes requires EvolutionStage == Archaea.
```

---

### 11.4 Already Purchased

If non-repeatable upgrade is already owned:

```text
Reject request or return already completed state.
Do not deduct Matter twice.
```

This is especially important for Create Life.

---

### 11.5 Planet Ownership

Upgrade effects should apply only to the player’s own Origin World.

The server should not allow a player to purchase upgrades for another player’s planet unless a future system explicitly supports that.

---

## 12. Data Model Suggestions

### 12.1 Player Profile

Conceptual structure:

```lua
profile = {
    Matter = 0,
    EvolutionTier = 0,
    EvolutionStage = "Prebiotic",
    ArchaeaCount = 0,
    PurchasedUpgrades = {
        -- [upgradeId] = true
    },
}
```

Future expansion:

```lua
profile = {
    Matter = 0,
    EvolutionTier = 0,
    EvolutionStage = "Prebiotic",
    ArchaeaCount = 0,
    LifeProgress = 0,
    Stability = 100,
    SentienceProgress = 0,
    PurchasedUpgrades = {},
    UpgradeCounts = {},
    Traits = {},
}
```

Epic 5 does not need all future fields, but should not make them hard to add later.

---

### 12.2 Upgrade Definition

Conceptual structure:

```lua
local UpgradeDefinitions = {
    create_life = {
        id = "create_life",
        displayName = "Create Life",
        category = "Life",
        description = "Spark the first Archaea Cell on your Origin World.",
        cost = {
            Matter = 15,
        },
        repeatable = false,
        requirements = {
            evolutionStage = "Prebiotic",
        },
        effects = {
            setEvolutionTier = 1,
            setEvolutionStage = "Archaea",
            addArchaeaCount = 1,
        },
        sortOrder = 10,
    },
}
```

---

### 12.3 Upgrade State Sent To Client

The client should receive simplified display state.

Example:

```lua
{
    id = "create_life",
    displayName = "Create Life",
    category = "Life",
    description = "Spark the first Archaea Cell on your Origin World.",
    cost = { Matter = 15 },
    state = "Completed",
    canPurchase = false,
    lockedReason = nil,
}
```

or:

```lua
{
    id = "nourish_microbes",
    displayName = "Nourish Microbes",
    category = "Life",
    cost = { Matter = 20 },
    state = "Unaffordable",
    canPurchase = false,
    lockedReason = "Need 20 Matter.",
}
```

---

## 13. Epic Breakdown

## 13.1 Sprint 5A — Audit And Align Existing Upgrade Work

### Goal

Understand what Nova’s current upgrade system has implemented and align Epic 5 around it.

### Tasks

- Review current upgrade/Matter Core files.
- Identify current remotes.
- Identify current player profile fields.
- Identify how Create Life / Archaea is implemented.
- Identify UI entry points.
- Identify duplicated or confusing buttons.
- Document current state in handoff.

### Acceptance Criteria

- We know which file owns upgrade UI.
- We know which file owns server upgrade validation.
- We know current remotes.
- We know what should not be touched without coordination.
- Handoff notes are updated.

---

## 13.2 Sprint 5B — Define Upgrade / Intervention Data Model

### Goal

Create a clear data-driven format for interventions.

### Tasks

- Create or update shared upgrade definition module.
- Define `create_life` intervention.
- Optionally define future locked placeholders:
  - `nourish_microbes`
  - `stabilize_oceans`
  - `accelerate_mutation`
- Include cost, category, description, requirements, effect metadata.
- Keep names and text player-friendly.

### Acceptance Criteria

- Upgrade definitions are centralized.
- UI and server can reference the same upgrade IDs.
- Create Life is represented as a definition.
- Future upgrades can be added without hardcoding new UI buttons everywhere.

---

## 13.3 Sprint 5C — Server-Authoritative Purchase Pipeline

### Goal

Ensure upgrades are bought through a safe server path.

### Tasks

- Add/confirm remote request for upgrade purchase.
- Server validates upgrade ID.
- Server validates Matter cost.
- Server validates stage/requirements.
- Server validates repeatability/ownership.
- Server deducts Matter.
- Server applies effects.
- Server updates client state.
- Server handles failures with clear messages.

### Acceptance Criteria

- Client cannot grant itself upgrades.
- Client cannot bypass Matter cost.
- Client cannot buy Create Life twice.
- Failed purchases do not change player state.
- Successful purchases update Matter and planet state.

---

## 13.4 Sprint 5D — Matter Core UI / Intervention Cards

### Goal

Render interventions clearly in the UI.

### Tasks

- Build card list UI for interventions.
- Show cost, description, state, and button.
- Show locked/completed/coming soon states.
- Connect purchase buttons to server request.
- Refresh UI after server update.
- Keep styling consistent with inspect panel.

### Acceptance Criteria

- Player can see Create Life card.
- Player understands cost and effect.
- Button works if requirements are met.
- Button gives readable feedback if requirements fail.
- Completed interventions are not purchasable again.

---

## 13.5 Sprint 5E — Inspect Panel Integration

### Goal

Make planet interventions feel tied to the Origin World.

### Tasks

- Place Matter Core / Interventions section inside or alongside planet inspect UI.
- Ensure UI only applies interventions to player’s own planet.
- If global Matter Core button exists, make it secondary/overview-only.
- Remove or hide redundant floating Create Life buttons if they create confusion.
- Make sure inspect mode still exits correctly.

### Acceptance Criteria

- Primary upgrade flow is through planet inspect.
- No confusing duplicate Create Life entry points.
- Player understands they are upgrading/intervening on their Origin World.
- Inspect camera/marker/return-home behavior remains stable.

---

## 13.6 Sprint 5F — Planet Feedback And Stage Update

### Goal

Make successful upgrades visibly affect the planet.

### Tasks

- Create Life sets correct planet state.
- Archaea visuals appear after Create Life.
- Inspect panel stage text updates.
- Optional success particle/pulse/toast.
- Matter HUD updates.

### Acceptance Criteria

- Player sees immediate feedback after Create Life.
- Planet visually communicates life exists.
- Inspect panel and Matter HUD stay in sync.

---

## 13.7 Sprint 5G — Documentation And Testing

### Goal

Make the system understandable for future sessions and future epics.

### Tasks

- Update Epic 5 doc.
- Update HANDOFF file(s).
- Document changed files.
- Document remotes and data shape.
- Add test checklist.
- Document future extension points for Epic 6.

### Acceptance Criteria

- Future Claude session can understand the upgrade system.
- Tien and Nova know which files own which responsibilities.
- Testing checklist passes.
- Future Life Progress/Stability work has a clear place to connect.

---

## 14. Detailed Ticket List

### Ticket 5.1 — Audit Current Matter Core / Upgrade Work

**Type:** Investigation / Docs  
**Priority:** Critical  

#### Description

Before changing code, inspect Nova’s current upgrade implementation and document what exists.

#### Tasks

- Find the client UI file for Matter Core / Matter Converter.
- Find the server purchase handler.
- Find current remotes.
- Find current constants/costs.
- Find where Archaea count/state is stored.
- Find where `EvolutionTier` / `EvolutionStage` is set.
- Write notes in handoff.

#### Acceptance

- Current architecture is documented.
- No gameplay code changed unless necessary.

---

### Ticket 5.2 — Centralize Upgrade Definitions

**Type:** Code / Architecture  
**Priority:** High  

#### Description

Create or align a shared upgrade definition table.

#### Tasks

- Add definition for `create_life`.
- Include display name, cost, category, description, requirements, effects.
- Optionally include locked future interventions.
- Ensure server and UI can use same IDs.

#### Acceptance

- Create Life data is not duplicated across UI/server.
- Adding a future intervention requires minimal code changes.

---

### Ticket 5.3 — Purchase Request Validation

**Type:** Server  
**Priority:** Critical  

#### Description

Ensure all upgrade purchases are server-authoritative.

#### Tasks

- Implement or verify request remote.
- Validate upgrade ID.
- Validate Matter cost.
- Validate requirements.
- Validate repeatability.
- Apply effects safely.
- Return success/failure result.

#### Acceptance

- Exploit-like client requests are rejected.
- Matter cannot go negative.
- Create Life cannot be bought twice.

---

### Ticket 5.4 — Intervention Card UI

**Type:** Client UI  
**Priority:** High  

#### Description

Create UI cards for Matter Core interventions.

#### Tasks

- Render list of upgrade definitions.
- Show state per card.
- Add button behavior.
- Add locked/completed/insufficient Matter state.
- Keep style close to inspect menu.

#### Acceptance

- UI is readable.
- Player knows what each action does.
- Buttons reflect state correctly.

---

### Ticket 5.5 — Inspect Integration Cleanup

**Type:** Client UI / UX  
**Priority:** High  

#### Description

Make the primary upgrade flow happen from planet inspect.

#### Tasks

- Put Matter Core/Interventions section in inspect panel or linked panel.
- Remove confusing duplicate Create Life entry point.
- Keep global Matter Core button as overview only if retained.
- Ensure interactions are own-planet-only.

#### Acceptance

- No confusing duplicate upgrade buttons.
- Player understands where to go to upgrade planet.

---

### Ticket 5.6 — Create Life Feedback Pass

**Type:** Visual / UI Feedback  
**Priority:** Medium  

#### Description

Make Create Life feel satisfying and obvious.

#### Tasks

- Show success message.
- Update planet stage text.
- Trigger Archaea glow/state visual.
- Update Matter HUD.
- Mark Create Life completed.

#### Acceptance

- Player can clearly tell Create Life succeeded.

---

### Ticket 5.7 — Epic 6 Extension Notes

**Type:** Docs  
**Priority:** Medium  

#### Description

Document how Epic 6 can plug into Epic 5.

#### Tasks

- Document how to add Life Progress.
- Document how to add Stability.
- Document how to add future interventions.
- Document how to add events/projects later.

#### Acceptance

- Epic 6 can start without rediscovering the system.

---

## 15. Testing Plan

### 15.1 Basic Purchase Test

```text
1. Start game.
2. Collect enough Matter.
3. Return to Origin World.
4. Inspect planet.
5. Buy Create Life.
6. Confirm Matter decreases.
7. Confirm planet stage changes to Archaea.
8. Confirm UI marks Create Life completed.
9. Confirm planet visual updates.
```

---

### 15.2 Insufficient Matter Test

```text
1. Start with less Matter than required.
2. Try to buy Create Life.
3. Confirm purchase fails.
4. Confirm Matter does not change.
5. Confirm UI explains not enough Matter.
```

---

### 15.3 Duplicate Purchase Test

```text
1. Buy Create Life.
2. Try to buy Create Life again.
3. Confirm server rejects or UI blocks duplicate purchase.
4. Confirm Matter is not deducted twice.
5. Confirm Archaea count/state does not duplicate incorrectly.
```

---

### 15.4 Requirement Lock Test

```text
1. Show a future intervention that requires Archaea or Multicellular.
2. Confirm it is locked before requirement is met.
3. Meet requirement if implemented.
4. Confirm state updates correctly.
```

---

### 15.5 Inspect Integration Test

```text
1. Approach Origin World.
2. Press E to inspect.
3. Confirm Matter Core / Interventions are visible.
4. Purchase available intervention.
5. Exit inspect.
6. Re-enter inspect.
7. Confirm state persists during session.
```

---

### 15.6 Own-Planet Safety Test

```text
1. Join with multiple players if possible.
2. Inspect or approach another player planet.
3. Confirm upgrades cannot be applied to another player’s planet.
4. Confirm only own Origin World can receive intervention effects.
```

---

### 15.7 UI State Refresh Test

```text
1. Collect Matter while Matter Core UI is open or reopen after collecting.
2. Confirm affordable/unaffordable states refresh.
3. Spend Matter.
4. Confirm cards refresh again.
```

---

## 16. Risk List

### Risk 1 — Duplicated Upgrade Logic

If UI and server each hardcode costs/effects separately, future changes will break easily.

**Mitigation:** Centralize definitions where possible.

---

### Risk 2 — Conflicting With Nova’s Work

Nova may already have upgrade logic in progress.

**Mitigation:** Audit and align before refactoring. Do not create a parallel system unless necessary.

---

### Risk 3 — UI Becomes Too Big Too Soon

Trying to show all future systems now could overwhelm players.

**Mitigation:** Only show current + a few locked/preview cards.

---

### Risk 4 — Upgrades Become Generic

If names/effects are too bland, the system feels like a normal tycoon shop.

**Mitigation:** Use intervention language and planet feedback.

---

### Risk 5 — Server Trust Issues

If the client controls purchases, exploit risk is high.

**Mitigation:** Server-authoritative validation.

---

## 17. Future Extension Points

Epic 5 should leave clean paths for later systems.

### 17.1 Epic 6 — Early Evolution Progression

Future additions:

```text
Life Progress
Stability
Nourish Microbes
Stabilize Oceans
Accelerate Mutation
Evolve Multicellular Life
Mass Algae Bloom event
```

Epic 5 should make it easy to add those as new interventions.

---

### 17.2 Epic 7 — Planet Era Visuals

Future additions:

```text
visual changes per EvolutionStage
more terrain/life effects
city lights
industrial glow
orbiting satellites
```

Epic 5 should ensure planet attributes are updated reliably so visuals can listen to them.

---

### 17.3 Epic 8 — Events And Disasters

Future additions:

```text
biological events
civilization events
space events
choice cards
consequence tracking
```

Epic 5’s intervention/card UI may inspire event choice UI later.

---

### 17.4 Epic 9 — DataStore / Saving

Future additions:

```text
save Matter
save upgrades
save EvolutionStage
save LastLogoutTime
save active projects/trade/probes later
```

Epic 5 should keep upgrade state in a structure that can be saved later.

---

### 17.5 Epic 10 — Nearby Worlds / First Contact

Future additions:

```text
Telescope Array
Radio Array
Nearby Worlds panel
First Contact ping
Known Civilizations list
```

Epic 5 should support future unlocks like Telescope Array as intervention/project definitions.

---

## 18. Documentation Requirements

When Epic 5 is implemented, update:

```text
HANDOFF.md / HANDOFF-TIEN.md / HANDOFF-NOVA.md as appropriate
CLAUDE.md if workflow or file responsibilities change
docs/EPICS/Epic5.md
any relevant system docs
```

Documentation should include:

- changed files,
- remotes used,
- upgrade definition format,
- profile fields used,
- how to add a new intervention,
- testing checklist,
- known limitations,
- what is deferred to Epic 6.

---

## 19. Suggested Handoff Summary Format

After working on Epic 5, Claude should produce:

```markdown
## Epic 5 Handoff Summary

### What Changed
-

### Files Changed
-

### Upgrade / Intervention IDs Added
-

### Remotes Used / Added
-

### Player Profile Fields Used / Added
-

### Planet Attributes Used / Added
-

### How To Test
-

### Known Issues
-

### Deferred To Future Epics
-

### Handoff File Updated
- HANDOFF.md / HANDOFF-TIEN.md / HANDOFF-NOVA.md / None
```

---

## 20. Definition Of Done

Epic 5 is complete when:

- Player can open a Matter Core / Interventions UI.
- Create Life is represented as an intervention/upgrade.
- Purchase flow is server-authoritative.
- Matter is deducted safely.
- Requirements and ownership are validated.
- Planet state updates correctly.
- UI reflects available/locked/completed states.
- Create Life cannot be purchased twice.
- Player receives clear feedback.
- Upgrade definitions are documented.
- Future interventions can be added without rewriting the whole system.
- Docs/handoff are updated.

---

## 21. Final Epic Thesis

Epic 5 is not about adding a giant upgrade shop.

Epic 5 is about turning Matter spending into the foundation of planet-scale progression.

The player should feel:

```text
I am not buying random boosts.
I am intervening in my planet’s development.
Every major purchase moves my world toward a new era.
```

This is the bridge from the current prototype into the long-term game:

```text
Matter collection
→ Matter Core
→ Life interventions
→ Evolution progression
→ Civilization projects
→ First contact
→ Trade / diplomacy / conflict
→ cosmic-scale progression
```

Epic 5 should be small enough to ship, but structured enough to support everything that comes after.

---

# Sprint 5A — Audit & Alignment (executed 2026-06-20, Tien + Claude)

> **Headline finding: Epic 5's MVP is ~80% already built by Nova's Epic 3 work.** The
> server-authoritative, inspect-integrated, data-driven Create-Life-and-upgrade flow this
> epic describes already exists. Per §13.1 / Risk 2, the correct path is to **align with and
> extend Nova's system, NOT build a parallel Matter Core framework.**

## Current upgrade architecture (as merged on `main`)

**Remotes** (`src/shared/Remotes.luau`): `MatterUpdate`, `CreateArchaea`, `ConverterUpdate`,
`PurchaseOrganelle`, `CellEvolved`, `CascadeTriggered`.

**Server — `src/server/PlayerManager.luau`** (server-authoritative throughout):
- Profile: `{ matter, cells = {}, nextCellId, cascadeTriggered, dustMultiplier, maxTierEvolved }`.
- `onCreateArchaea(player)` — validates Matter ≥ cost, deducts, appends a cell; on the **first**
  cell sets planet `EvolutionTier=1` / `EvolutionStage="Archaea"`.
- `onPurchaseOrganelle(player, payload)` — validates cost + correct next organelle (no skipping);
  on completing the path triggers the one-time **Eukaryotic Cascade** (`EvolutionStage="Eukaryotic"`,
  raises `dustMultiplier`). Pushes `ConverterUpdate`.
- Dust multiplier per evolved tier (`dustMultiplierForTier`).

**Definitions — `src/shared/OrganelleData.luau`**: ordered Tier-1 path (membrane → cytoplasm →
ribosomes → nucleoid → plasmids → mitochondria → nucleus), each `{ id, name, cost, productionBonus,
visual }`; `TOTAL_COST = 240`; helpers (`nextOrganelle`, `isComplete`, …). **This is already a
data-driven definition table** — the thing §7.2 / §13.2 asks for, scoped to organelles.

**Client UI — `src/client/CellInterventionUI.luau`**: `.mount(parent, opts)` is mounted **into the
inspect panel** by `PlanetInteraction` (Epic 5 §13.5 / Pillar 3 already satisfied). Renders cell list
+ per-cell organelle cards with affordability/locked/completed states; fires `CreateArchaea` /
`PurchaseOrganelle`; subscribes to `MatterUpdate` / `ConverterUpdate`. Feedback handled by
`BiosphereView.client.luau` (Life Vessel + Microscope) and `PlanetStageVisuals` (Archaea glow).

## Epic 5 MVP vs. what exists

| Epic 5 MVP requirement | Status |
|---|---|
| Matter Core / Interventions UI in the inspect panel | ✅ `CellInterventionUI` (mounted in inspect) |
| Create Life as a purchasable intervention | ✅ `CreateArchaea` (note: **repeatable** — many cells, not one-time) |
| Server-authoritative purchase + Matter deduction | ✅ `PlayerManager` |
| Owned/purchased state tracking | ✅ profile `cells` / `cascadeTriggered` / `dustMultiplier` |
| Planet attribute updates from upgrades | ✅ `EvolutionTier` / `EvolutionStage` |
| Data-driven definitions (shared IDs UI↔server) | ✅ `OrganelleData` (organelle-scoped) |
| Clear success/failure feedback | ✅ BiosphereView + stage visuals |
| No competing global Create-Life button | ✅ old `MatterConverterUI` removed (8E) |

## Gap (what Epic 5 wants that does NOT yet exist)

1. A **generic, category-based intervention definition** format with `requirements` / locked
   "Coming Soon" states / repeatability — beyond the organelle path (§7.2, §12.2).
2. **Non-organelle interventions** (Nourish Microbes, Stabilize Oceans, Accelerate Mutation) as
   locked/preview cards — these introduce `LifeProgress` / `Stability`, which the
   GameplayProgressionVision marks as **Epic 6 (Early Evolution Progression)**.
3. Extension documentation (§Ticket 5.7) for how Epic 6 plugs in.

## ⚠️ Coordination risk (why we paused before writing code)

Nova **owns this lane and is actively extending it** — he has **unmerged** branches
`nova/dynamic-pricing-1c` (Sprint 1C: `Pricing.luau`, `MulticellularData.luau`, `PurchaseUpgrade`)
and `nova/dev-menu`. Building a parallel `UpgradeDefinitions` + generic purchase pipeline now would
duplicate his system and collide with that work — exactly what §13.1 and Risk 2 warn against.

**Recommendation:** treat Epic 5 as *formalize + extend + document*, not *rebuild*. Deliver the
generic intervention-definition format as an **additive** layer the existing organelle flow and
future interventions both conform to, and write the Epic 6 extension docs — done in coordination
with Nova, not on top of his unmerged branches.

**Status:** 5A ✅ complete. 5B–5F gated on the scope decision below (coordinate with Nova).
