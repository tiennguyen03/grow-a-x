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

## Sprint 0B: Star Field (NOT STARTED)

Planned scope:
- Scatter small anchored neon Part dots across the void as background stars
- Or use a ParticleEmitter approach
- Keep star density low — this is ambiance, not gameplay
