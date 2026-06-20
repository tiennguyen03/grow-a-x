# Epic 6 — Ecosystem Interventions & Early Evolution Progression

**Project:** Grow A [X]  
**Epic Type:** Core Gameplay Progression / Early Strategy Layer  
**Status:** Planned / Ready for implementation planning  
**Primary Owner:** Tien for inspect/UI/ecosystem layer, with Nova coordination for biology/economy integration  
**Primary Goal:** Turn the read-only `Ecosystem Interventions` preview into a real, server-authoritative, planet-level progression system using **Life Progress** and **Stability**, while preserving Nova's existing **Cell Cultures / organelle / Multicellular Path** as the microscopic life progression lane.

---

## 0. Executive Summary

Epic 6 is the bridge between the current working biology system and the larger civilization-progression vision.

The game already has:

```text
Fly through space
→ collect Matter
→ inspect Origin World
→ create Archaea / cells
→ upgrade cells through organelles
→ evolve toward Eukaryotic / Multicellular paths
→ see life through Biosphere View
```

That is a strong microscopic progression loop.

However, the game still needs the first layer of **planet-level strategy**.

Epic 6 introduces that layer through:

```text
Life Progress
Stability
Ecosystem Interventions
first simple biological event
clear path toward Multicellular / Complex Life
```

The key design relationship is:

```text
Cell Cultures = microscopic life progression
Ecosystem Interventions = planet-level evolution strategy
```

These should not compete. They should work together.

Epic 6 should **not** replace Nova's cell upgrades. It should give those upgrades a larger planet context.

The player-facing loop becomes:

```text
Create / evolve cells
→ cells generate Matter and biological capacity
→ spend Matter on Ecosystem Interventions
→ Life Progress and Stability change
→ planet moves toward the next era
→ events and visuals respond
```

---

## 1. Why Epic 6 Exists

Epic 5 formalized the Matter Core / intervention direction and added read-only future cards. It clarified that the upgrade system should not become endless generic number boosts.

Epic 6 is where those future cards become real gameplay.

The problem we are solving:

```text
Cell upgrades are working, but the planet itself still needs meaningful progression decisions.
```

Without Epic 6, the early game risks becoming:

```text
make cell
upgrade cell
make another cell
upgrade another cell
repeat forever
```

That is better than a raw cookie clicker, but it still needs a larger strategic layer.

Epic 6 adds the first simple strategic tension:

```text
Fast evolution vs stable evolution
```

The player should start asking:

```text
Do I push life forward quickly, or do I keep the ecosystem stable?
```

That is the first step toward the larger Civ-adjacent game.

---

## 2. Relationship To Existing Systems

### 2.1 Epic 3 / Nova's Biology Lane

Nova's existing and in-progress systems own the microscopic life layer:

```text
Create Archaea / cells
Organelles
Eukaryotic evolution
Eukaryotic Cascade
Dust Multiplier
Biosphere View
Multicellular Path / dynamic pricing
future cell/body/tier upgrades
```

Epic 6 must respect that.

Do **not** create a second cell-upgrade path.

Do **not** create a second “become multicellular” path that ignores Nova's work.

Instead, Epic 6 should provide planet-level support around that path.

### 2.2 Epic 5 / Matter Core Additive Layer

Epic 5 added / planned a generic intervention definition layer:

```text
InterventionData
InterventionPreviewUI
Coming Soon cards
Nourish Microbes
Stabilize Oceans
Accelerate Mutation
```

Epic 6 activates those cards.

Epic 5 also intentionally deferred the live generic purchase pipeline. Epic 6 is where the non-organelle intervention purchase pipeline should be implemented.

### 2.3 Epic 4 / Planet Inspect

Epic 4 made the Origin World inspectable and established the inspect panel as the correct place for planet-centered actions.

Epic 6 should continue that rule:

```text
Ecosystem Interventions live in the inspect panel.
```

They should sit below or near `Cell Cultures`, using the same visual language.

### 2.4 Epic 2 / Planet Identity

The planet generator exposes attributes like:

```text
DisplayName
Archetype
WaterCoverage
CloudCoverage
AtmosphereThickness
EvolutionTier
EvolutionStage
```

Epic 6 should add new planet/profile state such as:

```text
LifeProgress
Stability
LifeEra
```

or equivalent names.

These values should be visible in inspect UI and eventually feed visuals/events.

---

## 3. Design Pillars

### Pillar 1 — Planet-Level Strategy, Not More Cell Micro

Cell Cultures answers:

```text
What life forms do I have?
How developed are they?
How much do they produce?
```

Ecosystem Interventions answers:

```text
What conditions am I creating for that life?
Is the ecosystem healthy?
Am I pushing evolution safely or dangerously?
```

Both are needed.

### Pillar 2 — Keep It Casual

Epic 6 should not introduce a complicated simulation.

No hexes.  
No workers.  
No manual species management.  
No 20 resources.  
No hard-core 4X spreadsheet.

The player should make simple, readable decisions:

```text
Nourish Microbes
Stabilize Oceans
Accelerate Mutation
Respond to Mass Algae Bloom
```

### Pillar 3 — Strategy Through Tradeoffs

Each action should have a clear purpose.

Safe action:

```text
Nourish Microbes → reliable Life Progress
```

Defensive action:

```text
Stabilize Oceans → Stability
```

Risky action:

```text
Accelerate Mutation → more Life Progress, less Stability
```

This creates strategy without complexity.

### Pillar 4 — Server Authority

All ecosystem interventions must be validated on the server.

The client may request an intervention.

The server decides:

```text
Does the intervention exist?
Is it active?
Does the player meet requirements?
Can the player afford it?
How does it affect Life Progress / Stability?
Should the planet stage update?
```

### Pillar 5 — Integrate With Nova, Do Not Duplicate Nova

Epic 6 should avoid duplicating these:

```text
CreateArchaea
PurchaseOrganelle
PurchaseUpgrade / Multicellular branch if present
cell production math
organelle data
Biosphere rendering rules
```

If Nova's dynamic pricing / Multicellular branch is merged, Epic 6 should read and support it, not replace it.

### Pillar 6 — The Planet Must React

The player should see changes.

At minimum:

```text
Life Progress bar updates
Stability value updates
Stage text updates
success/failure messages show
planet visuals get subtle feedback
```

Later:

```text
more microbial tint
ocean shimmer
ecosystem pulse
biome glow
multicellular vegetation hints
```

---

## 4. Core Concepts

## 4.1 Life Progress

**Life Progress** represents how far the planet's biosphere has advanced toward the next biological era.

It is not the same as cell count.

Cell count means:

```text
How many cells exist?
```

Life Progress means:

```text
How much has the planet's ecosystem matured?
```

Recommended initial range:

```text
Life Progress: 0 / 100
```

When Life Progress reaches 100, the planet becomes eligible for the next milestone.

Example:

```text
Archaea Era
Life Progress 100 / 100
→ Multicellular transition becomes available or boosted
```

Important: if Nova's Multicellular Path already defines the actual transition, Life Progress should act as a requirement/support value, not an alternate transition.

Possible integration options:

```text
Option A: Life Progress unlocks Nova's Multicellular Path section.
Option B: Life Progress reduces cost / boosts progress on Nova's Multicellular upgrades.
Option C: Life Progress is required before final Multicellular completion.
Option D: Life Progress is only a visible ecosystem track for now, with stage transition deferred.
```

Recommended first implementation:

```text
Life Progress is visible and accumulates.
At 100, show “Ready for Multicellular Path” / “Ecosystem Matured”.
Do not force stage transition until Nova's path integration is agreed.
```

This avoids conflict.

---

## 4.2 Stability

**Stability** represents the health and resilience of the planet's ecosystem.

Recommended initial range:

```text
Stability: 0–100
```

Suggested starting value after first life:

```text
Stability = 70 or 75
```

High Stability means:

```text
life grows safely
events are less harmful
risky interventions are safer
future civilization starts healthier
```

Low Stability means:

```text
more biological events
slower progress
greater risk from mutation/disaster choices
possible production penalties later
```

In Epic 6, Stability should be simple.

Do not yet build a full disaster simulator.

Initial use:

```text
Stabilize Oceans increases Stability.
Accelerate Mutation lowers Stability.
Mass Algae Bloom event reads Stability.
```

---

## 4.3 Ecosystem Interventions

Ecosystem Interventions are Matter-powered actions that affect planet-level life conditions.

They are distinct from Cell Cultures.

They should be shown under a section named:

```text
Ecosystem Interventions
```

Bridge copy:

```text
Shape the world around your cells so life can grow, stabilize, and evolve.
```

Initial interventions:

```text
Nourish Microbes
Stabilize Oceans
Accelerate Mutation
```

Future interventions:

```text
Encourage Biodiversity
Protect Fragile Ecosystems
Encourage Cooperation
Encourage Curiosity
Nudge Problem Solving
```

Epic 6 should focus on the first three.

---

## 4.4 Biological Events

Events are small choice moments that make the planet feel alive.

Epic 6 should implement at most one simple event, probably:

```text
Mass Algae Bloom
```

This should be a light system.

No huge event framework yet.

The event should teach:

```text
Life growth can create consequences.
Stability matters.
The player can respond with Matter or accept a tradeoff.
```

---

## 5. Target Player Flow

### 5.1 Player With No Life Yet

```text
1. Player collects Matter.
2. Player inspects Origin World.
3. Cell Cultures shows Create Archaea / Create Cell.
4. Ecosystem Interventions are locked or hidden until life exists.
5. Player creates first cell.
6. Planet stage becomes Archaea.
7. Ecosystem Interventions unlock.
```

### 5.2 Player In Archaea Era

```text
1. Player inspects planet.
2. Cell Cultures shows cells / organelles / production.
3. Ecosystem Interventions shows Life Progress and Stability.
4. Player chooses one:
   - Nourish Microbes
   - Stabilize Oceans
   - Accelerate Mutation
5. Server validates Matter and requirements.
6. Matter is deducted.
7. Life Progress / Stability update.
8. UI and planet feedback update.
```

### 5.3 Player Reaches Life Progress 100

```text
1. Life Progress reaches 100.
2. UI shows “Ecosystem Matured” or “Ready for Multicellular Life.”
3. If Nova's Multicellular Path is present, it unlocks / highlights.
4. If not present yet, the game shows a milestone placeholder.
```

Do not create a competing multicellular button without agreement.

---

## 6. MVP Scope

### 6.1 In Scope

Epic 6 MVP includes:

```text
Life Progress field
Stability field
server-authoritative ApplyIntervention handler
ApplyIntervention remote
active Nourish Microbes
active Stabilize Oceans
active Accelerate Mutation
Ecosystem Interventions UI updated from preview to interactive
inspect panel display of Life Progress and Stability
basic success/failure feedback
optional/simple Mass Algae Bloom event
stage/visual hooks for Life Progress or ecosystem pulse
Epic docs + handoff updates
```

### 6.2 Out Of Scope

Epic 6 does not include:

```text
full Sentience Progress
full Civilization Projects
full Technology tree
full Doctrine system
DataStore saving
Offline progression
Nearby Worlds
Trade routes
War
Probes
Dark Forest mechanics
complex disasters
full procedural terrain rewrite
full species simulation
```

### 6.3 Stretch Scope

Stretch goals only after MVP works:

```text
Life Progress milestone animation
simple Multicellular readiness badge
one biological event
small planet visual shimmer based on Stability
small Biosphere View hint when Life Progress changes
```

---

## 7. Data Model

## 7.1 Player Profile Fields

Add to the existing profile in `PlayerManager` or equivalent server profile owner:

```lua
profile.lifeProgress = 0
profile.stability = 75
profile.ecosystemInterventions = {
    -- optional counts or history
}
```

Recommended names:

```text
lifeProgress
stability
```

Avoid uppercase inconsistency unless existing profile style uses uppercase.

### Initial Values

Before life exists:

```text
lifeProgress = 0
stability = nil or 0 or 75 hidden
```

After first cell / Archaea:

```text
lifeProgress = 0
stability = 75
```

Recommendation:

```text
Initialize fields on profile creation, but only display/use them after life exists.
```

This makes code simpler.

---

## 7.2 Planet Attributes

Add/update attributes on the local player's planet model so client visuals and inspect UI can read them:

```text
LifeProgress
Stability
```

Optional:

```text
LifeProgressMax = 100
EcosystemState = "Stable" / "Unstable" / "Maturing"
```

Recommended minimum:

```text
LifeProgress
Stability
```

These should update whenever the server applies an intervention.

---

## 7.3 ConverterUpdate Payload

Extend the existing `ConverterUpdate` payload to include:

```lua
{
    -- existing fields
    archaeaCount = number,
    cells = table,
    totalProduction = number,
    dustMultiplier = number,
    cascadeTriggered = boolean,

    -- new Epic 6 fields
    lifeProgress = number,
    lifeProgressMax = 100,
    stability = number,
}
```

This lets existing UI systems update without creating too many new remotes.

---

## 7.4 InterventionData Definitions

`InterventionData` should become the source of truth for ecosystem intervention definitions.

Example conceptual definitions:

```lua
nourish_microbes = {
    id = "nourish_microbes",
    displayName = "Nourish Microbes",
    category = "Ecosystem",
    description = "Feed the first fragile ecosystems and help microbial life spread.",
    cost = { Matter = 20 },
    repeatable = true,
    requirements = {
        lifeExists = true,
        minEvolutionTier = 1,
    },
    effects = {
        addLifeProgress = 20,
    },
    state = "Active",
    sortOrder = 100,
}
```

```lua
stabilize_oceans = {
    id = "stabilize_oceans",
    displayName = "Stabilize Oceans",
    category = "Ecosystem",
    description = "Calm violent seas so fragile life can survive and multiply.",
    cost = { Matter = 25 },
    repeatable = true,
    requirements = {
        lifeExists = true,
        minEvolutionTier = 1,
    },
    effects = {
        addStability = 15,
    },
    state = "Active",
    sortOrder = 110,
}
```

```lua
accelerate_mutation = {
    id = "accelerate_mutation",
    displayName = "Accelerate Mutation",
    category = "Ecosystem",
    description = "Force faster adaptation. Evolution moves quickly, but the ecosystem becomes less stable.",
    cost = { Matter = 25 },
    repeatable = true,
    requirements = {
        lifeExists = true,
        minEvolutionTier = 1,
    },
    effects = {
        addLifeProgress = 35,
        addStability = -10,
    },
    state = "Active",
    sortOrder = 120,
}
```

---

## 8. Intervention Behavior

## 8.1 Nourish Microbes

### Player-facing role

Safe ecosystem growth.

### Player-facing copy

```text
Feed the first fragile ecosystems and help microbial life spread.
```

### Cost

```text
20 Matter
```

### Effect

```text
Life Progress +20
```

### Risk

```text
None
```

### Purpose

This is the simple default action.

It teaches the player:

```text
Matter can help the whole planet's life progress.
```

### UI state

Available when:

```text
player has at least one cell
EvolutionTier >= 1
EvolutionStage is Archaea/Eukaryotic or later
```

---

## 8.2 Stabilize Oceans

### Player-facing role

Safe defensive/ecological action.

### Player-facing copy

```text
Calm the planet's oceans so fragile life can survive and multiply.
```

### Cost

```text
25 Matter
```

### Effect

```text
Stability +15
```

Clamp:

```text
Stability cannot exceed 100.
```

### Risk

```text
None
```

### Purpose

This teaches the player:

```text
Progress is not everything. Conditions matter.
```

It prepares future event/disaster gameplay.

---

## 8.3 Accelerate Mutation

### Player-facing role

Risky fast-growth option.

### Player-facing copy

```text
Force faster adaptation. Evolution moves quickly, but the ecosystem becomes less stable.
```

### Cost

```text
25 Matter
```

### Effect

```text
Life Progress +35
Stability -10
```

Clamp:

```text
Stability cannot go below 0.
```

### Purpose

This is the first strategic tradeoff.

It teaches:

```text
You can rush evolution, but instability builds.
```

---

## 9. Requirements And Locking

### 9.1 Before Life Exists

Ecosystem Interventions should show locked or hidden.

Recommended UI:

```text
Ecosystem Interventions
Create your first Cell Culture to shape the ecosystem.
```

Cards may show locked state:

```text
Requires first cell.
```

### 9.2 After First Cell

Unlock the three interventions.

### 9.3 When Not Enough Matter

Cards should be visible but button disabled.

Example:

```text
Need 20 Matter
```

### 9.4 When Life Progress Is Maxed

If Life Progress is already 100:

- `Nourish Microbes` and `Accelerate Mutation` can either be disabled or still usable for overflow later.

Recommendation for MVP:

```text
Disable Life Progress actions at 100.
Show “Ecosystem Matured”.
```

Keep `Stabilize Oceans` available if Stability is below 100.

### 9.5 Stability At Max

If Stability is 100:

```text
Stabilize Oceans button disabled or shows “Stability already maxed”.
```

---

## 10. Server Implementation Plan

## 10.1 Remote

Add a new RemoteEvent in `Remotes.luau`:

```text
ApplyIntervention
```

Direction:

```text
Client → Server
```

Payload:

```lua
{
    interventionId = "nourish_microbes"
}
```

Alternative simple payload:

```lua
"nourish_microbes"
```

Recommended:

```text
use a table payload for future extensibility.
```

### Optional Result Remote

Could add:

```text
InterventionResult
```

Direction:

```text
Server → Client
```

Payload:

```lua
{
    interventionId = string,
    success = boolean,
    message = string,
}
```

But if existing UI can infer state from `MatterUpdate` / `ConverterUpdate`, this may not be necessary.

Recommended MVP:

```text
Use ApplyIntervention request + existing ConverterUpdate.
Add InterventionResult only if UI needs explicit failure messages.
```

---

## 10.2 Server Handler

Add `onApplyIntervention(player, payload)` in `PlayerManager` or a new service if architecture allows.

Recommended flow:

```text
1. Extract interventionId.
2. Look up InterventionData.get(interventionId).
3. Reject if not found.
4. Reject if state is not Active.
5. Load player profile.
6. Validate life/stage requirements.
7. Validate cost.
8. Validate caps/max rules.
9. Deduct Matter.
10. Apply effects.
11. Clamp values.
12. Update planet attributes.
13. Fire MatterUpdate.
14. Fire ConverterUpdate.
15. Optionally fire InterventionResult success.
```

---

## 10.3 Requirement Checks

Supported MVP requirements:

```text
lifeExists
minEvolutionTier
maxLifeProgress
stabilityBelowMax
```

Example:

```lua
local function requirementsMet(profile, planet, def)
    if def.requirements.lifeExists and #profile.cells <= 0 then
        return false, "Create your first cell first."
    end

    if def.requirements.minEvolutionTier then
        local tier = planet:GetAttribute("EvolutionTier") or profile.evolutionTier or 0
        if tier < def.requirements.minEvolutionTier then
            return false, "Requires life on your planet."
        end
    end

    return true
end
```

Use actual current profile/planet data shape.

---

## 10.4 Effect Application

Supported MVP effects:

```text
addLifeProgress
addStability
```

Clamps:

```text
Life Progress: 0–100
Stability: 0–100
```

Example:

```lua
profile.lifeProgress = math.clamp(profile.lifeProgress + addLifeProgress, 0, 100)
profile.stability = math.clamp(profile.stability + addStability, 0, 100)
```

When Life Progress reaches 100, optionally set:

```text
EcosystemState = "Matured"
```

or:

```text
ReadyForMulticellular = true
```

Recommended MVP:

```text
Set profile.readyForMulticellular = true only if Nova agrees.
Otherwise show UI milestone only.
```

---

## 10.5 Planet Attribute Sync

After applying effects:

```lua
planet:SetAttribute("LifeProgress", profile.lifeProgress)
planet:SetAttribute("Stability", profile.stability)
```

Optional:

```lua
planet:SetAttribute("LifeProgressMax", 100)
```

The inspect panel should read these attributes or the `ConverterUpdate` payload.

---

## 10.6 Matter Deduction Order

Recommended order:

```text
validate first
then deduct Matter
then apply effects
then push updates
```

Avoid deducting Matter before all checks pass.

---

## 11. Client UI Implementation Plan

## 11.1 Promote Preview Cards To Interactive Cards

Current `InterventionPreviewUI` renders read-only cards.

Epic 6 can either:

```text
Option A: extend InterventionPreviewUI into InterventionUI with interactive states.
Option B: create EcosystemInterventionUI and leave PreviewUI as legacy/read-only.
```

Recommended:

```text
Create/rename to EcosystemInterventionUI if the code would become clearer.
```

But keep file churn low if possible.

---

## 11.2 Target Section Layout

```text
Life Interventions

Cell Cultures
[existing Nova UI]

Ecosystem Interventions
Shape the world around your cells so life can grow, stabilize, and evolve.

Life Progress: 40 / 100  [progress bar]
Stability: 75%           [small badge/bar]

[Nourish Microbes]
[Stabilize Oceans]
[Accelerate Mutation]
```

---

## 11.3 Card States

Each card should support:

```text
Available
Unaffordable
Locked
Maxed
Applying / cooldown optional
```

ComingSoon should disappear once Epic 6 makes them live.

Example states:

### Available

```text
Nourish Microbes
Cost 20 Matter · Life Progress +20
[Apply]
```

### Unaffordable

```text
Nourish Microbes
Cost 20 Matter · Need 8 more Matter
[Not Enough Matter]
```

### Locked

```text
Nourish Microbes
Requires first Cell Culture.
```

### Maxed

```text
Nourish Microbes
Ecosystem Matured.
```

---

## 11.4 Success Feedback

On successful intervention:

```text
small toast
card flash
Life Progress bar animates
Stability value animates
optional planet pulse
```

Example messages:

```text
Microbes nourished. Life Progress +20.
Oceans stabilized. Stability +15.
Mutation accelerated. Life Progress +35, Stability -10.
```

---

## 11.5 Failure Feedback

If server rejects:

```text
Not enough Matter.
Create your first cell first.
Ecosystem already matured.
Unknown intervention.
```

Failure should not silently do nothing.

---

## 11.6 Refresh Sources

Client should refresh when:

```text
MatterUpdate received
ConverterUpdate received
InterventionResult received if used
inspect panel opens
planet attributes change
```

Avoid polling if existing event updates are enough.

---

## 12. Integration With Nova's Systems

## 12.1 Cell Cultures Should Stay First

Cell Cultures should remain above Ecosystem Interventions because the player must create life before shaping the ecosystem.

Recommended hierarchy:

```text
Life Interventions
├── Cell Cultures
└── Ecosystem Interventions
```

## 12.2 Do Not Duplicate Multicellular Path

If Nova's Multicellular Path exists:

```text
Life Progress should support/unlock/highlight it.
```

Do not create a separate `Evolve Multicellular Life` button unless it is explicitly integrated with Nova's upgrade path.

## 12.3 Possible Integration With Multicellular Path

Potential designs:

### Design A — Life Progress unlocks Multicellular Path

```text
Life Progress reaches 100
→ Multicellular Path section unlocks
```

### Design B — Life Progress boosts Multicellular upgrades

```text
Each 20 Life Progress gives small discount / requirement progress.
```

### Design C — Life Progress is independent but thematic

```text
Life Progress reaches 100
→ UI milestone only for now
→ Nova path still controls actual transition
```

Recommended MVP:

```text
Design C first, then Design A after coordination.
```

This avoids merge/design conflict.

---

## 13. Visual Feedback Plan

## 13.1 MVP Visuals

Do not overbuild visuals in Epic 6.

MVP:

```text
progress bar movement
small success toast
small planet pulse/overlay intensity change
```

## 13.2 Planet Visual Hooks

`PlanetStageVisuals` currently reacts to `EvolutionTier` / `EvolutionStage`.

Epic 6 could add:

```text
LifeProgress-driven subtle glow intensity
Stability-driven color/tint/particle pulse later
```

Suggested MVP:

```text
When an intervention succeeds, pulse existing Archaea glow briefly.
```

Do not make permanent complex visuals yet.

## 13.3 Biosphere View Hooks

`BiosphereView` is Nova-owned.

Do not edit it without coordination.

Potential future hooks:

```text
Nourish Microbes → vessel sparkle
Accelerate Mutation → fast cell motion pulse
Stabilize Oceans → calming blue pulse
```

These are optional and require Nova coordination.

---

## 14. Event System Mini-Scope

## 14.1 Should Epic 6 Include Events?

Recommended:

```text
Only include one simple event if the intervention MVP is stable.
```

The event should be small and mostly self-contained.

## 14.2 First Event: Mass Algae Bloom

### Trigger

Potential trigger:

```text
Life Progress >= 60
Stability <= 60
Event not already resolved
```

or:

```text
after Accelerate Mutation has been used 2–3 times
```

Keep it simple.

### Player-facing text

```text
Mass Algae Bloom
Your oceans surge with unstable microbial growth. The ecosystem can adapt naturally, but intervention may prevent long-term instability.
```

### Choices

```text
Let Nature Adapt
Effect: +Adaptive tendency later / no Matter cost / slower progress or small Stability loss

Stabilize Oceans
Cost: 25 Matter
Effect: Stability +15

Accelerate Mutation
Cost: 25 Matter
Effect: Life Progress +20, Stability -10
```

### MVP Simplification

If events are too much for this epic, document this event and defer it to Epic 8.

Recommended for implementation:

```text
Do not implement full event choice UI in Epic 6 unless time allows.
```

---

## 15. File Plan

### Likely touched files

```text
src/shared/InterventionData.luau
src/client/InterventionPreviewUI.luau or new EcosystemInterventionUI.luau
src/client/PlanetInteraction.client.luau
src/server/PlayerManager.luau
src/shared/Remotes.luau
src/client/PlanetStageVisuals.client.luau optional
```

### Files to coordinate before touching

```text
src/server/PlayerManager.luau
src/shared/Remotes.luau
src/client/CellInterventionUI.luau
src/client/BiosphereView.client.luau
src/shared/MulticellularData.luau if merged
src/shared/Pricing.luau if merged
```

### Files to avoid unless necessary

```text
src/shared/OrganelleData.luau
Nova's dynamic pricing branch files
BiosphereView visuals
CellInterventionUI internals
```

---

## 16. Sprint Breakdown

# Sprint 6A — Audit Current Biology / Upgrade State

## Goal

Confirm what is currently in `main` and what Nova has in active branches before implementing Epic 6.

## Tasks

- Read current `Epic3.md`, `Epic5.md`, `HANDOFF.md`, `HANDOFF-NOVA.md`, `HANDOFF-TIEN.md`.
- Check whether Nova's dynamic Multicellular branch is merged.
- Identify current `ConverterUpdate` payload shape.
- Identify current `PlayerManager` profile fields.
- Identify current `InterventionData` / preview UI status.
- Decide whether Epic 6 will add `ApplyIntervention` now or wait for Nova's branch.

## Acceptance Criteria

- No blind coding.
- We know whether `PurchaseUpgrade` / Multicellular Path exists in the current base.
- Handoff notes document what can be touched safely.

---

# Sprint 6B — Life Progress + Stability Data Foundation

## Goal

Add the basic server/profile/planet state for Life Progress and Stability.

## Tasks

- Add `lifeProgress` field to player profile.
- Add `stability` field to player profile.
- Set starting values.
- Add values to `ConverterUpdate` payload.
- Set planet attributes `LifeProgress` and `Stability`.
- Clamp values on updates.
- Ensure values initialize correctly on join and after Create Life.

## Acceptance Criteria

- Server stores Life Progress and Stability.
- Client receives Life Progress and Stability.
- Inspect UI can read them.
- No gameplay buttons active yet if Sprint 6C not done.
- Existing cell/organelle flow still works.

---

# Sprint 6C — Server-Authoritative ApplyIntervention Pipeline

## Goal

Allow non-organelle ecosystem interventions to be applied through one safe server path.

## Tasks

- Add `ApplyIntervention` remote.
- Add server handler `onApplyIntervention`.
- Read definitions from `InterventionData`.
- Validate active state.
- Validate requirements.
- Validate Matter cost.
- Deduct Matter.
- Apply effects.
- Push `MatterUpdate` and `ConverterUpdate`.
- Add failure messages if needed.

## Acceptance Criteria

- Client cannot fake Life Progress or Stability.
- Unknown intervention IDs are rejected.
- Not enough Matter is rejected.
- Locked interventions are rejected.
- Successful interventions update Matter/profile/planet/UI.
- Existing Create Cell / organelle purchases still work.

---

# Sprint 6D — Interactive Ecosystem Interventions UI

## Goal

Turn the read-only preview section into a real interaction section.

## Tasks

- Rename section to `Ecosystem Interventions`.
- Add bridge copy.
- Show Life Progress bar.
- Show Stability value/bar.
- Render active intervention cards.
- Add buttons for Nourish Microbes, Stabilize Oceans, Accelerate Mutation.
- Disable buttons for locked/unaffordable/maxed states.
- Fire `ApplyIntervention` on click.
- Refresh from `ConverterUpdate` / Matter changes.

## Acceptance Criteria

- Cards are interactive when requirements are met.
- Cards are clearly disabled when not affordable/locked.
- UI copy makes the Cell Cultures vs Ecosystem distinction clear.
- No duplicate Create Life path added.
- No old `Future Interventions` label remains in player-facing UI.

---

# Sprint 6E — Ecosystem Feedback And Milestone State

## Goal

Make ecosystem interventions feel responsive and show a clear milestone at Life Progress 100.

## Tasks

- Animate Life Progress changes.
- Animate Stability changes.
- Show success toast per intervention.
- Add small planet pulse on success if safe.
- Show `Ecosystem Matured` or `Ready for Multicellular Life` at 100.
- Decide final text depending on Nova integration.

## Acceptance Criteria

- Player can see interventions worked.
- Life Progress 100 is obvious.
- The UI does not imply a fake transition if Nova's Multicellular path is not integrated yet.

---

# Sprint 6F — Nova Multicellular Integration Point

## Goal

Connect Life Progress to Nova's Multicellular Path without duplicating it.

## Tasks

- Coordinate with Nova.
- Pick one integration model:
  - Life Progress unlocks Multicellular Path.
  - Life Progress highlights Multicellular Path.
  - Life Progress remains a separate readiness milestone for now.
- Update UI copy accordingly.
- Avoid creating a second Multicellular purchase path.
- Document the decision.

## Acceptance Criteria

- No duplicate evolution route exists.
- Player understands how ecosystem progress relates to cell/body progression.
- Nova's lane remains intact.

---

# Sprint 6G — First Biological Event: Mass Algae Bloom

## Goal

Add one simple biological event to prove Stability matters.

## Tasks

- Add event trigger condition.
- Add simple event UI or use a temporary inspect-panel alert.
- Add 2–3 response choices.
- Apply effects server-side.
- Prevent event spam.
- Document event behavior.

## Acceptance Criteria

- Event appears under controlled conditions.
- Player gets meaningful choices.
- Effects update Life Progress/Stability.
- Event does not punish offline players or create frustration.

**Note:** This sprint is optional if Epic 6 MVP is already large.

---

# Sprint 6H — QA, Docs, Handoff

## Goal

Finalize Epic 6 documentation and testing.

## Tasks

- Update `docs/EPICS/Epic6.md`.
- Update relevant handoff file(s).
- Document remotes.
- Document profile fields.
- Document intervention definitions.
- Document how to add future ecosystem interventions.
- Run regression tests.

## Acceptance Criteria

- Future sessions understand the system.
- Existing Nova flow still works.
- Epic 6 can be handed off safely.

---

## 17. Ticket List

## Ticket 6.1 — Audit Current Biology State

**Type:** Investigation / Docs  
**Priority:** Critical

### Description

Before implementation, inspect current merged code and Nova's handoff to avoid duplicating active work.

### Acceptance

- Confirm whether dynamic Multicellular branch is merged.
- Confirm current remotes.
- Confirm current profile shape.
- Confirm current UI mount points.

---

## Ticket 6.2 — Add Life Progress / Stability Fields

**Type:** Server / Data  
**Priority:** Critical

### Description

Add in-session state fields for ecosystem progression.

### Acceptance

- Profile has `lifeProgress` and `stability`.
- ConverterUpdate includes those fields.
- Planet attributes sync.

---

## Ticket 6.3 — Activate InterventionData Entries

**Type:** Shared Data  
**Priority:** High

### Description

Change the three Epic 6 definitions from `ComingSoon` to `Active` and add any required metadata.

### Acceptance

- `nourish_microbes`, `stabilize_oceans`, and `accelerate_mutation` have costs/effects/requirements.
- Shared data is used by server and UI.

---

## Ticket 6.4 — ApplyIntervention Remote + Handler

**Type:** Server  
**Priority:** Critical

### Description

Add generic server-authoritative purchase path for ecosystem interventions.

### Acceptance

- Valid interventions apply correctly.
- Invalid requests reject safely.
- Matter cannot go negative.
- Values clamp correctly.

---

## Ticket 6.5 — Ecosystem UI Interactive Cards

**Type:** Client UI  
**Priority:** High

### Description

Turn preview cards into active cards with buttons and state display.

### Acceptance

- Player can apply each intervention.
- UI displays Life Progress and Stability.
- UI explains locked/unaffordable/maxed states.

---

## Ticket 6.6 — Milestone Feedback

**Type:** UX / Visual  
**Priority:** Medium

### Description

Show satisfying feedback when interventions apply and when Life Progress reaches 100.

### Acceptance

- Progress bar animates.
- Success messages show.
- Maturity milestone is visible.

---

## Ticket 6.7 — Multicellular Integration Decision

**Type:** Design / Coordination  
**Priority:** High

### Description

Decide with Nova how Life Progress relates to the Multicellular Path.

### Acceptance

- Decision documented.
- No duplicate path created.

---

## Ticket 6.8 — Mass Algae Bloom Event

**Type:** Gameplay Event  
**Priority:** Optional / Stretch

### Description

Add first biological event if MVP is stable.

### Acceptance

- Event appears under clear conditions.
- Player choices affect Stability/Life Progress.
- Event does not spam.

---

## 18. Testing Plan

## 18.1 Regression Test Existing Flow

```text
1. Start game.
2. Collect Matter.
3. Inspect Origin World.
4. Create first cell.
5. Buy organelles.
6. Confirm Biosphere View still works.
7. Confirm Archaea/Eukaryotic progression still works.
```

## 18.2 Ecosystem Unlock Test

```text
1. Inspect planet before creating a cell.
2. Confirm Ecosystem Interventions are locked/hidden.
3. Create first cell.
4. Confirm Ecosystem Interventions unlock.
```

## 18.3 Nourish Microbes Test

```text
1. Get at least 20 Matter.
2. Apply Nourish Microbes.
3. Confirm Matter decreases by 20.
4. Confirm Life Progress increases by 20.
5. Confirm UI updates.
6. Confirm planet attribute updates.
```

## 18.4 Stabilize Oceans Test

```text
1. Lower Stability below 100 if needed.
2. Apply Stabilize Oceans.
3. Confirm Matter decreases by 25.
4. Confirm Stability increases by 15, clamped to 100.
5. Confirm UI updates.
```

## 18.5 Accelerate Mutation Test

```text
1. Get at least 25 Matter.
2. Apply Accelerate Mutation.
3. Confirm Matter decreases by 25.
4. Confirm Life Progress increases by 35.
5. Confirm Stability decreases by 10, clamped to 0.
6. Confirm UI warns about tradeoff.
```

## 18.6 Insufficient Matter Test

```text
1. Have less Matter than required.
2. Try applying an intervention.
3. Confirm server rejects.
4. Confirm Matter and stats do not change.
5. Confirm UI displays failure/disabled state.
```

## 18.7 Max Progress Test

```text
1. Reach Life Progress 100.
2. Confirm Life Progress actions become maxed or disabled.
3. Confirm milestone message appears.
4. Confirm Stabilize Oceans still works if Stability < 100.
```

## 18.8 Multiplayer Safety Test

```text
1. Test with two players if possible.
2. Confirm each player's interventions affect only their own Origin World.
3. Confirm no cross-player UI leaks.
```

## 18.9 Respawn / Reinspect Test

```text
1. Apply intervention.
2. Exit inspect.
3. Re-enter inspect.
4. Confirm values remain for session.
5. Reset character.
6. Reinspect and confirm UI still works.
```

---

## 19. Risk List

### Risk 1 — Duplicating Nova's Multicellular Path

Epic 6 could accidentally create a second path to Multicellular Life.

**Mitigation:** Treat Life Progress as ecosystem readiness/support until Nova integration is decided.

### Risk 2 — UI Gets Too Crowded

Inspect panel already has planet info, Cell Cultures, and future cards.

**Mitigation:** Keep the Ecosystem section compact. Use progress bars and collapsible/scrollable cards if needed.

### Risk 3 — Too Many Stats Too Soon

Adding Life Progress, Stability, cell count, dust multiplier, production, organelles, and future paths can overwhelm players.

**Mitigation:** Explain with grouping:

```text
Cell Cultures = cells
Ecosystem Interventions = planet conditions
```

### Risk 4 — Server Data Shape Gets Messy

If values are stored in multiple places without sync rules, UI and planet attributes can disagree.

**Mitigation:** Server profile is source of truth. Planet attributes/client payload mirror it.

### Risk 5 — Progress Is Too Fast Or Too Slow

Costs/effects may need tuning.

**Mitigation:** Keep constants in data definitions. Playtest.

### Risk 6 — DataStore Later

Epic 6 state is likely in-session only until saving exists.

**Mitigation:** Document fields so Epic 9/DataStore can save them later.

---

## 20. Balancing Notes

Initial values are intentionally simple:

```text
Life Progress max: 100
Stability max: 100
Starting Stability after life: 75
Nourish Microbes: 20 Matter → +20 Life Progress
Stabilize Oceans: 25 Matter → +15 Stability
Accelerate Mutation: 25 Matter → +35 Life Progress, -10 Stability
```

Why these work:

```text
Nourish = safe but slower
Stabilize = defensive/preparation
Accelerate = fastest but risky
```

Expected path:

```text
5 Nourish Microbes = 100 Life Progress, safe but costs 100 Matter
3 Accelerate Mutation = 105 Life Progress, costs 75 Matter but -30 Stability
mixed path lets player balance risk
```

This is the first meaningful strategic choice.

---

## 21. Documentation Requirements

When implemented, update:

```text
docs/EPICS/Epic6.md
HANDOFF.md if global state changes
HANDOFF-TIEN.md or HANDOFF-NOVA.md depending on owner
CLAUDE.md only if workflow/file ownership changes
```

Docs should include:

```text
new remotes
new profile fields
new planet attributes
new intervention definitions
how to add a new ecosystem intervention
how Life Progress relates to Nova's path
known limitations
playtest results
```

---

## 22. Handoff Summary Format

After each Epic 6 work session, use:

```markdown
## Epic 6 Handoff Summary

### What Changed
-

### Files Changed
-

### Interventions Added / Changed
-

### Remotes Added / Used
-

### Player Profile Fields Added
-

### Planet Attributes Added
-

### Nova Coordination Notes
-

### How To Test
-

### Known Issues
-

### Deferred Work
-

### Handoff File Updated
- HANDOFF.md / HANDOFF-TIEN.md / HANDOFF-NOVA.md / None
```

---

## 23. Definition Of Done

Epic 6 MVP is complete when:

- `LifeProgress` exists server-side.
- `Stability` exists server-side.
- Values are sent to client.
- Values are mirrored to planet attributes.
- Ecosystem Interventions are renamed/positioned clearly in inspect UI.
- `Nourish Microbes` is active and server-authoritative.
- `Stabilize Oceans` is active and server-authoritative.
- `Accelerate Mutation` is active and server-authoritative.
- UI clearly shows costs, effects, and tradeoffs.
- UI shows Life Progress and Stability.
- Server rejects invalid/unaffordable/locked requests.
- Existing Cell Cultures / organelle / Biosphere View still works.
- Life Progress 100 shows a clear milestone without duplicating Nova's Multicellular path.
- Docs and handoff are updated.

---

## 24. Final Epic Thesis

Epic 6 is the first real strategic layer of Grow A [X].

It does not make the game heavy.

It does not add hexes, workers, or serious 4X micromanagement.

It adds simple planet-level choices:

```text
Grow life safely.
Stabilize the world.
Push evolution faster at a cost.
```

This is how the game begins to evolve from:

```text
make cells and buy upgrades
```

toward:

```text
shape the conditions of an entire civilization-bearing world
```

The core relationship remains:

```text
Cell Cultures = what life exists
Ecosystem Interventions = what world that life grows inside
```

That distinction keeps the game clear, casual, and expandable.
