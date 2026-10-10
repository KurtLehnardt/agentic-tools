---
name: determine-market-interest-validation-build-meeting-notes
description: Validate idea with strong demand, supply gap, and monetization model
tags: [determine-market-interest]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 20
---

I want to validate an idea: "an AI tool that transcribes meeting recordings to meeting notes and summaries."

Here's the market research data I've collected. Please analyze whether there's a real market for this.

## Derived Queries (from the idea phrasing)

Problem intent:
- "transcribe meeting recordings to notes" - 8,200 monthly searches (Estimated), rising
- "automatic meeting note taking" - 5,400 monthly searches (Estimated), rising
- "AI meeting transcript summarizer" - 3,100 monthly searches (Estimated), flat

Solution intent:
- "meeting transcription software" - 4,800 monthly searches (Estimated), flat
- "transcription app for meetings" - 2,100 monthly searches (Estimated), rising

Competitor searches:
- "Otter.ai" - 18,000 monthly searches (Estimated)
- "Fireflies.io" - 2,100 monthly searches (Estimated)

## Existing Solutions (Supply Assessment)

1. **Otter.ai** - https://otter.ai
   - Quality: 4.5/5 on Trustpilot
   - Failure modes: Expensive ($120/month for business plan), requires Otter account, UI cluttered for simple one-off meetings, customer complaints about accuracy on technical jargon, limited languages

2. **Fireflies.io** - https://firefiles.io
   - Quality: 4.2/5
   - Failure modes: $10/month minimum, lacks built-in summary (requires separate prompt), poor mobile experience, less popular (fewer integrations)

3. **Google Meet recording + manual transcription** - not a product, people still doing this manually
   - Gap signal: "People also ask" full of "how do I transcribe a meeting", indicating unsolved pain

## SERP Composition

Page 1 contains: 3 working tools, 2 listicles, 1 Wikipedia entry on transcription (articles outnumber tools — gap signal).

## Assumptions for Scoring

- Build baseline: Next.js + Supabase + cloud storage for audio
- Stack ease: Medium (audio handling, API integrations, but no on-device ML needed)
- Payer: Small business owner, freelancer, or corporate training department
- Price point: $15/month (undercut Otter by 80% with narrower feature set) or $2 per recording (usage-based)

Does this market validate? What's your verdict on building this?
