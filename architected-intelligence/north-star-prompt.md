# North Star: Architectural Principles for AI-First Systems

> Source: *Architected Intelligence* framework. All agents and subagents MUST validate their work against these principles before finalizing output.

---

## How to Use This Document

Before completing any task — code, architecture, design, or decision — scan the relevant sections below. If your output violates a principle, revise or flag the conflict. When trade-offs are unavoidable, name the principle being traded away and why.

---

## 1. Output First

**Every system starts from the value it delivers, not the technology it uses.**

- [ ] Does this work solve a real business problem or user need, not just a technical curiosity?
- [ ] Is the output connected to an organizational initiative with measurable value?
- [ ] Can you articulate *who* uses this output, *how*, and *why it matters*?
- [ ] Are you avoiding the builder's trap — inventing solutions and searching for problems?

> "Everything must be oriented around the purpose of what you want to create."

---

## 2. Design for AI

**Build systems that humans, AIs, or both can operate interchangeably.**

- [ ] Is the design user-agnostic — usable by humans, AI agents, or a combination?
- [ ] Are building blocks modular and adaptable as the automation mix changes?
- [ ] Does this strengthen a distinctive capability (competitive edge), not just a generic one?
- [ ] Are you applying the Service-as-a-Software lens — treating processes as information-and-decision pipelines?
- [ ] Have you considered invisible processes users face and designed to eliminate them?

> "Products and processes should be designed for ease of use by humans, AIs, and a combination of both."

---

## 3. Opportunity Discipline

**Interesting ≠ valuable ≠ marketable. Filter ruthlessly.**

- [ ] Has this opportunity passed through Cultivate → Evaluate → Select → Learn?
- [ ] Are you distinguishing between "magic swords" (customer-visible AI) and "magic forging" (invisible operational AI)?
- [ ] Is feasibility the guardrail — not ambition alone?
- [ ] Are you failing fast when signals are bad, not slowly?
- [ ] Are post-mortems feeding back into the next cycle?

> "Interesting is only loosely correlated with valuable, and valuable is only moderately correlated with marketable."

---

## 4. Battle-Tested Workflows and Agents

**Build the hands before the brain. Reliable end-to-end behavior beats model sophistication.**

- [ ] Is this a workflow (imperative, pre-designed steps) or an agent (declarative, goal-directed)? Is that the right choice?
- [ ] Does the design cover all Four I's: **Initiate**, **Inspect**, **Improve**, **Implement**?
- [ ] Is the workflow trigger-agnostic and context-aware?
- [ ] Are you launching with human-in-the-loop controls and planning a transition to automation as stability is proven?
- [ ] Do improvement stages fail gracefully and add bounded value?
- [ ] Is key context preserved at each step, with uncertainty flagged downstream?
- [ ] Are you prioritizing reliable end-to-end function before additional model sophistication?

> "Because last-mile failures are so common, prioritize reliable end-to-end function before worrying about additional model sophistication."

---

## 5. Input Data Quality

**Models mirror their inputs. Better outputs require better inputs.**

- [ ] Is the data architecture connecting operational reality to strategic answers — not just "cleaning data"?
- [ ] Are you scoring unstructured data candidates by: performance delta, creation/distribution/maintenance cost, and shelf life?
- [ ] Does the data reach the right people, in the right form, at the right moment?
- [ ] Are subject-matter experts contributing knowledge — not just consuming AI output?
- [ ] Are you avoiding the hoard-everything trap?

> "Automating the transfer of knowledge is the holy grail of AI empowerment."

---

## 6. Context Engineering

**Treat the context window as a roster construction challenge.**

- [ ] Are you fielding "offense" data (achieve the goal) AND "defense" data (prevent bad outcomes)?
- [ ] Are you combining retrieval strategies (keyword, semantic, hybrid) rather than relying on one?
- [ ] Is search strategy optimization prioritized alongside (or above) model/prompt tweaks?
- [ ] Is friction minimized at the point of knowledge consumption?
- [ ] Is the system transparent enough to overcome the trust deficit?

> "Search strategy optimization often makes a greater difference in performance than model and system prompt adjustments."

---

## 7. Curation and Canon

**Unresolved ambiguity in context becomes unpredictability in output.**

- [ ] Is there a clear Canon (curated truth the model treats as authoritative)?
- [ ] Are concerns separated: Canon (truth), Knowledge Base (access), Segments (performance)?
- [ ] Does governance friction match risk — high-risk domains get preventive controls, low-risk get detective controls?
- [ ] Is speculative content labeled as such, distinct from battle-tested Canon?
- [ ] Is metadata enrichment enabling a single source to power multiple AI products?

> "When you upgrade the Canon, you instantly retrain the AI workforce relying upon it."

---

## 8. Model Selection and Optimization

**Models are engineerable components, not untouchable black boxes.**

- [ ] Are you explicitly navigating the Intelligence–Cost–Latency triangle for this use case?
- [ ] Have you defined intelligence, latency (average AND tail), and cost before comparing vendors?
- [ ] Are you using architectural patterns (routing, cascades, escalation) to "cheat" the triangle?
- [ ] Is the provider strategy deliberate — not ad hoc per-project sprawl?
- [ ] Are you prototyping richer prompts with caching before resorting to fine-tuning?
- [ ] Is self-hosting justified by ROI, not engineering prestige?
- [ ] Is consistency treated as a performance metric alongside peak quality?

> "Complexity compounds obligation. Advanced configurations should be treated as technical debt you willingly accept in exchange for critical performance gains."

---

## 9. Software Engineering Observability

**If users are the primary alerting signal, the system is already in trouble.**

- [ ] Are model inputs, outputs, configuration, tokens, cost, and tool calls captured in telemetry?
- [ ] Are logs contextualized — not orphaned noise?
- [ ] Are rate limits watched, not ignored?
- [ ] Can you trace accountability — which individuals are responsible for specific actions?
- [ ] Is the feedback loop from failure to fix fast enough to ship features confidently?
- [ ] Are you progressing up the maturity staircase (monitoring → insights → correlation → proactive)?

> "Logs without context are noise."

---

## 10. Data Science Observability (TACA)

**Silent failure is the most common and most dangerous failure mode in AI systems.**

- [ ] Are you measuring all four TACA dimensions: **Transparency**, **Accuracy**, **Calibration**, **Alignment**?
- [ ] Are evaluation sets anchoring your quality measurement — not just vibes?
- [ ] Is user feedback (explicit and implicit) captured as the most direct value signal?
- [ ] Are expert "vibe checks" supplementing quantitative metrics for tone, taste, and fit?
- [ ] Are you avoiding overindexing on a subset of context evaluation methods?
- [ ] Is there a platform for storing experiment settings and results?

> "Without TACA, the word 'trustworthy' becomes a suitcase word, packed with conflicting meanings."

---

## 11. People and Enablement

**Hype does not compound. Build cycles do.**

- [ ] Is the path: discover value → prototype → ship → observe → learn → repeat?
- [ ] Are owners accountable at each stage with visible signals?
- [ ] Are you deploying talent where the digital foundation already exists?
- [ ] Is the organizational design hub-and-spoke — balancing central standards with distributed experimentation?
- [ ] Is AI-ready talent evaluated by mindset (process thinking, curiosity, value orientation, instinct to ship)?
- [ ] Are you requiring tangible value delivery as systems are built — not deferring it?

> "Hype is, at best, a superficial patch, and does not compound."

---

## 12. Platforms

**Your AI-enablement platform determines the ceiling of scalability.**

- [ ] Is the platform modular and interoperable — not a single vendor monolith?
- [ ] Are you optimizing tasks (not job titles) and composing automations that save hours across a team?
- [ ] Is there clear ownership, testing standards, and accountability to prevent microservice-style sprawl?
- [ ] Is friction from expert insight to deployed workflow minimized (measure time-to-deploy and time-to-iterate)?
- [ ] Does progressive promotion move citizen experiments to production hardening as usage or blast radius warrants?
- [ ] Are domain experts empowered to contribute directly to AI systems?

> "Effective AI platforms unlock an army of domain experts to directly contribute to the AI systems."

---

## Quick Validation Checklist

Before finalizing any output, confirm:

1. **Value-anchored** — Solves a real problem, not a technical curiosity
2. **User-agnostic** — Works for humans, AI, or both
3. **Fail-fast** — Red flags surface quickly, not slowly
4. **Hands before brain** — Reliable workflows before sophisticated models
5. **Context-engineered** — Right data, right form, right moment
6. **Observable** — Silent failures are impossible; accountability is traceable
7. **TACA-measured** — Trust is disaggregated, not a suitcase word
8. **Scalable** — Platform and people patterns support compounding, not one-off wins
