# Epic 7: Procedural Planet Generation & Planet Identity

> Slotted as Epic 7 to avoid renumbering the existing tracker (Epic 2 stays "Planet Upgrade System"). Conceptually this is the **planet foundation** — upgrades/interventions and era visuals will act on planets generated here.

**Status:** ✅ Sprints 7A–7F complete. **Refactor (per-player + noise continents):** planets are now built per player by `PlayerPlanetService` on join (seed = `UserId + WORLD_SEED_SALT`), under `workspace.SpaceEnvironment.PlayerPlanets`. Land is generated from coherent `math.noise` over the sphere (connected continents/islands) instead of clustered blobs; `WorldBuilder` no longer builds a planet (backdrop only); atmosphere is a thin shell (scale 1.04–1.08). See `PlayerPlanetService.luau` + `PlanetGenerator.generateSurface`.

---

## One-sentence goal

A seeded, deterministic procedural planet system: every world is generated from a seed, can be regenerated identically from that seed, and is built from constrained, scientifically-grounded traits (not random chaos).

## Why

Each player should feel "this is *my* world — nobody else has this exact one," instead of everyone sharing one hand-made blue sphere. This epic builds the deterministic identity + visual generator that powers the home planet now and future planets later. Keep v0 simple: a planet *identity + visual generator*, not a full simulator.

---

## Core design philosophy

1. **Procedural, not random chaos.** `seed → archetype → constrained traits → constrained palette → visual layers`. Unique but believable.
2. **Archetype first, traits second.** Pick a planet archetype, then roll traits *inside that archetype's valid ranges*. No impossible combos (no lava world with ice caps + neon purple sky).
3. **Scientific grounding, Roblox readability.** Rocky habitable starts, liquid water, thin atmosphere rim (not a fog bubble), clouds correlated with water, polar caps only when temperature supports them. But keep a strong silhouette, clear atmosphere shell, simple readable colors.
4. **Deterministic seeds.** Same seed → same planet, always. So both devs see the same world from source, bugs reproduce, and screenshots tie to a seed. `UserId + PlanetIndex + WORLD_SEED_SALT → seed → descriptor → visual model`.
5. **Home planet is constrained.** The starting "Origin World" only rolls habitable archetypes (Temperate / Ocean / Young Habitable). Desert/Ice/Volcanic/Barren/GasGiant/Exotic are saved for later — the first planet must read as a world that can develop life.

Player-facing name for the start planet: **Origin World**. Internal names: `HomePlanet`, `HomePlanetAtmosphere`, `HomePlanetClouds`, `HomePlanetSurfaceFeatures`.

---

## Planet descriptor fields

A descriptor is a plain Luau table produced by `PlanetGenerator`:

| Field | Type | Purpose |
|---|---|---|
| `planetId` | string | Stable internal ID |
| `displayName` | string | Player-facing name |
| `seed` | number | Deterministic seed |
| `archetype` | string | Planet category |
| `radius` | number | Visual size |
| `waterCoverage` | number | 0–1 |
| `cloudCoverage` | number | 0–1 (correlated with water) |
| `atmosphereThickness` | number | 0–1 visual strength |
| `iceCoverage` | number | 0–1 polar/ice |
| `oceanColor` / `landColor` / `atmosphereColor` / `cloudColor` | Color3 | Palette picks |
| `rotationSeconds` | number | Visual rotation speed |
| `hasRings` / `moonCount` / `tags` | bool / number / table | Future hooks |

## Starting archetypes (home pool)

| Archetype | Vibe | Notes |
|---|---|---|
| Temperate | Earth-like but not Earth | Balanced ocean/land, moderate clouds, thin blue atmosphere — best default home |
| Ocean | Calm, deep, early-life friendly | High water coverage, more cloud, blue/teal palette |
| Young Habitable | Life possible, no civilization yet | Volcanic/rocky land variation, oceans + atmosphere present, slightly unstable look |

Future (disabled for now): Desert, Ice, Volcanic, Barren, GasGiant, Exotic.

---

## Epic scope

**In scope:** seeded descriptor generation; archetype definitions + constrained ranges; procedural HomePlanet v0 (sphere + atmosphere shell, optional cloud shell + simple surface patches); deterministic from seed; model attributes; docs for expansion.

**Out of scope:** DataStore, planet stats gameplay, Matter/Influence spending, civilization sim, events, multiplayer visiting, terraforming, moons, rings, satellites, city lights, Dyson structures, complex terrain, external-asset textures, runtime-heavy mesh generation.

---

## File plan

**New:** `src/shared/WorldConfig.luau`, `src/shared/PlanetArchetypes.luau`, `src/shared/PlanetGenerator.luau`
**Touch later:** `src/server/WorldBuilder.luau`, `docs/EPICS/Epic7.md`, `CLAUDE.md`, `HANDOFF.md`
**Avoid (likely Nova's Matter/economy lane):** `PlayerManager.luau`, `GameConfig.luau`, `Remotes.luau`, `InfluenceUI.luau`, both `Main` files, `SpaceMovement.client.luau`

---

## Sprints

### Sprint 7A: Planet Generation Foundation ✅ COMPLETE
**Goal:** the data-only foundation — deterministic descriptors, no Roblox objects.

**Files:** `src/shared/WorldConfig.luau`, `src/shared/PlanetArchetypes.luau`, `src/shared/PlanetGenerator.luau`

- [x] **7A-01 `WorldConfig.luau`** — home planet constants (`WORLD_SEED_SALT`, `HOME_PLANET_ID/NAME/DISPLAY_NAME`, `HOME_PLANET_POS`, `RETURN_HOME_POS`, `INSPECT_DISTANCE`, `HOME_PLANET_SEED_MODE`, `FALLBACK_HOME_PLANET_SEED`, `HOME_ARCHETYPE_POOL`). Pure table, no services.
- [x] **7A-02 `PlanetArchetypes.luau`** — Temperate / Ocean / YoungHabitable, each with `allowedForHome`, `enabled`, trait ranges, color palettes, tags.
- [x] **7A-03 `PlanetGenerator.luau`** — `generatePlanetDescriptor(seed, options?)`: deterministic via `Random.new(seed)`, archetype-first, fixed rng-call order, explicit ordered candidate list (never `pairs`), returns a plain table, creates no Instances.
- [x] **7A-04** — `debugDescriptor(descriptor)` one-line summary helper.

**Validated:** same seed → identical descriptor; 6 different seeds → 6 distinct believable planets; clouds correlate with water; colors stay within palettes. `rojo build` clean.

**Determinism note:** descriptor reproducibility depends on the FIXED order of `rng` calls in `generatePlanetDescriptor` and the explicit ordered candidate pool. Don't reorder those rng calls or switch to `pairs` for archetype selection.

---

### Sprint 7B: HomePlanet Visual v0 From Seed ✅ COMPLETE
**Goal:** `WorldBuilder` builds the first visible HomePlanet from a descriptor.
**Files:** `WorldBuilder.luau`

- [x] 7B-01 Require `WorldConfig` + `PlanetGenerator` in `WorldBuilder`; generate descriptor from `FALLBACK_HOME_PLANET_SEED` (restricted to `HOME_ARCHETYPE_POOL`).
- [x] 7B-02 Build `HomePlanet` model (`PlanetBody` + `AtmosphereShell`) at `HOME_PLANET_POS`. Body is `SmoothPlastic`, colored by `landColor:Lerp(oceanColor, waterCoverage)`; atmosphere is a subtle `ForceField` shell scaled by `atmosphereThickness`. Body `CanCollide = false` so it never blocks flight; `CanQuery = true` for future inspect raycasts.
- [x] 7B-03 Set model attributes (PlanetId, DisplayName, Seed, Archetype, Radius, WaterCoverage, CloudCoverage, AtmosphereThickness).
- [x] 7B-04 `WorldBuilder.build()` clears `SpaceEnvironment` first, so no duplicate planets on Play/Stop/Play.

**Validated:** `rojo build` clean; live Studio run builds the model with correct blended color, subtle atmosphere, and all attributes. The seed-`20260618` Origin World is an Ocean world (radius 36).

> ⚠️ This rewrote the planet section of `WorldBuilder.luau`. If Nova still has an unmerged Epic 0 home-planet (0D-01), this supersedes it — coordinate so the procedural version wins and the simple one is dropped.

### Sprint 7C: Visual Variation v0 ✅ COMPLETE
Different seeds already produce visibly different planets — the body color (`landColor:Lerp(oceanColor, waterCoverage)`), radius, atmosphere, and rotation value all come from the descriptor's archetype-constrained rolls. `RotationSeconds` and `IceCoverage` are now also exposed as model attributes. Validated: 6 seeds → 6 distinct believable planets.

### Sprint 7D: Simple Surface Features v1 ✅ COMPLETE
`PlanetGenerator.generateSurfaceFeatures(descriptor)` returns deterministic patch data (a separate rng stream from the seed, so it never disturbs the main rolls); `WorldBuilder` builds each as a small anchored `Part`.
- [x] Land patches (8–20, more when drier), shaded from `landColor`, on the body surface → `HomePlanet/SurfaceFeatures`
- [x] Ice caps (0–4, only if `iceCoverage > 0.05`), near the poles, pale → `SurfaceFeatures`
- [x] Cloud patches (6–18, scaled by `cloudCoverage`), white-ish, floating just above the surface, semi-transparent → `HomePlanet/Clouds`
- All patches `CanCollide=false`, `CanQuery=false`, `CastShadow=false`. No external assets, no mesh generation. Validated: seed `20260618` → 25 patches (10 land / 2 ice / 13 cloud), deterministic, varies by seed.

### Sprint 7E: Planet Motion & Presentation ✅ COMPLETE
- [x] `RotationSeconds` exposed as a model attribute (7E-01).
- [x] **`src/client/PlanetVisuals.client.luau`** — self-contained LocalScript that slowly spins the HomePlanet model about its center (visual only, client-side; re-acquires the planet if it rebuilds). Speed = `2π / RotationSeconds` (7E-02).
- [x] Spawn composition already matches the spec — spawn `(0,0,0)`, planet `(0,0,-180)`, star `(0,-20,-350)`, return `(0,20,-90)`. Confirmed in-playtest: planet is clearly visible from spawn with the star anchoring the background (7E-03).

### Sprint 7F: Multi-Planet Generator Prep ✅ COMPLETE
- [x] `generatePlanetDescriptor(seed, options)` already accepts `planetId` / `displayName` / `allowedArchetypes` (7F-01).
- [x] Future archetypes `Desert`, `Ice`, `Volcanic`, `Barren` added to `PlanetArchetypes` with `enabled = false`, `allowedForHome = false` — the generator's candidate filter requires `enabled`, so they're never rolled until turned on (7F-02).
- [x] Future gameplay hooks documented as comments in `PlanetArchetypes.luau` (ocean = faster early life, desert = stronger solar, etc.) — docs only, no modifiers implemented (7F-03).

---

**Epic 7 status: all sprints 7A–7F complete.** Next recommended work is **Epic 0 Sprint 0E** (planet approach + inspect prompt), which targets this generated `HomePlanet`.

---

## Determinism test plan
1. Seed `20260618` → Play → observe planet → Stop → Play again → identical.
2. Change seed → planet changes but still looks believable.
3. Visual: visible from spawn, atmosphere not too thick, reads as a world not a toy ball, colors believable, boost/return-home still work.
4. Performance: no Output errors, no thousands of parts, no duplicates after rebuild.

## Branch naming
`feature/7a-planet-generator-foundation`, `feature/7b-home-planet-from-seed`, `feature/7c-…`, etc.

## Definition of done (Epic 7)
Planets generate from seeds; same seed → same descriptor; HomePlanet built from procedural data with believable controlled variation and useful attributes; future planet scripts can read it; no Matter/Influence coupling; no DataStore; docs updated; both devs can add future planet types without guessing.

## What comes after
- **Epic 0 Sprint 0E:** Planet Approach + Inspect Prompt — fly near Origin World → "Press E to Inspect" → camera frames planet.
- **Epic 1 next:** First Intervention — spend Influence to "Guide Evolution," planet changes slightly.
- **Epic 3 (Planet Era Visuals):** stage-based overlays on the same generated foundation (microbial tint → vegetation → city lights → industrial haze → satellites → orbital structures).
