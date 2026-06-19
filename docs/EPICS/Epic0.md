# Epic 0: World Traversal

Establishes the core feel of being a Universe Architect floating through space. This runs in parallel with Epic 1 — it is about environment and player movement, not game systems.

---

## Sprint 0A: Void Environment + Space Movement ✅ COMPLETE

**Goal:** Player spawns in a dark void and floats freely through space.

### Environment Changes (now built from source by `WorldBuilder.luau`)
> Originally applied directly in Studio via MCP; migrated into `src/server/WorldBuilder.luau` so the world rebuilds from source on every Play.
- [x] Baseplate deleted
- [x] SpawnLocation deleted (player spawns at origin)
- [x] `Workspace.Gravity = 0`
- [x] `Lighting.ClockTime = 0` (midnight star sky)
- [x] `Lighting.Brightness = 1`
- [x] `Lighting.Ambient / OutdoorAmbient` = deep space blue `(5, 5, 15)`
- [x] `Atmosphere.Density = 0` (no haze)
- [x] `SunRays` deleted (no sun)
- [x] `Bloom` tuned: Intensity 0.4, Threshold 0.95
- [x] `DepthOfField` disabled

### Movement Script
**File:** `src/client/SpaceMovement.client.luau`

Self-contained LocalScript. No module pattern needed.

**Controls:**
| Key | Action |
|---|---|
| W / A / S / D | Move horizontally, camera-relative |
| Space | Move up |
| Left Ctrl / Left Shift | Move down |
| Mouse | Camera (default Roblox camera) |

**Tuning constants:**
```lua
MOVE_SPEED     = 40
VERTICAL_SPEED = 35
ACCELERATION   = 8
DECELERATION   = 10
```

**How it works:**
- On `CharacterAdded`: sets `WalkSpeed = 0`, `JumpPower = 0`, `AutoRotate = false`
- On `RenderStepped`: reads input, projects W/S/A/D onto camera's XZ plane, lerps `currentVelocity` toward desired velocity, applies via `AssemblyLinearVelocity`
- Gravity = 0 globally so no anti-gravity counterforce needed

**Out of scope (not built yet):**
- Server-authoritative movement
- Character rotation to face camera
- Dash/boost ability
- Planet proximity effects

---

## Sprint 0B: Centerpiece + Star Field ✅ COMPLETE

**Goal:** Give the player visual reference points so motion through the void is perceptible (empty void = can't tell you're moving).

**File:** `src/server/WorldBuilder.luau` (built from script, called by `Main.server.luau`)

- [x] Centerpiece "star": neon ball at `(0, -20, -350)`, radius 60, with a ForceField halo shell and a `PointLight` (range 600) so it lights the player
- [x] Star field: 200 anchored neon balls scattered in a spherical shell (150–900 studs from origin)
- [x] Star colors: ~75% white, 15% blue, 10% warm
- [x] Fixed RNG seed `20260618` so both devs see the same layout
- [x] `WorldBuilder.build()` clears any prior `SpaceEnvironment` folder first (no duplicates on re-run)

**Tuning constants** (top of `WorldBuilder.luau`):
```lua
STAR_SEED         = 20260618
STAR_COUNT        = 200
STAR_FIELD_RADIUS = 900
STAR_MIN_DIST     = 150
CENTERPIECE_POS    = Vector3.new(0, -20, -350)
CENTERPIECE_RADIUS = 60
```

> **Update (Epic 7 Sprint 7H):** the centerpiece position/radius are no longer hardcoded in `WorldBuilder` — they now come from `WorldConfig.CENTERPIECE_STAR_POS` `(0,0,-900)` / `CENTERPIECE_STAR_RADIUS` `200`, the single source of truth shared with the orbiting planets and the dust field. Tune the star there. Return-home (R) also moved into `SpaceMovement` proper: it now teleports just outside the local player's **orbiting** planet (far side from the star), falling back to `WorldConfig.RETURN_HOME_FALLBACK` if the planet hasn't spawned. A new `PlanetMarker.client.luau` shows a screen-edge marker pointing back to your planet when you're far from it.

**Footstep sound:** Muted in `SpaceMovement.client.luau` setup by setting the default `Running` Sound's `Volume = 0` (we're floating, not walking).

---

## Sprint 0C: Soaring Pose + Banking ✅ COMPLETE

**Goal:** Make the character look like it's flying (Superman-style) instead of sliding around upright.

**File:** `src/client/SpaceMovement.client.luau` (orientation block added to the `RenderStepped` loop)

- [x] While moving, pitch the body 90° into a horizontal head-first flight pose facing the travel direction
- [x] Bank (roll) into turns, proportional to how fast the heading is changing
- [x] Smoothly ease the bank in/out so it doesn't snap
- [x] Return to an upright hover (facing camera) when nearly stopped
- [x] Handle near-vertical flight without `lookAt` gimbal flipping (camera-forward up hint)

**How it works:**
- `CFrame.lookAt(pos, pos + moveDir) * CFrame.Angles(-pi/2, 0, 0)` → upright-facing-travel, then pitched forward into the dive pose. After the pitch, the body's local Y axis points along travel, so `CFrame.Angles(0, bank, 0)` rolls it into the turn.
- Turn rate is measured frame-to-frame via the signed angle between the previous and current horizontal heading (`atan2` of cross/dot).
- Orientation is applied by lerping `rootPart.CFrame` toward the target pose each frame (position preserved — physics still drives translation via `AssemblyLinearVelocity`).

**Tuning constants** (top of `SpaceMovement.client.luau`):
```lua
ORIENT_SMOOTH    = 9
POSE_MIN_SPEED   = 3
BANK_SENSITIVITY = 0.18
BANK_SMOOTH      = 6
MAX_BANK         = math.rad(55)
```
> If banking rolls the *wrong* way, flip the sign on `BANK_SENSITIVITY`.

**Still out of scope:** an actual flying *animation* (limbs are held in the default pose). That needs an uploaded animation asset — defer until we have a rig/anim pipeline.

---

## Sprint 0D: Boost + Speed Feel + Home Anchor 🔶 IN PROGRESS

**Goal:** Make floating feel faster, clearer, and harder to get lost in.

Split across two owners / branches:

### Tien — movement (`feature/0d-boost-movement`, `src/client/SpaceMovement.client.luau`) ✅ DONE
- [x] **0D-02 Boost:** Left Shift is now boost (no longer descend); Left Ctrl is the only descend key. Boost raises horizontal speed and only applies while moving horizontally.
- [x] **0D-03 FOV:** camera FOV eases from 70 → 84 while boosting and back; reset to 70 on respawn so it can't stick.
- [x] **0D-04 Boost VFX:** a blue `ParticleEmitter` on a rootPart `Attachment`, enabled only while boosting; recreated per spawn (no duplicates).
- [x] **0D-05 Return home (R):** teleports to `(0, 20, -90)` (in front of/above the home planet), zeroes velocity. Edge-triggered via `InputBegan` so it fires once per press.
- [x] **0D-06 Tuning:** adopted the spec's final constants.

### Nova — environment (`feature/0d-home-planet`, `src/server/WorldBuilder.luau`) ⬜ PENDING
- [ ] **0D-01 Home planet:** `HomePlanet` sphere + `HomePlanetAtmosphere` shell inside `SpaceEnvironment` at `(0, 0, -180)`, radius 35.

**Movement tuning constants** (top of `SpaceMovement.client.luau`):
```lua
MOVE_SPEED         = 40
BOOST_SPEED        = 95
VERTICAL_SPEED     = 35
ACCELERATION       = 8
BOOST_ACCELERATION = 6
DECELERATION       = 10
NORMAL_FOV = 70 ; BOOST_FOV = 84 ; FOV_SMOOTH = 8
RETURN_HOME_POS = Vector3.new(0, 20, -90)
```

> **Coordination note:** `RETURN_HOME_POS (0,20,-90)` is positioned relative to Nova's `HOME_PLANET_POS (0,0,-180)`. If Nova moves the planet, update the return point to match.

### Controls after 0D
| Input | Action |
|---|---|
| W/S | Fly toward / away from where the camera looks (full 3D — look down to descend, up to climb) |
| A/D | Strafe horizontally |
| Space | World-up (fine altitude control) |
| Left Ctrl | World-down (fine altitude control) |
| Left Shift | Boost |
| R | Return near home planet |

> **Flight model (added after first 0D playtest):** W/S use the camera's **full** look vector, not a flattened one. Pointing the camera down and holding W now descends (previously movement was locked to the horizontal plane and the only way down was Left Ctrl). Space/Ctrl remain as world-vertical strafing on top. Zero gravity means releasing input hovers — there is intentionally no auto-fall.

### Definition of Done (Sprint 0D)
- [x] Boost on Left Shift; Left Ctrl is the only descend key
- [x] Look-based 3D flight (down/up by aiming)
- [x] Smooth FOV change while boosting
- [x] Subtle boost VFX
- [x] R returns near home and stops the player
- [x] Soaring pose + banking still work
- [ ] Home planet appears from `WorldBuilder.luau` (Nova)
- [ ] Both PRs merged into `main`

---

## Sprint 0E: Planet Approach + Inspect Prompt ⬜ NOT STARTED

**Goal:** When the player approaches the home planet, show a simple interaction prompt and a basic focus/inspect mode.

Possible scope (do not start until 0D feels good):
- Detect distance to `HomePlanet`
- Show "Press E to Inspect" near the planet
- Press E to slow/stop the player and frame the planet with the camera
- Press E or Backspace to exit focus mode
- No planet stats yet unless Epic 1 needs them
