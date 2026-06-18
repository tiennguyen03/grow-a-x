# Epic 0 — Sprint 0D: Boost + Speed Feel + Home Anchor

**Project codename:** Grow A [X]  
**Epic:** Epic 0 — World Traversal  
**Sprint:** Sprint 0D  
**Sprint status:** Not Started  
**Primary owner:** Tien  
**Second dev:** Nova  
**Main goal:** Make floating through the void feel faster, clearer, and more usable before adding deeper planet systems.

---

## 1. Sprint Summary

Sprint 0D improves the core traversal feel.

The player already floats freely through a dark void, moves with camera-relative controls, has no gravity, sees a starfield/centerpiece star, and has a soaring/banking pose while moving.

This sprint adds the next layer of feel:

1. **Boost movement** so long-distance travel feels better.
2. **Camera FOV smoothing** so boost feels fast without needing complex VFX.
3. **Simple boost VFX** so the player gets a clear visual cue while moving fast.
4. **Home planet visual anchor** so the void has a clear destination/reference point.
5. **Return-home key** so testers do not get lost in empty space.

This sprint is still about traversal and environment feel only. It should not add planet gameplay, upgrades, saving, events, or civilization systems.

---

## 2. Design Intent

The player should feel like a powerful space-level entity floating through a void and moving between cosmic points of interest.

The movement should feel:

- Smooth
- Fast when needed
- Easy to control
- Slightly floaty
- Not like normal Roblox walking
- Not like slippery ice
- Good enough to enjoy testing repeatedly

The world should feel:

- Dark
- Spatial
- Large
- Easy to orient within
- Not completely empty

The home planet is only a visual anchor for now. It is not a real gameplay planet yet.

---

## 3. Current Foundation

Already complete from earlier Epic 0 work:

- Baseplate deleted.
- SpawnLocation deleted.
- Player spawns at/near origin.
- `Workspace.Gravity = 0`.
- Lighting configured as a dark void.
- Starfield generated from source.
- Centerpiece star generated from source.
- Movement script exists at `src/client/SpaceMovement.client.luau`.
- Player moves with WASD, camera-relative.
- Space moves up.
- Left Ctrl / Left Shift currently move down.
- Movement is applied through `AssemblyLinearVelocity`.
- Character uses a soaring pose while moving.
- Character banks into turns.
- Default running footstep sound is muted.

Already complete from Epic 1:

- Influence generation exists.
- Influence UI exists.
- Server profile starts with `influence = 0` and `influencePerSec = 1`.

Epic 1 should not be touched during this sprint.

---

## 4. Sprint 0D Scope

### In Scope

- Shift boost movement.
- Left Ctrl as the only descend key.
- Smooth FOV increase while boosting.
- Smooth FOV return when boost ends.
- Simple boost particles/trail.
- Home planet visual object.
- Optional home planet atmosphere shell.
- R key return-home safety teleport.
- Small movement tuning pass.

### Out of Scope

Do **not** add any of the following:

- Influence upgrades.
- DataStore saving.
- Planet stats.
- Planet UI.
- Civilization simulation.
- Events/disasters.
- Multiplayer visiting.
- Server-authoritative movement.
- Complex orbital mechanics.
- Click-to-travel.
- Planet inspect mode.
- Prompt UI.
- New economy systems.
- New permanent progression systems.

---

## 5. Target Player Experience

After Sprint 0D, a player should be able to:

1. Spawn into the dark void.
2. See stars, the centerpiece star, and a nearby home planet.
3. Float around normally with WASD.
4. Move up with Space.
5. Move down with Left Ctrl.
6. Hold Left Shift to boost quickly through the void.
7. Feel the camera widen during boost.
8. See subtle boost VFX while boosting.
9. Press R to return near the home planet if they get lost.
10. Continue testing movement without errors.

---

## 6. Controls After Sprint 0D

| Input | Action |
|---|---|
| W | Move forward relative to camera |
| A | Move left relative to camera |
| S | Move backward relative to camera |
| D | Move right relative to camera |
| Space | Move up |
| Left Ctrl | Move down |
| Left Shift | Boost |
| R | Return near home planet |
| Mouse | Default Roblox camera |

Important change:

- **Left Shift should no longer move down.**
- **Left Shift becomes boost only.**
- **Left Ctrl is the only descend key.**

---

## 7. File Ownership Plan

This matters because the team is only two people and we want to avoid merge conflicts.

### Tien Owns Movement

Tien owns this file for Sprint 0D:

```text
src/client/SpaceMovement.client.luau
```

Tien implements:

- Boost input.
- Shift/Control input cleanup.
- Boost speed.
- Boost acceleration.
- FOV smoothing.
- Return-home key.
- Movement tuning.
- Boost VFX if it is directly inside the movement script.

Nova should **not** edit `SpaceMovement.client.luau` during this sprint unless Tien explicitly hands it off.

### Nova Owns Environment

Nova owns this file for Sprint 0D:

```text
src/server/WorldBuilder.luau
```

Nova implements:

- Home planet sphere.
- Home planet atmosphere shell.
- Optional minor lighting/visual polish.

Tien should **not** edit `WorldBuilder.luau` during this sprint unless Nova explicitly hands it off.

### Optional Future Split

If `SpaceMovement.client.luau` gets too large later, create separate files in a future sprint:

```text
src/client/BoostVFX.client.luau
src/shared/MovementConfig.luau
```

Do not create them during this sprint unless absolutely necessary.

---

## 8. Branch Plan

### Tien Branch

```bash
git checkout main
git pull origin main
git checkout -b feature/0d-boost-movement
```

### Nova Branch

```bash
git checkout main
git pull origin main
git checkout -b feature/0d-home-planet
```

---

## 9. Recommended Merge Order

Recommended order:

1. Nova finishes `feature/0d-home-planet`.
2. Nova opens PR.
3. Tien reviews and merges.
4. Tien pulls latest `main`.
5. Tien finishes `feature/0d-boost-movement`.
6. Tien opens PR.
7. Nova reviews/tests.
8. Merge movement branch.

Reason:

The return-home position in the movement script should match the home planet location created in `WorldBuilder.luau`.

---

# 10. Tickets / Tasks

For this team, “ticket” and “task” mean the same thing.

---

## Ticket 0D-01 — Add Home Planet Visual Anchor

**Owner:** Nova  
**Branch:** `feature/0d-home-planet`  
**Primary file:** `src/server/WorldBuilder.luau`  
**Conflict risk:** Low, as long as Tien does not touch `WorldBuilder.luau`

### Goal

Add a simple home planet near spawn so the player has a destination and scale reference in the void.

This is not a real gameplay planet yet. It is only a visual anchor.

### Requirements

- Create a `HomePlanet` sphere inside the existing `SpaceEnvironment` folder.
- Create a slightly larger transparent atmosphere shell named `HomePlanetAtmosphere`.
- Both objects must be generated from source inside `WorldBuilder.build()`.
- Both objects must be anchored.
- Both objects must be non-collidable.
- Planet should be visible from spawn.
- Planet should not block movement testing.
- Planet should not duplicate after multiple Play sessions.
- Existing centerpiece star and starfield must still work.
- No UI.
- No interaction prompt.
- No planet stats.
- No Influence logic.

### Suggested Constants

Add near the top of `WorldBuilder.luau`:

```lua
local HOME_PLANET_POS = Vector3.new(0, 0, -180)
local HOME_PLANET_RADIUS = 35
local HOME_PLANET_COLOR = Color3.fromRGB(80, 130, 255)
```

### Suggested Hierarchy

```text
Workspace
└── SpaceEnvironment
    ├── CenterpieceStar
    ├── StarField
    ├── HomePlanet
    └── HomePlanetAtmosphere
```

### Suggested Implementation

```lua
local planet = Instance.new("Part")
planet.Name = "HomePlanet"
planet.Shape = Enum.PartType.Ball
planet.Size = Vector3.new(
    HOME_PLANET_RADIUS * 2,
    HOME_PLANET_RADIUS * 2,
    HOME_PLANET_RADIUS * 2
)
planet.Position = HOME_PLANET_POS
planet.Anchored = true
planet.CanCollide = false
planet.Material = Enum.Material.SmoothPlastic
planet.Color = HOME_PLANET_COLOR
planet.Parent = environmentFolder

local atmosphere = Instance.new("Part")
atmosphere.Name = "HomePlanetAtmosphere"
atmosphere.Shape = Enum.PartType.Ball
atmosphere.Size = Vector3.new(
    HOME_PLANET_RADIUS * 2.15,
    HOME_PLANET_RADIUS * 2.15,
    HOME_PLANET_RADIUS * 2.15
)
atmosphere.Position = HOME_PLANET_POS
atmosphere.Anchored = true
atmosphere.CanCollide = false
atmosphere.Material = Enum.Material.ForceField
atmosphere.Transparency = 0.65
atmosphere.Color = Color3.fromRGB(120, 180, 255)
atmosphere.Parent = environmentFolder
```

Adjust variable names if `WorldBuilder.luau` already uses different local names.

### Acceptance Criteria

Done when:

- Home planet appears in the void.
- Atmosphere shell appears around it.
- Home planet is visible from spawn.
- Home planet lives inside `SpaceEnvironment`.
- No duplicate planets appear after repeated Play sessions.
- Existing starfield still appears.
- Existing centerpiece star still appears.
- No Output errors.

### Test Steps

1. Pull latest `main`.
2. Create `feature/0d-home-planet` branch.
3. Implement changes in `WorldBuilder.luau`.
4. Run Rojo.
5. Open Roblox Studio.
6. Press Play.
7. Confirm home planet appears near spawn.
8. Stop Play.
9. Press Play again.
10. Confirm there is still only one `HomePlanet` and one `HomePlanetAtmosphere`.
11. Fly around the planet.
12. Confirm there are no collision issues.
13. Check Output for errors.

---

## Ticket 0D-02 — Add Boost Input + Boost Speed

**Owner:** Tien  
**Branch:** `feature/0d-boost-movement`  
**Primary file:** `src/client/SpaceMovement.client.luau`  
**Conflict risk:** Low, as long as Nova does not touch `SpaceMovement.client.luau`

### Goal

Add a boost mode that lets the player fly faster through the void.

### Requirements

- Left Shift becomes the boost key.
- Left Shift no longer moves the player downward.
- Left Ctrl remains the descend key.
- Holding Left Shift increases movement speed.
- Releasing Left Shift returns movement to normal speed.
- Boost only matters when movement input exists.
- Boost should not break current soaring pose.
- Boost should not break banking.
- Boost should not require server code.
- Boost should not touch Epic 1 Influence systems.

### Suggested Constants

Update/add constants near the top of `SpaceMovement.client.luau`:

```lua
local MOVE_SPEED = 40
local BOOST_SPEED = 95
local VERTICAL_SPEED = 35

local ACCELERATION = 8
local BOOST_ACCELERATION = 6
local DECELERATION = 10
```

If the file already has `MOVE_SPEED`, `VERTICAL_SPEED`, `ACCELERATION`, or `DECELERATION`, update existing constants instead of duplicating them.

### Implementation Notes

The existing script likely tracks input states and calculates a movement direction each frame.

Add a boost input state:

```lua
local inputState = {
    forward = false,
    backward = false,
    left = false,
    right = false,
    up = false,
    down = false,
    boost = false,
}
```

When input begins:

```lua
if input.KeyCode == Enum.KeyCode.LeftShift then
    inputState.boost = true
end
```

When input ends:

```lua
if input.KeyCode == Enum.KeyCode.LeftShift then
    inputState.boost = false
end
```

Make sure Left Shift is removed from descend logic.

Descend should only be:

```lua
if input.KeyCode == Enum.KeyCode.LeftControl then
    inputState.down = true
end
```

In the movement loop:

```lua
local isBoosting = inputState.boost and inputDirection.Magnitude > 0
local targetSpeed = isBoosting and BOOST_SPEED or MOVE_SPEED
local targetAcceleration = isBoosting and BOOST_ACCELERATION or ACCELERATION

local desiredVelocity = inputDirection * targetSpeed
```

Then use the existing velocity smoothing system.

### Acceptance Criteria

Done when:

- Holding Shift increases movement speed.
- Releasing Shift returns speed to normal.
- Ctrl moves down.
- Shift does not move down anymore.
- Space still moves up.
- WASD still works.
- Character still banks while turning.
- Character still uses the soaring pose while moving.
- No Output errors.

### Test Steps

1. Press Play.
2. Hold W and confirm normal movement.
3. Hold W + Shift and confirm boosted movement.
4. Release Shift and confirm normal speed returns.
5. Press Space and confirm upward movement.
6. Press Left Ctrl and confirm downward movement.
7. Press Left Shift alone and confirm no weird movement occurs.
8. Turn while boosting and confirm banking still works.
9. Check Output for errors.

---

## Ticket 0D-03 — Add Camera FOV Smoothing During Boost

**Owner:** Tien  
**Branch:** `feature/0d-boost-movement`  
**Primary file:** `src/client/SpaceMovement.client.luau`

### Goal

Make boosting feel faster by smoothly widening the camera FOV while boost is active.

### Requirements

- Normal FOV should be around `70`.
- Boost FOV should be around `84`.
- FOV should interpolate smoothly.
- FOV should not snap instantly.
- FOV should return to normal when boost ends.
- FOV should reset correctly after respawn.
- No server code.

### Suggested Constants

```lua
local NORMAL_FOV = 70
local BOOST_FOV = 84
local FOV_SMOOTH = 8
```

### Suggested Implementation

Inside the `RenderStepped` loop, after `isBoosting` is known:

```lua
local camera = workspace.CurrentCamera
if camera then
    local targetFov = isBoosting and BOOST_FOV or NORMAL_FOV
    local alpha = math.clamp(dt * FOV_SMOOTH, 0, 1)
    camera.FieldOfView = camera.FieldOfView + (targetFov - camera.FieldOfView) * alpha
end
```

When the script starts or character resets, make sure the camera does not stay stuck at boost FOV.

Optional reset:

```lua
local camera = workspace.CurrentCamera
if camera then
    camera.FieldOfView = NORMAL_FOV
end
```

### Acceptance Criteria

Done when:

- Camera widens while boosting.
- Camera returns smoothly when boost stops.
- No harsh snap.
- FOV does not get stuck after respawn.
- No Output errors.

### Test Steps

1. Press Play.
2. Fly normally and observe FOV.
3. Hold Shift while moving.
4. Confirm FOV widens smoothly.
5. Release Shift.
6. Confirm FOV returns smoothly.
7. Reset character if possible.
8. Confirm FOV returns to normal after reset.
9. Check Output for errors.

---

## Ticket 0D-04 — Add Simple Boost VFX

**Owner:** Tien  
**Branch:** `feature/0d-boost-movement`  
**Primary file:** `src/client/SpaceMovement.client.luau`

### Goal

Add a small visual effect that turns on when boosting and turns off when not boosting.

### Why Tien Owns This

This VFX depends directly on the boost state inside the movement script. To avoid merge conflicts and unnecessary architecture, keep it in the movement script for now.

### Requirements

- Create boost VFX once per character spawn.
- Attach VFX to the character/root part.
- VFX should be disabled by default.
- VFX should enable only while boosting.
- VFX should disable when boost ends.
- VFX should not duplicate after respawn.
- VFX should be subtle.
- VFX should not block the camera.
- No external asset required.

### Suggested Implementation

During character setup, after getting `rootPart`:

```lua
local boostAttachment = Instance.new("Attachment")
boostAttachment.Name = "BoostVFXAttachment"
boostAttachment.Parent = rootPart

local boostParticles = Instance.new("ParticleEmitter")
boostParticles.Name = "BoostParticles"
boostParticles.Enabled = false
boostParticles.Rate = 40
boostParticles.Lifetime = NumberRange.new(0.25, 0.45)
boostParticles.Speed = NumberRange.new(8, 14)
boostParticles.SpreadAngle = Vector2.new(15, 15)
boostParticles.LightEmission = 0.8
boostParticles.Parent = boostAttachment
```

Inside `RenderStepped`:

```lua
if boostParticles then
    boostParticles.Enabled = isBoosting
end
```

If the script already recreates character references on respawn, store `boostParticles` in an outer variable and replace it on each character setup.

### Acceptance Criteria

Done when:

- Boost VFX appears while boosting.
- Boost VFX disappears after releasing Shift.
- VFX does not duplicate after respawn.
- VFX is not visually annoying.
- No Output errors.

### Test Steps

1. Press Play.
2. Hold W + Shift.
3. Confirm boost VFX appears.
4. Release Shift.
5. Confirm boost VFX disappears.
6. Reset character.
7. Boost again.
8. Confirm VFX still works and did not duplicate.
9. Check Output for errors.

---

## Ticket 0D-05 — Add Return Home Key

**Owner:** Tien  
**Branch:** `feature/0d-boost-movement`  
**Primary file:** `src/client/SpaceMovement.client.luau`

### Goal

Add a simple return-home key so the player can recover if they fly too far away.

This is mainly a dev/testing convenience, but it also supports the future player experience.

### Requirements

- Pressing R moves the player near the home planet.
- Pressing R resets velocity to zero.
- Pressing R should not kill/respawn the player.
- It should be client-side for now.
- It should not use server remotes.
- It should not add UI.
- It should not touch Influence systems.

### Suggested Constant

If Nova uses `HOME_PLANET_POS = Vector3.new(0, 0, -180)`, use:

```lua
local RETURN_HOME_POS = Vector3.new(0, 20, -90)
```

This places the player in front of and slightly above the home planet, not inside it.

### Suggested Implementation

In input began logic:

```lua
if input.KeyCode == Enum.KeyCode.R then
    if rootPart then
        rootPart.AssemblyLinearVelocity = Vector3.zero
        rootPart.AssemblyAngularVelocity = Vector3.zero
        rootPart.CFrame = CFrame.new(RETURN_HOME_POS)
        currentVelocity = Vector3.zero
    end
end
```

If `currentVelocity` is local to the loop, reset whatever velocity state the script uses.

### Acceptance Criteria

Done when:

- Pressing R returns the player near the home planet.
- Velocity resets to zero.
- Player does not keep flying after teleport.
- Movement still works after teleport.
- Camera still works after teleport.
- No Output errors.

### Test Steps

1. Press Play.
2. Fly far away.
3. Press R.
4. Confirm player appears near home planet.
5. Confirm velocity is stopped.
6. Move again after teleport.
7. Confirm movement still works.
8. Check Output for errors.

---

## Ticket 0D-06 — Final Movement Tuning Pass

**Owner:** Tien  
**Branch:** `feature/0d-boost-movement`  
**Primary file:** `src/client/SpaceMovement.client.luau`

### Goal

Tune the movement constants after boost, FOV, VFX, and return-home are working.

### Requirements

Only tune constants unless there is a real bug.

Review:

- Normal movement speed.
- Boost speed.
- Vertical speed.
- Acceleration.
- Boost acceleration.
- Deceleration.
- FOV values.
- FOV smoothing.
- Bank sensitivity.
- Orientation smoothing.

### Suggested Final Starting Values

```lua
local MOVE_SPEED = 40
local BOOST_SPEED = 95
local VERTICAL_SPEED = 35

local ACCELERATION = 8
local BOOST_ACCELERATION = 6
local DECELERATION = 10

local NORMAL_FOV = 70
local BOOST_FOV = 84
local FOV_SMOOTH = 8

local ORIENT_SMOOTH = 9
local POSE_MIN_SPEED = 3
local BANK_SENSITIVITY = 0.18
local BANK_SMOOTH = 6
local MAX_BANK = math.rad(55)
```

### Feel Targets

Normal movement should feel:

```text
smooth, controlled, floaty
```

Boost should feel:

```text
fast, satisfying, still controllable
```

Stopping should feel:

```text
slightly floaty, not icy
```

Turning should feel:

```text
smooth and readable, not spinny
```

FOV should feel:

```text
noticeable, but not nauseating
```

### Acceptance Criteria

Done when:

- Normal movement feels good near objects.
- Boost feels useful for longer distances.
- Boost does not feel uncontrollable.
- FOV is noticeable but not too aggressive.
- Banking does not over-roll during boost.
- The character does not snap weirdly between poses.
- No Output errors.

---

# 11. AI Coding Prompts

Use these prompts for Claude Code or another AI coding agent.

---

## Prompt for Nova — Home Planet Branch

```text
We are working on Epic 0 Sprint 0D for a Roblox project called Grow A [X].

Implement a simple home planet visual anchor in `src/server/WorldBuilder.luau`.

Current WorldBuilder already:
- removes/rebuilds `SpaceEnvironment`
- configures dark void lighting
- creates a centerpiece star
- creates a seeded star field

Requirements:
1. Add constants:
   - HOME_PLANET_POS = Vector3.new(0, 0, -180)
   - HOME_PLANET_RADIUS = 35
   - HOME_PLANET_COLOR = Color3.fromRGB(80, 130, 255)
2. Create a `HomePlanet` sphere inside `SpaceEnvironment`.
3. Create a slightly larger transparent ForceField atmosphere shell named `HomePlanetAtmosphere`.
4. Both should be anchored and non-collidable.
5. Planet should rebuild from source on every Play.
6. No duplicate planets after repeated Play.
7. Existing centerpiece star and starfield must still work.
8. Do not add planet stats.
9. Do not add UI.
10. Do not add interaction prompt.
11. Do not touch movement or influence systems.

Acceptance criteria:
- Home planet appears near spawn.
- It is visible in the void.
- It lives inside `SpaceEnvironment`.
- It does not duplicate on rebuild.
- Existing centerpiece star and starfield still work.
- No Output errors.
```

---

## Prompt for Tien — Boost Movement Branch

```text
We are working on Epic 0 Sprint 0D for a Roblox project called Grow A [X].

Implement boost traversal in `src/client/SpaceMovement.client.luau`.

Current movement already supports:
- WASD camera-relative floating movement
- Space to move up
- Left Ctrl / Left Shift currently move down
- gravity is 0
- character uses soaring pose and banking while moving
- movement is applied with AssemblyLinearVelocity

Requirements:
1. Make Left Shift a boost key instead of descend.
2. Keep Left Ctrl as the only descend key.
3. Add boost speed while Shift is held and player is moving.
4. Add smooth camera FOV increase while boosting.
5. Add simple boost particles or trail that enables only while boosting.
6. Add R key to return player near home planet at Vector3.new(0, 20, -90), reset velocity to zero.
7. Do not add server code.
8. Do not add UI.
9. Do not touch influence systems.
10. Keep the script self-contained and clean.

Suggested constants:
- MOVE_SPEED = 40
- BOOST_SPEED = 95
- VERTICAL_SPEED = 35
- ACCELERATION = 8
- BOOST_ACCELERATION = 6
- DECELERATION = 10
- NORMAL_FOV = 70
- BOOST_FOV = 84
- FOV_SMOOTH = 8

Acceptance criteria:
- W/A/S/D still works.
- Space moves up.
- Left Ctrl moves down.
- Left Shift boosts.
- Camera FOV widens during boost and returns after.
- Boost VFX appears only while boosting.
- R teleports player near home and stops movement.
- Existing soaring pose and banking still work.
- No Output errors.
```

---

# 12. Pull Request Template

Use this PR format for both branches.

```markdown
## Ticket

0D-__

## Owner

Tien / Nova

## What Changed

-

## Files Changed

-

## How I Tested

-

## Screenshots / Video

Optional.

## Known Issues

-

## Checklist

- [ ] I only changed files allowed by the ticket
- [ ] I tested in Roblox Studio
- [ ] There are no Output errors
- [ ] I did not add out-of-scope systems
- [ ] I did not touch the other person's owned files
- [ ] Existing movement still works
- [ ] Existing Influence UI still works
```

---

# 13. Definition of Done

Sprint 0D is complete when:

- Home planet appears from `WorldBuilder.luau`.
- Home planet has a simple atmosphere shell.
- Player can boost with Left Shift.
- Left Shift no longer descends.
- Left Ctrl descends.
- Space moves up.
- WASD movement still works.
- Camera FOV changes smoothly during boost.
- Boost has a subtle VFX.
- Pressing R returns player near the home planet.
- Existing soaring pose works.
- Existing banking works.
- Existing starfield works.
- Existing centerpiece star works.
- Existing Influence UI still works.
- No Output errors.
- Both PRs are merged into `main`.

---

# 14. What Comes Next

Recommended next sprint:

## Sprint 0E — Planet Approach + Inspect Prompt

Goal:

```text
When the player approaches the home planet, show a simple interaction prompt.
Press E to enter a basic planet focus/inspect mode.
```

Possible scope:

- Detect distance to `HomePlanet`.
- Show `Press E to Inspect` near the planet.
- Press E to slow/stop the player.
- Camera frames the planet.
- Press E or Backspace to exit focus mode.
- No planet stats yet unless needed by Epic 1.

Do not start Sprint 0E until Sprint 0D movement feels good.
