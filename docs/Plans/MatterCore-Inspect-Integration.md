# Matter Core + Planet Inspect UI Integration Plan

**Project:** Grow A [X]  
**Purpose:** Make the Planet Inspect UI and Matter Converter / Create Life flow feel like one seamless system.  
**Status:** ✅ v0 implemented 2026-06-19 (on `tien/integration-matter-planets`) — pending in-Studio playtest  
**Primary coordination:** Tien + Nova  
**Recommended owner split:** Tien owns planet inspect UX/stylization; Nova owns Matter spending/server economy.

---

## Implementation status (2026-06-19)

Implemented in one pass while Nova was idle, to be pushed to `main` as the shared base:

- **Phase 1 (entry points):** the global "Create Life" button is renamed **"Matter Core"** (`MatterConverterUI.luau`); its panel is now a read-only **overview** (Matter / Owned / Production) — its own Create button was removed, so there is a single create path.
- **Phase 2 (context):** `MatterConverterUI` now requires `PlanetInspectContext` and shows the inspected planet's name (or "No planet inspected — press E…"), reacting to `Changed`.
- **Phase 3 (in-panel Create Life):** the inspect panel's old "Open Matter Converter" button is replaced by an **Intervention** section — Create Life with cost / effect / owned / production + a styled **[Create Life]** button (`PlanetInteraction.client.luau`).
- **Phase 4 (server spend):** the button fires the existing `CreateArchaea` remote; `PlayerManager` stays authoritative (validate → deduct → increment). The inspect button subscribes to `MatterUpdate`/`ConverterUpdate` for affordability + "Owned".
- **Phase 5 (stage update):** `PlayerManager.onCreateArchaea` sets `EvolutionTier=1` / `EvolutionStage="Archaea"` on the player's planet when the first cell is created, so the inspect panel flips to "Archaea / Microbial" and `PlanetStageVisuals` shows the glow automatically.
- **Phase 6 (labels):** "Matter Core" (menu) vs "Create Life" (planet action).

**Deferred / to confirm in playtest:** Phase 7 manual test pass; camera/UX taste tuning; whether the Matter Core panel should stay reachable by **C** at all (currently yes, as an overview shortcut).

---

## One-sentence goal

Unify the current Planet Inspect panel and Nova's Matter Converter / Create Life system so the player has one clear, planet-contextual path:

```text
Fly to Origin World
→ Press E to inspect
→ See planet info
→ Create Life from the same inspect-styled UI
→ Matter is spent server-side
→ planet updates to Archaea
```

---

## Current problem

The current UI has two competing entry points:

```text
Top-right HUD:
Create Life

Planet Inspect Panel:
Open Matter Converter
```

This is confusing because the player does not know where upgrades/interventions are supposed to happen:

- Is Create Life a global action?
- Is it connected to the planet?
- Is the Matter Converter a separate menu?
- Why does the inspect panel have an Open Matter Converter button that does not lead to the actual action?

The systems technically work, but the UX feels disconnected.

---

## Design decision

Use the **existing Planet Inspect menu stylization** as the main visual language.

Do **not** replace the inspect UI.

Instead, fold Matter Converter / Create Life functionality into the inspect-styled UI so planet info and planet interventions feel like one coherent interaction.

### Core rule

```text
Create Life is a planet intervention, not a random global HUD button.
```

### Matter Converter role

The Matter Converter / Matter Core should be the tool that powers interventions, but the first action should be shown in planet context.

Good direction:

```text
Inspect Origin World
→ Intervention section appears
→ Create Life
```

Bad direction:

```text
Random top-right Create Life button
→ player clicks it without planet context
```

---

## Target player flow

1. Player flies around and collects Matter.
2. Player uses the planet marker or R return-home to find Origin World.
3. Player presses E near the planet to inspect it.
4. Right-side inspect panel opens using the current stylization.
5. Panel shows planet information.
6. Panel includes an Intervention section.
7. Player clicks Create Life.
8. Client requests the purchase.
9. Server validates Matter cost.
10. Server deducts Matter and increments Archaea count.
11. Server updates planet attributes:
    - `EvolutionTier = 1`
    - `EvolutionStage = "Archaea"`
12. Matter HUD updates.
13. Inspect panel updates.
14. Archaea glow appears on the planet.

---

## Final UI direction

### Remove / replace this current disconnected setup

```text
Top-right:
[Create Life]

Inspect Panel:
[Open Matter Converter]
```

### Replace with this

```text
Top-right:
[Matter Core] or [Matter Converter]
```

or hide the global button entirely for now.

Inside inspect mode:

```text
PEPPERROCKET's World

Archetype      Ocean
Stage          Prebiotic
Life           Dormant
Civilization   None
Water          75%
Clouds         59%
Atmosphere     Moderate

Intervention
Create Life
Cost: 15 Matter
Effect: Creates the first Archaea Cell
Owned: 0
Production: +1 Matter / 5 sec

[Create Life]

[E] / [Backspace] Exit
```

---

## Recommended implementation approach

Use the inspect panel as the immediate v0 interface.

The Matter Converter can still exist as a concept and shortcut, but for the first playable loop the player should be able to create life directly inside the planet inspect panel.

### Why this is better

- Fewer clicks.
- Less confusing.
- The planet remains the emotional anchor.
- Create Life clearly belongs to the inspected planet.
- Nova's server-side economy can still own the actual purchase logic.

---

## Files likely involved

### Client / UI

```text
src/client/PlanetInteraction.client.luau
src/client/PlanetInspectContext.luau
src/client/MatterConverterUI.luau
```

### Server / economy

```text
src/server/PlayerManager.luau
```

### Shared config/remotes if needed

```text
src/shared/Remotes.luau
src/shared/GameConfig.luau
```

### Docs

```text
docs/EPICS/Epic4.md
docs/EPICS/Epic3.md
HANDOFF.md
```

---

## Files to avoid unless necessary

```text
src/shared/PlanetGenerator.luau
src/server/PlayerPlanetService.luau
src/shared/DustField.luau
src/server/WorldBuilder.luau
DataStore files / saving systems
prestige systems
multiplayer trade / war systems
full 9-tier evolution implementation
```

---

# Phase 1: Clean up competing UI entry points

## Goal

Remove the current confusion where Create Life appears globally while the inspect panel has a separate nonfunctional Matter Converter button.

## Tasks

1. Find the top-right Create Life button in `MatterConverterUI.luau` or whichever UI file owns it.
2. Remove it, hide it, or rename it.
3. Preferred rename if keeping a global button:

```text
Matter Core
```

or

```text
Matter Converter
```

4. The global button should open the converter panel, not directly perform Create Life.
5. If the player is not inspecting a planet, the converter should show:

```text
Inspect your Origin World to apply planet interventions.
```

## Acceptance criteria

- There is no standalone global Create Life button disconnected from the planet.
- The player sees only one clear path to Create Life.
- The UI language is consistent:

```text
Matter Core / Matter Converter = tool/menu
Create Life = planet intervention/action
```

---

# Phase 2: Wire inspect context into the converter

## Goal

Make the existing `PlanetInspectContext` seam actually useful to Nova's converter UI.

## Existing seam

`PlanetInteraction` should already set context when inspect mode starts:

```lua
{
    type = "Planet",
    planetModel = planet,
    planetId = planet:GetAttribute("PlanetId"),
    ownerUserId = planet:GetAttribute("OwnerUserId"),
    displayName = planet:GetAttribute("DisplayName") or "Origin World",
}
```

`PlanetInteraction` should clear context when inspect exits.

## Tasks

1. In `MatterConverterUI.luau`, require `PlanetInspectContext`.
2. Listen for `OpenRequested`.
3. Optionally listen for `Changed` to track active planet context live.
4. When `OpenRequested` fires:
   - open the converter UI
   - read the active context
   - display the inspected planet name
5. If context is missing, show a safe fallback state.

## Expected behavior

Clicking `Open Matter Converter` from the inspect panel should no longer do nothing. It should open the converter UI in planet context.

## Acceptance criteria

- Inspect mode sets planet context.
- Exiting inspect clears planet context.
- MatterConverterUI can read active planet context.
- Clicking the inspect-panel button opens the converter.
- Converter displays the inspected planet name.
- No errors if context is missing.

---

# Phase 3: Prefer direct Create Life inside the inspect panel

## Goal

Since the team agreed to use the inspect menu stylization, put the first intervention directly into the inspect-styled UI.

## Recommended v0 UI

Replace this:

```text
[Open Matter Converter]
```

with this:

```text
Intervention
Create Life
Cost: 15 Matter
Effect: Creates the first Archaea Cell
Owned: 0
Production: +1 Matter / 5 sec

[Create Life]
```

Optional small text:

```text
Powered by Matter Core
```

## Tasks

1. Add an Intervention section to the inspect panel.
2. Display current Matter balance if accessible, or rely on existing Matter HUD.
3. Display Archaea count from converter state if available.
4. Add Create Life button inside the inspect panel.
5. Style it to match the existing inspect panel:
   - same rounded corners
   - same blue/cyan border language
   - same dark translucent background
   - no random green floating button detached from context

## Acceptance criteria

- The Create Life button appears inside the inspect-styled UI.
- The old disconnected top-right Create Life button is removed or renamed.
- The player does not need to understand two separate upgrade menus.
- The interaction reads as a planet intervention.

---

# Phase 4: Connect Create Life to Nova's server logic

## Goal

Use Nova's existing server-authoritative Create Archaea system.

## Existing likely systems

- `CreateArchaea` remote
- `ConverterUpdate` remote
- `MATTER_CONVERTER_COST_ARCHAEA`
- `ARCHAEA_PRODUCTION_INTERVAL`
- `ARCHAEA_PRODUCTION_AMOUNT`
- server-side cost validation in `PlayerManager`
- Matter deduction and `archaeaCount` increment

## Required behavior

When the Create Life button is clicked:

1. Client checks Matter only for visual button enable/disable.
2. Client fires `CreateArchaea` remote.
3. Server re-checks affordability.
4. Server deducts Matter.
5. Server increments `archaeaCount`.
6. Server fires `MatterUpdate`.
7. Server fires `ConverterUpdate`.
8. Client updates UI.

## Important security rule

```text
The client never decides the purchase.
The client only requests the purchase.
The server validates everything.
```

## Acceptance criteria

- If player has enough Matter, clicking Create Life spends Matter and creates an Archaea Cell.
- If player does not have enough Matter, button is disabled or server rejects safely.
- Matter HUD updates.
- Archaea count updates.
- No duplicate purchases from spam clicking.
- No client-only fake purchases.

---

# Phase 5: Update planet stage after first life creation

## Goal

Make the planet visually respond after the first successful Create Life purchase.

## Existing visual hook

`PlanetStageVisuals.client.luau` reacts to:

```text
EvolutionTier >= 1
```

or

```text
EvolutionStage == "Archaea"
```

## Tasks

On the server, after the first Archaea Cell is successfully created, set attributes on the player's planet model:

```lua
planet:SetAttribute("EvolutionTier", 1)
planet:SetAttribute("EvolutionStage", "Archaea")
```

Suggested condition:

```text
if archaeaCount goes from 0 to 1:
    set EvolutionTier = 1
    set EvolutionStage = "Archaea"
```

If player creates additional cells:

```text
keep EvolutionTier = 1 for now
keep EvolutionStage = "Archaea"
```

Do not implement the full 9-tier system here.

## Expected player feedback

Before purchase:

```text
Stage: Prebiotic
Life: Dormant
```

After purchase:

```text
Stage: Archaea
Life: Microbial
```

The planet should show the subtle Archaea glow.

## Acceptance criteria

- After first Create Life purchase, planet attributes update.
- Inspect panel changes to Archaea / Microbial.
- Archaea glow appears.
- This uses existing visual hook.
- No full evolution tree added.

---

# Phase 6: Label and copy cleanup

## Preferred player-facing labels

Global/menu name:

```text
Matter Core
```

or

```text
Matter Converter
```

Planet action:

```text
Create Life
```

Flavor text:

```text
Use Matter to spark the first primitive life on this world.
```

Technical/internal terms:

```text
CreateArchaea
archaeaCount
EvolutionTier = 1
EvolutionStage = "Archaea"
```

## Avoid

```text
Upgrade shop
Buy upgrade
Create Life floating outside planet context
multiple buttons doing the same thing
```

---

# Phase 7: Testing plan

## Manual test checklist

1. Start Play.
2. Confirm Matter HUD appears.
3. Collect enough Matter.
4. Return to Origin World with R.
5. Press E to inspect.
6. Confirm inspect panel appears with current styling.
7. Confirm there is no confusing top-right standalone Create Life button.
8. Confirm Create Life appears inside the inspect/menu flow.
9. Click Create Life.
10. Confirm Matter decreases.
11. Confirm Archaea count increases.
12. Confirm planet stage updates to Archaea.
13. Confirm planet glow appears.
14. Exit inspect mode.
15. Re-enter inspect mode.
16. Confirm panel still shows Archaea / Microbial state.
17. Press C if the converter shortcut remains.
18. Confirm it opens the same styled/conceptual Matter Core, not a disconnected random action.
19. Try clicking without enough Matter.
20. Confirm it fails cleanly.

---

# Definition of Done

This integration is done when:

- There is one clear UI path for Create Life.
- Inspect menu stylization is preserved.
- Matter Converter / Matter Core is connected to planet context.
- `Open Matter Converter` either works or is replaced by direct Create Life.
- Top-right `Create Life` button is removed or renamed.
- Server remains authoritative for spending.
- Planet stage updates after first life creation.
- Archaea glow appears after successful creation.
- No DataStore added.
- No full 9-tier system added.
- No unrelated systems added.
- No Output errors.
- Epic docs and `HANDOFF.md` are updated.

---

# Recommended Discord handoff

```text
We agreed to keep the inspect menu stylization. Next integration task is to unify the Matter Converter / Create Life flow with the inspect panel.

Goal: no more random top-right Create Life button. Create Life should appear as a planet intervention inside the inspect-styled UI, or the top-right button should become a general Matter Core button.

The client can request CreateArchaea, but server still validates/deducts Matter. After first successful Create Life, server should set EvolutionTier = 1 and EvolutionStage = "Archaea" on the player's planet so the existing Archaea glow + inspect panel update kicks in.
```
