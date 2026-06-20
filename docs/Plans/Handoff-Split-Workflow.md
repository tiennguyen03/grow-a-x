# Handoff Split Workflow Plan

## Purpose

The current project uses one shared `HANDOFF.md` file. That is becoming confusing during merges because both Tien and Nova update the same file with active branch notes, recent changes, file ownership, blockers, and next tasks.

This plan refactors the handoff workflow into one global handoff file plus one active-lane handoff file per developer.

## Recommended Structure

Use three handoff files:

```text
HANDOFF.md
HANDOFF-TIEN.md
HANDOFF-NOVA.md
```

The goal is not to replace the global handoff. The goal is to make `HANDOFF.md` stable and project-wide while giving each developer their own fast-changing active-work file.

## File Responsibilities

### `HANDOFF.md`

`HANDOFF.md` should be the global project/integration snapshot.

It should contain:

- current project status
- current integration branch / main branch status
- active lanes table
- global blockers
- shared coordination files
- stable file map / ownership map
- merge / PR notes
- links/instructions to read `HANDOFF-TIEN.md` and `HANDOFF-NOVA.md`
- what has been integrated into main or the integration branch

It should not be used as either developer's daily scratchpad.

Update `HANDOFF.md` only when:

- work is merged into main or an integration branch
- a sprint is completed
- a major file/system is added
- the global file map changes
- project-wide current state changes
- a global blocker appears
- integration state changes

### `HANDOFF-TIEN.md`

`HANDOFF-TIEN.md` should be Tien's active lane handoff.

Tien/Claude can update this freely while Tien works.

Nova should not edit this unless explicitly asked or unless the task is a coordination/merge task.

### `HANDOFF-NOVA.md`

`HANDOFF-NOVA.md` should be Nova's active lane handoff.

Nova/Claude can update this freely while Nova works.

Tien should not edit this unless explicitly asked or unless the task is a coordination/merge task.

## Claude Read Order

When Claude starts a session, it should read:

```text
1. CLAUDE.md
2. HANDOFF.md
3. The active developer handoff file
4. The other developer handoff file only if the task overlaps shared files or the other developer's lane
5. Relevant docs/EPICS/Epic<N>.md
```

### If working with Tien

Read:

```text
CLAUDE.md
HANDOFF.md
HANDOFF-TIEN.md
```

Also read `HANDOFF-NOVA.md` if the task touches Nova's lane or shared files.

After implementation:

- update `HANDOFF-TIEN.md`
- update `HANDOFF.md` only if the global/integration state changed

### If working with Nova

Read:

```text
CLAUDE.md
HANDOFF.md
HANDOFF-NOVA.md
```

Also read `HANDOFF-TIEN.md` if the task touches Tien's lane or shared files.

After implementation:

- update `HANDOFF-NOVA.md`
- update `HANDOFF.md` only if the global/integration state changed

## Merge Policy

The merge policy should be:

```text
Global truth goes in HANDOFF.md.
Daily active-lane notes go in the developer-specific file.
```

This reduces merge conflicts because Tien and Nova are no longer constantly editing the same `HANDOFF.md` for day-to-day updates.

## Claude Task: Create Split Handoff Workflow

### Goal

Create and document the new handoff workflow.

### Files to create

```text
HANDOFF-TIEN.md
HANDOFF-NOVA.md
```

### Files to update

```text
HANDOFF.md
CLAUDE.md
```

Do not delete useful context from the current `HANDOFF.md`. Preserve it by moving active developer-specific notes into the relevant per-developer file and keeping global information in `HANDOFF.md`.

## Suggested `HANDOFF.md` Structure

```markdown
# HANDOFF — Global Project State

## Read Order
1. Read this file first.
2. Read `HANDOFF-TIEN.md` for Tien's active lane.
3. Read `HANDOFF-NOVA.md` for Nova's active lane.
4. Read relevant `docs/EPICS/Epic<N>.md`.

## Current Integration State
-

## Active Lanes
| Developer | Current Lane | Branch | Handoff |
|---|---|---|---|
| Tien |  |  | `HANDOFF-TIEN.md` |
| Nova |  |  | `HANDOFF-NOVA.md` |

## What Is Done
-

## Current Global Blockers
-

## Shared Coordination Files
-

## File Map / Ownership Summary
-

## Merge / PR Notes
-

## Maintenance Rules
- Update this file only when global/integration state changes.
- Use `HANDOFF-TIEN.md` and `HANDOFF-NOVA.md` for active day-to-day lane updates.
```

## Suggested `HANDOFF-TIEN.md` Structure

```markdown
# HANDOFF — Tien

## Current Branch
-

## Current Focus
-

## Active Sprint / Ticket
-

## Files I Am Touching
-

## Files I Should Avoid
-

## Recent Changes
-

## How To Test My Work
-

## Open Questions / Blockers
-

## Next Safe Tasks
-

## Notes For Nova
-
```

## Suggested `HANDOFF-NOVA.md` Structure

```markdown
# HANDOFF — Nova

## Current Branch
-

## Current Focus
-

## Active Sprint / Ticket
-

## Files I Am Touching
-

## Files I Should Avoid
-

## Recent Changes
-

## How To Test My Work
-

## Open Questions / Blockers
-

## Next Safe Tasks
-

## Notes For Tien
-
```

## `CLAUDE.md` Updates

### Update the starting-session instruction

Replace the current startup language with:

```markdown
> 📋 **Starting a session?** Read `HANDOFF.md` first, then read the active developer handoff:
> - Tien work → `HANDOFF-TIEN.md`
> - Nova work → `HANDOFF-NOVA.md`
>
> If the task touches shared files or another developer's lane, also read the other developer's handoff before editing.
```

### Add a new section to `CLAUDE.md`

Add this section near the existing Claude Operating Rules:

```markdown
## Handoff File Workflow

The project uses one global handoff file and one per-developer handoff file.

- `HANDOFF.md` is the global integration snapshot.
- `HANDOFF-TIEN.md` is Tien's active work handoff.
- `HANDOFF-NOVA.md` is Nova's active work handoff.

Claude must always read `HANDOFF.md` first, then read the relevant developer handoff file.

Do not use `HANDOFF.md` as a daily scratchpad. Use the per-developer handoff file for active branch notes, files being touched, blockers, and next steps.

Only update `HANDOFF.md` when shared project state changes:

- sprint completed
- branch merged
- new system added
- file ownership changed
- global blocker discovered
- integration state changed

During normal implementation, update the active developer's file:

- Tien work → update `HANDOFF-TIEN.md`
- Nova work → update `HANDOFF-NOVA.md`

Do not edit the other developer's handoff file unless explicitly asked or unless the task is a coordination/merge task.
```

### Update Claude Operating Rules

Add these items to the "Before starting any task" checklist:

```markdown
- Identify which developer is active: Tien or Nova.
- Identify which handoff file should be updated after the task.
- Decide whether `HANDOFF.md` needs a global update or only the per-developer file needs updating.
```

### Update Required Handoff Summary Format

Add this section to the end of the handoff summary format:

```markdown
### Handoff File Updated
- HANDOFF-TIEN.md / HANDOFF-NOVA.md / HANDOFF.md / None
```

## Initial Migration Plan

1. Keep the existing `HANDOFF.md`.
2. Create `HANDOFF-TIEN.md`.
3. Create `HANDOFF-NOVA.md`.
4. Refactor `HANDOFF.md` to be shorter and more global.
5. Move Tien-specific active branch/work notes into `HANDOFF-TIEN.md`.
6. Move Nova-specific active branch/work notes into `HANDOFF-NOVA.md`.
7. Keep stable shared file map information in `HANDOFF.md`.
8. If the file map contains per-lane notes, summarize them globally in `HANDOFF.md` and put day-to-day notes in the per-dev files.
9. Update `CLAUDE.md` with the new read/update workflow.
10. Do not delete useful context. If unsure, preserve it.

## Acceptance Criteria

This task is complete when:

- `HANDOFF.md` exists and functions as the global integration snapshot.
- `HANDOFF-TIEN.md` exists and contains Tien's active lane template/current state.
- `HANDOFF-NOVA.md` exists and contains Nova's active lane template/current state.
- `CLAUDE.md` tells Claude to read global handoff first, then the relevant per-dev handoff.
- `CLAUDE.md` explains when to update `HANDOFF.md` versus per-dev files.
- `CLAUDE.md` handoff summary format includes which handoff file was updated.
- Existing useful context is preserved, not deleted.
- The new workflow reduces merge conflicts by avoiding constant edits to the same `HANDOFF.md`.

## Final Recommendation

Use this structure:

```text
HANDOFF.md       = shared global truth
HANDOFF-TIEN.md  = Tien's active work notes
HANDOFF-NOVA.md  = Nova's active work notes
```

Do not split everything into only developer-specific files. Keep one global truth, but move fast-changing daily work into per-dev handoffs.
