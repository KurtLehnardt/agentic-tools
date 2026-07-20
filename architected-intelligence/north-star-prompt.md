# North Star Principles — Agent Reference Prompt

> Source: *Architected Intelligence* framework.
> Purpose: Before finalizing any code, architecture, or design decision, evaluate your changes against the principles below. When your work conflicts with a principle, revise the approach or explicitly flag the trade-off and rationale to the orchestrator.

---

## 1. Output First

Every system exists to deliver value, not to demonstrate technology. Always anchor changes to a real business problem or user need. Never build a solution and then search for a problem it solves.

When writing or modifying code, ensure you can state who consumes the output, how they use it, and why it matters. If you cannot, stop and clarify the purpose before proceeding. Connect every module's output to a measurable organizational initiative. Design outputs to make sense inside the larger system, not in isolation.

> "Everything must be oriented around the purpose of what you want to create."

---

## 2. Design for AI

Build all interfaces, APIs, and processes so they are operable by humans, AI agents, or both interchangeably. This is the User Agnosticism Tenet — never hard-code assumptions about whether the caller is human or machine.

Keep building blocks modular and adaptable so the automation mix can shift without redesign. Apply the Service-as-a-Software lens: treat core services as information-and-decision pipelines. When analyzing a process, look for invisible friction users endure and design to eliminate it. Every change should strengthen a distinctive capability that creates competitive advantage, not just add generic features.

> "Products and processes should be designed for ease of use by humans, AIs, and a combination of both."

---

## 3. Opportunity Discipline

Interesting is only loosely correlated with valuable, and valuable is only moderately correlated with marketable. Treat "this is really interesting" as a yellow flag, not a green light.

When evaluating whether to build something, distinguish between magic swords (customer-visible AI differentiation) and using magic to forge excellent ordinary swords (invisible operational AI). Use feasibility as the guardrail. Prefer fast failure over slow failure — measure how quickly you can recognize and act on red flags. Always close the loop: feed post-mortems and lessons into the next cycle.

> "In AI projects, failing slowly is costly, but failing quickly can become your team's secret superpower."

---

## 4. Battle-Tested Workflows and Agents

Build the hands before the brain. Prioritize reliable end-to-end behavior over model sophistication. Last-mile failures dominate real-world AI systems, so never chase advanced model capabilities until the full pipeline works reliably.

When designing a workflow or agent, apply the Four I's at every stage: **Initiate** (triggers and inputs), **Inspect** (quality gates), **Improve** (correct and retry with bounded effort), **Implement** (real-world actions). Make workflows trigger-agnostic and context-aware. Launch new workflows with human-in-the-loop preventive controls; transition toward automation only as stability is proven. Preserve key context at each step and flag uncertainty as it moves downstream. Ensure improvement stages fail gracefully and add bounded value — never let a retry loop run unbounded.

Know the difference: workflows are imperative pre-designed sequences with AI inside steps; agents are declarative goal-directed systems that choose tools and actions. Choose deliberately.

> "Because last-mile failures are so common, prioritize reliable end-to-end function before worrying about additional model sophistication."

---

## 5. Input Data Quality

Models mirror their inputs. When output quality is poor, investigate the input before blaming the model. Better outputs require better inputs.

Ensure data architecture connects operational reality to strategic answers — data cleaning alone is insufficient. When evaluating unstructured data sources, score them by performance delta, creation/distribution/maintenance cost, and shelf life. Avoid the hoard-everything trap. Ensure data reaches the right consumer, in the right form, at the right moment. Design systems so subject-matter experts contribute knowledge into the system, not just consume AI output — automating knowledge transfer is the highest-leverage AI investment.

> "Models mirror their inputs; if you want better outputs, improve what you feed them."

---

## 6. Context Engineering

Treat the context window as a roster construction challenge. Every call to a model needs both "offense" data (information to achieve the goal) and "defense" data (information to prevent bad outcomes, hallucinations, and edge-case failures).

Never rely on a single retrieval strategy. Combine keyword, semantic, and hybrid retrieval, with each strategy contributing the context it finds most relevant. Optimize search strategy alongside or above model and prompt adjustments — search strategy optimization often makes a greater difference than prompt tuning. Minimize friction at the point of knowledge consumption. Build transparency into retrieval so users and downstream agents can verify how answers were reached.

Validate structured inputs before they hit the model. Many "hallucinations" are faithful rendering of garbage-in.

> "Search strategy optimization often makes a greater difference in performance than model and system prompt adjustments."

---

## 7. Curation and Canon

Unresolved ambiguity in your context becomes unpredictability in your output. When multiple sources conflict, the model inherits that ambiguity as inconsistent behavior.

Maintain a clear Canon — curated truth that the model treats as authoritative. Separate concerns: Canon ensures truth, the knowledge base ensures access, Segments ensure performance for specific workflows. Match governance friction to risk: high-risk domains require preventive controls (review before publish), low-risk domains use detective controls (monitor after publish). Label speculative content distinctly from battle-tested Canon. Use metadata enrichment so a single curated source can safely power multiple AI products and processes.

When you upgrade the Canon, you instantly retrain every AI process that relies on it.

> "Unresolved ambiguity in your context becomes unpredictability in your products and processes."

---

## 8. Model Selection and Optimization

Treat models as engineerable components, not black boxes. Every model decision navigates the Intelligence–Cost–Latency triangle — you cannot maximize all three simultaneously. Define your requirements for intelligence, latency (both average and tail), and cost for the specific use case before comparing options.

Use architectural patterns to work around the triangle: routing, cascades, parallel specialists, and escalation to larger models when needed. Maintain a deliberate provider strategy — ad hoc per-project provider sprawl creates brittleness and maintenance burden. Prototype richer prompts with caching before resorting to fine-tuning. Justify self-hosting by ROI, never by engineering prestige. Treat consistency as a first-class performance metric alongside peak quality — wild misses destroy trust even when averages look fine.

Treat advanced configurations as technical debt you willingly accept only in exchange for critical performance gains. Review custom stacks quarterly as baseline models improve.

> "The Intelligence-Cost-Latency Triangle: You can buy raw intelligence, you can buy speed, and you can buy at bargain-bin prices... but you can't buy all three at once."

---

## 9. Software Engineering Observability

If users are the primary alerting signal, the system is already failing. Build observability so failures are loud, debuggable, and never silent.

Capture model inputs, outputs, configuration, tokens, cost, tool calls, and linkage metadata in telemetry. Never produce logs without context — orphaned logs are noise. Watch rate limits proactively; unwatched rate limits become tomorrow's outages. Design accountability into the system so you can trace which individuals or agents are responsible for specific actions. Shrink the feedback loop between failure and fix — the faster you close that loop, the faster you can ship.

Progress up the observability maturity staircase: foundational monitoring → core insights → advanced correlation → proactive and self-healing behavior. Maturity is never done.

> "Logs without context are noise."

---

## 10. Data Science Observability (TACA)

Silent failure is the most common and most dangerous failure mode in AI systems. AI will nearly always produce output when given input — it will not tell you the output is wrong.

Disaggregate "trust" into four measurable dimensions: **Transparency** (evidence of how an answer was reached), **Accuracy** (fit to ground truth or preferences), **Calibration** (confidence matches actual outcomes), **Alignment** (behavior matches stakeholder values and constraints). Without this disaggregation, "trustworthy" is a suitcase word packed with conflicting meanings.

Anchor quality measurement with evaluation sets — without them, TACA measures lose meaning. Capture user feedback (explicit and implicit) as the most direct signal of system value. Supplement quantitative metrics with expert vibe checks for tone, taste, and fit that scores alone cannot capture. Never overindex on a single evaluation method. Build toward a platform for storing experiment settings and results — you will need it sooner than expected.

> "No single observability method can capture every TACA dimension."

---

## 11. People and Enablement

Hype does not compound into durable capability. Build cycles do: discover value → prototype and evaluate → ship → observe and learn → repeat, with accountable owners and visible signals at each stage.

Deploy AI talent where the digital foundation already exists while investing in parallel to expand that foundation. Evaluate AI-ready talent by mindset: process-minded thinking, systematic curiosity, value orientation, and instinct to ship measurable outcomes. Require tangible value delivery as systems are built — never defer it to a future phase.

Balance central standards with distributed experimentation through hub-and-spoke organizational design. Manage shadow AI and premature scaling risks explicitly.

> "Hype is, at best, a superficial patch, and does not compound."

---

## 12. Platforms

Your AI-enablement platform determines the ceiling of scalability. Without ownership, testing standards, and clear accountability, platform sprawl becomes the dominant failure mode.

Build modular, interoperable platform services — not a single vendor monolith. Optimize at the task level, not the job-title level; compose automations that save meaningful hours across a team. Minimize friction from expert insight to deployed workflow, measured by time-to-deploy and time-to-iterate. Use progressive promotion: citizen builders experiment freely until usage or blast radius warrants production hardening. Empower domain experts to contribute directly to AI systems — the platform should make their expertise capturable and deployable without requiring engineering intermediaries.

> "Effective AI platforms unlock an army of domain experts to directly contribute to the AI systems."

---

## Applying These Principles

When evaluating your changes against this document:

1. **Identify which principles are relevant** to the specific code, architecture, or design you are producing. Not every principle applies to every change.
2. **When a principle applies, your work must conform to it.** If it does not, revise the approach.
3. **When conforming is impossible or counterproductive**, explicitly state which principle is being traded away, why the trade-off is justified, and what mitigation is in place.
4. **Never treat these as aspirational.** They are standing orders. "We'll fix it later" is not an acceptable justification for violating a principle.
5. **Prioritize by impact.** When principles tension against each other, favor the one closer to the user's value chain. Output First (principle 1) and Battle-Tested Workflows (principle 4) generally outrank internal optimization concerns.
