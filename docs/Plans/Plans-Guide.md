# Plans — cross-cutting implementation plans

This folder holds **implementation/coordination plans that span more than one epic**
(or that aren't a single sprint/epic at all) — design docs, integration plans, and
"how two systems should fit together" write-ups. Anything that doesn't belong under
a single `docs/EPICS/Epic<N>.md` lives here so it's easy to find later without
cluttering the epic docs.

**When to put a doc here vs. in `docs/EPICS/`:**
- One epic / one feature's sprints → `docs/EPICS/Epic<N>.md`.
- Reconciling or unifying *multiple* epics/systems, or a one-off plan/proposal that
  isn't itself a sprint → here.

**Naming:** descriptive kebab-case, e.g. `MatterCore-Inspect-Integration.md`.

**Status convention:** each plan keeps its own `**Status:**` line at the top
(Proposed / In Progress / Done / Superseded). When a plan is fully implemented,
either mark it **Done** with a one-line pointer to where the work landed, or — if it
stops being useful — leave it as a historical record (don't delete; this folder is a
keep-for-reference archive, same spirit as `PastEpics/`).

---

## Index

| Plan | What it covers | Status |
|---|---|---|
| [`MatterCore-Inspect-Integration.md`](MatterCore-Inspect-Integration.md) | Unify the Planet Inspect UI (Epic 4) with Nova's Matter Converter / Create Life (Epic 3 / Sprint 8B) into one planet-contextual flow — fold "Create Life" into the inspect panel as a planet intervention, wire the `PlanetInspectContext` seam, and have the server set `EvolutionTier=1` / `EvolutionStage="Archaea"` after first creation so the existing glow + panel update fire. | ✅ v0 implemented 2026-06-19 (pending playtest) |
| [`Handoff-Split-Workflow.md`](Handoff-Split-Workflow.md) | Split the single `HANDOFF.md` into a global file + per-dev lane files (`HANDOFF-TIEN.md` / `HANDOFF-NOVA.md`) to cut merge conflicts; defines read/update order and `CLAUDE.md` workflow. | ✅ Implemented 2026-06-19 |
| [`Ecosystem-Interventions-UI-Clarity.md`](Ecosystem-Interventions-UI-Clarity.md) | UI/copy pass framing Nova's Cell Cultures + Tien's preview as one early-life pipeline: rename `Future Interventions` → `Ecosystem Interventions` + bridge copy; no live logic (Epic 5 → 6 bridge). | ✅ Implemented 2026-06-20 |
