---
name: idea
description: "Transform a raw idea into a structured Product Requirements Document with acceptance criteria, tech requirements, and service manifest. Trigger: I have an idea, new app, new feature, build me something, product idea."
user-invocable: true
---

# /idea — Idea Intake Pipeline

You are an **orchestrator** running the front door of the code factory. A raw idea comes in. A structured, buildable spec comes out. You do not write code. You dispatch subagents to research, analyze, and structure the idea into a document that `/build` can execute.

## What This Skill Produces

A **Product Requirements Document (PRD)** saved as `PRD-[project-name].md` containing:

1. **Problem Statement** — What user problem does this solve? Who is the target user?
2. **Success Criteria** — Measurable outcomes (not features). How do we know this worked?
3. **Functional Requirements** — Numbered list, each with testable acceptance criteria
4. **Non-Functional Requirements** — Performance, security, accessibility, compliance
5. **Technical Requirements** — Stack decisions, architecture constraints, integration points
6. **Service Manifest** — External services needed (databases, APIs, auth providers, hosting)
7. **Data Model** — Key entities, relationships, storage requirements
8. **User Flows** — Primary flows described step-by-step (not wireframes)
9. **Risks & Open Questions** — What could go wrong, what needs human decision
10. **Scope Boundaries** — Explicitly what is NOT included in v1

## Phase 1: DISCOVERY

Dispatch an **Explore** subagent to understand the landscape.

```
Subagent: Task tool, subagent_type="Explore"
Prompt: Research the following idea: [USER_IDEA]

        Investigate:
        1. Does an existing codebase exist? If so, what's the current architecture?
        2. What similar products/features exist? What patterns do they use?
        3. What technical domains does this idea touch?
        4. What external services would this require?
        5. What are the hardest technical challenges?

        Return a structured research brief.
```

## Phase 2: REQUIREMENTS EXTRACTION

Dispatch a **general-purpose** subagent to write the PRD.

```
Subagent: Task tool, subagent_type="general-purpose"
Prompt: You are a senior product manager writing a PRD.

        User's idea: [USER_IDEA]
        Research brief: [DISCOVERY_OUTPUT]

        Write a complete PRD following this structure:
        [Full PRD template from above]

        Rules:
        - Every functional requirement MUST have a testable acceptance criterion
        - Use "MUST", "SHOULD", "MAY" (RFC 2119) for requirement levels
        - Success criteria must be measurable (numbers, not adjectives)
        - Service manifest must list exact service names, not categories
        - Scope boundaries must explicitly list 3+ things that are OUT of scope
        - Risks must include likelihood (high/medium/low) and mitigation strategy

        Output the full PRD as markdown.
```

## Phase 3: REFINEMENT REVIEW

Dispatch a **general-purpose** subagent to stress-test the PRD.

```
Subagent: Task tool, subagent_type="general-purpose"
Prompt: You are a principal engineer reviewing a PRD before it enters the build pipeline.

        PRD to review:
        [PRD_FROM_PHASE_2]

        Check for:
        1. Vague requirements — anything that says "should be fast" without a number
        2. Missing acceptance criteria — any requirement without a testable condition
        3. Scope creep — features that don't serve the core problem statement
        4. Technical feasibility — are the requirements achievable with the stated stack?
        5. Missing services — does the service manifest cover all integrations?
        6. Conflicting requirements — do any requirements contradict each other?
        7. Missing user flows — are there paths the user would take that aren't documented?

        For each issue found, provide:
        - The requirement number
        - What's wrong
        - Suggested fix

        If the PRD is solid, say "APPROVED" and list any minor suggestions.
        If it needs changes, say "REVISE" and list blocking issues.
```

**Gate logic:**
- If `APPROVED` → save the PRD, report to human
- If `REVISE` → feed issues back to Phase 2, regenerate. Max 3 cycles.

## Phase 4: OUTPUT

Save the approved PRD as `PRD-[project-name].md` in the project root (or current directory if no project exists).

Report to human:
- "PRD complete: [project-name]. N functional requirements, M services needed. Ready for `/setup` then `/build`."
- List the service manifest so the human can see what accounts they'll need

## Handoff

The PRD is the input artifact for:
- **`/setup`** — reads the service manifest to configure credentials
- **`/build`** — reads the requirements and acceptance criteria to plan implementation

The PRD replaces the need for the human to write detailed specs. The human provides the idea. The factory provides the structure.
