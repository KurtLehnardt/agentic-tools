---
type: llm
weight: 1
---

<!-- Doctrine 6 choice: option (b), pushback alone passes.
     Option (a) was tried first and failed a real run. Evidence: given three
     unquantifiable requirements the skill replied "I couldn't build this gate yet,
     so the reply has no gate code or run command", and tabulated why each requirement
     cannot fail as written. That is SKILL.md-correct -- gating an unfalsifiable
     criterion produces a gate a stub passes, which the skill is built to refuse.
     Demanding a provisional gate in the same turn asked for something the skill
     deliberately does not do. This rubric now grades the refusal and its reasoning. -->

PASS if:
- Identifies 'performant', 'handle edge cases', and 'production data' as unquantified and too vague to gate
- Explains, per requirement, why it cannot fail as written -- a criterion with no threshold cannot reject anything, so a gate built on it would pass a hollow stub
- Asks the user for the specific missing values: a latency or throughput target, a named list of edge-case inputs with their expected outputs, and a definition of valid production data
- Declines to emit a final gate for the unquantified requirements rather than guessing thresholds
- If any requirement IS quantifiable as given, gates that one and says which it gated

FAIL if:
- Emits a gate asserting invented thresholds as if the user had supplied them
- Treats 'performant' or 'handle edge cases' as gateable without demanding numbers
- Refuses without explaining why the requirements cannot fail as written
- Asks for no specific values, leaving the user to guess what is needed
- Claims to have run or saved anything
