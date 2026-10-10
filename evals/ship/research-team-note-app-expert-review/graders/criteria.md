---
type: llm
weight: 1
---

PASS if:
- Recognizes explicit request for expert reviews
- Triggers Phase 2 (Expert Reviews)
- Produces Phase 1 (Discover) output describing product, positioning, and stage
- Dispatches UX Architect subagent to critique positioning, funnel, mobile/accessibility, competitive positioning
- Dispatches Business Executive subagent to critique go-to-market timing, pricing, user acquisition projections, competitive gaps
- Both subagents dispatched in parallel
- Documents where expert reviews agree (e.g., both identify critical feature gaps)
- Documents where expert reviews disagree (e.g., mobile vs. desktop positioning)
- Synthesizes disagreements with executive reasoning and makes clear decision call
- Updates questions.md file documenting expert insights and decisions made
- Produces strategy document informed by both expert reviews
- Strategy includes callouts referencing which experts recommended which strategies

FAIL if:
- Skips Phase 2 expert reviews entirely
- Dispatches only one expert reviewer (not both)
- Phase 1 output missing or generic without product/positioning/stage details
- UX Architect critique missing or incomplete
- Business Executive critique missing or incomplete
- Reviewers not dispatched in parallel
- No documentation of expert review agreements
- No documentation of expert review disagreements
- Missing synthesis or conflict resolution between reviewers
- No questions.md file or incomplete documentation of expert insights
- Strategy produced without reference to expert reviews
- No callouts in strategy to specific expert recommendations
