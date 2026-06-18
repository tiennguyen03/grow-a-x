# Epic 7: Procedural Planet Generation & Planet Identity

> Slotted as Epic 7 to avoid renumbering the existing tracker (Epic 2 stays "Planet Upgrade System"). Conceptually this is the **planet foundation** — upgrades/interventions and era visuals will act on planets generated here.

**Status:** In Progress (Sprint 7A complete)

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

### Sprint 7B: HomePlanet Visual v0 From Seed ⬜ NOT STARTED
**Goal:** `WorldBuilder` builds the first visible HomePlanet from a descriptor.
**Files:** `WorldBuilder.luau`, `WorldConfig.luau`, `PlanetGenerator.luau`, `docs/EPICS/Epic7.md`, `docs/EPICS/Epic0.md`

- 7B-01 Require `WorldConfig` + `PlanetGenerator` in `WorldBuilder`; generate descriptor from `FALLBACK_HOME_PLANET_SEED`.
- 7B-02 Build `HomePlanet` model (`PlanetBody` + `AtmosphereShell`) at `HOME_PLANET_POS`, using descriptor radius/colors/atmosphere thickness.
- 7B-03 Set model attributes (PlanetId, DisplayName, Seed, Archetype, Radius, WaterCoverage, CloudCoverage, AtmosphereThickness).
- 7B-04 Keep `WorldBuilder.build()` idempotent — no duplicate planets on Play/Stop/Play.

> ⚠️ 7B touches `WorldBuilder.luau`, which Nova also owns for the Epic 0 home-planet ticket. Coordinate before starting 7B so we don't both rewrite the planet.

### Sprint 7C: Visual Variation v0 ⬜
Different seeds visibly produce different planets (colors, radius, rotation value, water/cloud/atmo/ice traits) while staying believable.

### Sprint 7D: Simple Surface Features v1 ⬜
Lightweight deterministic surface variation — small land/ice patch parts + a simple cloud shell. No external assets, no heavy mesh generation. Suggested counts: land 8–20, ice 0–4, cloud 6–18.

### Sprint 7E: Planet Motion & Presentation ⬜
Slow client-side visual rotation (`src/client/PlanetVisuals.client.luau`), spawn composition tuning (spawn `(0,0,0)`, planet `(0,0,-180)`, star `(0,-20,-350)`, return `(0,20,-90)`).

### Sprint 7F: Multi-Planet Generator Prep ⬜
Generator accepts explicit `planetId` / `displayName` / `allowedArchetypes`; add future archetypes as `enabled = false`; document future gameplay hooks (ocean = faster early life, desert = stronger solar, etc.) — docs only, no modifiers implemented.

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
