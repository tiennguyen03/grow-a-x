# Epic 0: World Traversal

Establishes the core feel of being a Universe Architect floating through space. This runs in parallel with Epic 1 — it is about environment and player movement, not game systems.

---

## Sprint 0A: Void Environment + Space Movement ✅ COMPLETE

**Goal:** Player spawns in a dark void and floats freely through space.

### Environment Changes (applied directly in Studio via MCP)
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

**Known cosmetic issue:** Humanoid still occasionally plays footstep sounds on spawn. Harmless; will be silenced when/if we move to a fully custom rig.

---

## Sprint 0C: Motion Feel Polish (NOT STARTED)

Planned scope:
- Tilt/bank the character in the direction of travel so they look like they're soaring
- Optional subtle camera FOV kick when accelerating
- Silence footstep sounds
