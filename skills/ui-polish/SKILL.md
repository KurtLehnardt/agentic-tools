---
name: ui-polish
description: "Audit and apply frontend micro-interaction and visual polish principles to make interfaces feel better. Covers text rendering, animations, shadows, spacing, and typography. Trigger: ui polish, make it feel better, polish the UI, interface details, micro-interactions."
user-invocable: true
---

# /ui-polish — Frontend Interface Polish Pipeline

You are an **orchestrator** dispatching agents to audit existing frontend code against 11 proven UI/UX polish principles and apply fixes. You do not write code. You dispatch subagents to find violations, plan fixes, and apply them.

## What This Skill Does

1. Audits frontend code against 11 interface polish principles
2. Identifies violations ranked by visual impact
3. Applies fixes via targeted subagents
4. Validates changes render correctly

## The 11 Principles

1. **Balanced Text Wrapping** — `text-wrap: balance` on headings
2. **Concentric Border Radius** — outer radius = inner radius + padding
3. **Contextual Icon Animations** — opacity + scale + blur transitions on conditional icons
4. **Crispy Text Rendering** — `-webkit-font-smoothing: antialiased` on layout root
5. **Tabular Numbers** — `font-variant-numeric: tabular-nums` on dynamic numbers
6. **Interruptible Animations** — CSS transitions for user interactions, keyframes only for staged sequences
7. **Staggered Enter Animations** — split entering elements with staggered delays
8. **Subtle Exit Animations** — reduced movement on exit (fixed offset, not full travel)
9. **Optical Alignment** — adjust padding/margin for visual centering over geometric centering
10. **Shadows Over Borders** — layered box-shadows instead of flat borders for depth
11. **Image Outlines** — subtle 1px outline on images for depth

Full reference: `references/ui-principles.md`

## Phase 1: AUDIT

Dispatch an **Explore** subagent to scan the frontend codebase for violations.

```
Subagent: Task tool, subagent_type="Explore"
Prompt: Audit this frontend codebase against UI polish principles.
        Reference: [contents of references/ui-principles.md]

        For each principle, scan for violations:

        1. TEXT WRAPPING: Find headings/titles without text-wrap: balance
        2. CONCENTRIC RADIUS: Find nested elements where outer border-radius != inner + padding
        3. ICON ANIMATIONS: Find conditionally rendered icons without enter/exit transitions
        4. TEXT RENDERING: Check if -webkit-font-smoothing: antialiased is set on layout root
        5. TABULAR NUMBERS: Find dynamic numeric displays without tabular-nums
        6. INTERRUPTIBLE ANIMATIONS: Find keyframe animations used for user interactions (should be transitions)
        7. STAGGERED ENTERS: Find groups of elements that enter together without stagger
        8. SUBTLE EXITS: Find exit animations with full travel distance (should be subtle)
        9. OPTICAL ALIGNMENT: Find buttons with icons where padding is equal on both sides
        10. SHADOWS VS BORDERS: Find cards/containers using solid borders instead of layered shadows
        11. IMAGE OUTLINES: Find <img> elements without subtle outlines

        For each violation found, return:
        - File path and line number
        - Which principle is violated
        - Current code snippet
        - Impact: HIGH (visible on primary surfaces), MEDIUM (secondary surfaces), LOW (rare screens)

        Return a structured audit report sorted by impact.
```

## Phase 2: FIX PLAN

Based on the audit, create a fix plan grouped by file. For each fix:
- The principle being applied
- Exact code change needed
- Risk assessment (does this change layout? does it affect existing animations?)

### Prioritization:
1. **Global wins** — single changes that affect the whole app (crispy text, global shadows utility)
2. **HIGH impact violations** — visible on primary user-facing surfaces
3. **MEDIUM impact** — secondary surfaces
4. **LOW impact** — only if trivial to fix

### Scope discipline:
- Only modify styles, animations, and layout-related code
- Never change business logic, data flow, or component structure
- If a fix requires a component refactor, flag it and skip

## Phase 3: APPLY FIXES

Dispatch **workers** to apply fixes. Group by file to minimize conflicts.

```
Subagent: Task tool, subagent_type="general-purpose"
Prompt: You are a senior frontend engineer applying UI polish fixes.
        You are ONLY modifying styles, animations, and visual properties.
        Do NOT change component structure, props, or business logic.

        Reference principles: [contents of references/ui-principles.md]

        Fixes to apply:
        [FIX_PLAN_SUBSET]

        For each fix:
        1. Read the target file
        2. Apply the minimal change needed
        3. Verify the change doesn't break adjacent styles
        4. Commit: style(ui-polish): apply [principle-name] to [component]

        Key implementation details:
        - text-wrap: balance goes on headings and short text blocks only
        - Concentric radius: calculate outer = inner + padding, don't guess
        - Shadows: use the 3-layer shadow pattern from the reference
        - Tabular nums: test that the font supports it (Inter changes numeral style)
        - Stagger: use CSS custom property --stagger with calc() for delay
        - Exit animations: max 12px translateY, not full container height
        - Optical alignment: prefer fixing in SVG over adding CSS offsets
```

## Phase 4: VALIDATION

After all workers complete:

```
Subagent: Task tool, subagent_type="general-purpose"
Prompt: Validate the UI polish changes.

        1. Run the project's build command to check for compilation errors
        2. Run any existing visual/snapshot tests
        3. Check that no TypeScript/ESLint errors were introduced
        4. Verify no layout shifts by checking that only visual properties changed

        Report:
        - Build status: PASS/FAIL
        - Test status: PASS/FAIL
        - Files modified: [list]
        - Any regressions found
```

## Phase 5: REPORT

```
UI Polish Audit Complete:
  Principles checked: 11
  Violations found: N
  Fixes applied: M
  Skipped (needs refactor): K

  Applied:
    ✓ Crispy text rendering — added to layout root
    ✓ Balanced text wrapping — applied to N headings
    ✓ Layered shadows — replaced borders on M cards
    ✓ Tabular numbers — applied to K numeric displays
    ...

  Skipped:
    ✗ Icon animations on SearchBar — needs AnimatePresence refactor
    ...

  Ready for visual review.
```
