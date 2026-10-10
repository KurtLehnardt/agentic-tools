---
type: llm
weight: 1
---

PASS if:
- Issues PIVOT verdict
- Explicitly names where the real demand is: "salon booking software" or "profession-specific scheduling" or "hair salon appointment booking" (12,000 rising searches, but only when narrowed by use case)
- Explains why the generic "simple free booking" idea is weak: Calendly is sticky (4.7★, 31K searches for it), Google Calendar is free and built-in, your generic option has no lock-in or advantage
- Shows the gap vs. Calendly: people search "Calendly alternative" (8,100) and "free appointment booking" (12,000 rising) but these are mostly niche use cases looking for profession-specific features
- Acknowledges the real demand is in "hair salon booking", "therapist scheduling", etc. — specific enough to be verifiable and buildable, but not what was proposed
- Scores the proposed generic idea as: D=6 (declining/flat demand for generic), S=2 (Calendly crushes it, free alternatives exist), M=5 (monetization weak when generic, hard to charge against free Google Calendar), B=8 (buildable but no defensibility) = 480 opportunity (unviable as proposed)
- Recommends pivoting: instead of "simple free generic", build "salon scheduling with client notifications" or "therapist booking with intake forms"
- Explains what would have to be true to change verdict: specificity to one profession, and pricing tied to that profession's willingness to pay ($10-50/month for workflow automation specific to their needs)
- Does not suggest the idea is DON'T BUILD — it points to where the real demand sits

FAIL if:
- Issues BUILD verdict (contradicts declining/flat generic search demand)
- Does not name the pivot direction explicitly
- Claims generic "simple free" app can compete with Calendly
- Does not acknowledge Calendly's strength (4.7★, 31K searches)
- Omits subscores or does not multiply them
- Misses the rising "book appointment" searches are niche (profession-specific) not generic
- Suggests abandoning the space entirely (should pivot, not reject)
- Does not explain the ordering: solve for profession first, not generic
