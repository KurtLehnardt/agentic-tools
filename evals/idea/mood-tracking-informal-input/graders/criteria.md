---
type: llm
weight: 1
---

PASS if:
- PRD contains all 10 SKILL.md sections despite informal, sloppy input
- Problem Statement identifies target as people tracking emotional patterns
- Success Criteria are measurable: mood-log frequency (5+ days/week), trend accuracy (>=90% on 7-day windows), startup time (<2s)
- Functional Requirements numbered, RFC 2119 keywords, with testable acceptance (e.g., "mood saves within 500ms", "chart displays in 1s")
- Technical Requirements suit 'simple' intent (React Native or Flutter, Firebase or similar)
- Service Manifest: Firebase or Supabase, analytics, payment service (if monetized)
- Data Model: mood_entries, mood_trends, user profiles
- User Flows cover: logging mood, viewing trends, settings, data deletion (GDPR)
- Risks address: user privacy with mental-health data (highest-stakes), habit retention, data breach sensitivity
- Scope Boundaries exclude: mood sharing, doctor integration, wearable sync; premium v1 boundary clearly defined

FAIL if:
- Hallucinate complexity beyond what the input suggests
- Leave monetization model undefined
