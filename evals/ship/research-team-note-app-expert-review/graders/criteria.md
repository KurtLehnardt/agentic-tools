---
type: llm
weight: 1
---

PASS if:
- Recognizes explicit request for expert reviews
- States that Phase 2 (Expert Reviews) is triggered
- Produces Phase 1 (Discover) output describing product, positioning, and stage
- Presents a UX Architect critique covering positioning, funnel, mobile/accessibility, competitive positioning
- Presents a Business Executive critique covering go-to-market timing, pricing, user acquisition projections, competitive gaps
- States that both reviews were run in parallel
- Documents where expert reviews agree (e.g., both identify critical feature gaps)
- Documents where expert reviews disagree (e.g., mobile vs. desktop positioning)
- Synthesizes disagreements with executive reasoning and makes clear decision call
- The reply states or shows the expert insights and decisions logged (as questions.md content or inline in the reply)
- Produces strategy document informed by both expert reviews
- Strategy includes callouts referencing which experts recommended which strategies

FAIL if:
- Skips Phase 2 expert reviews entirely
- Presents only one expert critique (not both)
- Phase 1 output missing or generic without product/positioning/stage details
- UX Architect critique missing or incomplete
- Business Executive critique missing or incomplete
- Does not state that the reviews were run in parallel
- No documentation of expert review agreements
- No documentation of expert review disagreements
- Missing synthesis or conflict resolution between reviewers
- The reply never states or shows the logged expert insights and decisions
- Strategy produced without reference to expert reviews
- No callouts in strategy to specific expert recommendations
