---
name: determine-market-interest-discovery-mode-four-domains
description: Discovery mode finds app ideas across default four domains
tags: [determine-market-interest]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 20
---

What app should I build? I'm comfortable with Next.js and Supabase.

Here's some market research across the default four domains I want you to consider: personal finance, small business ops, legal/admin paperwork, and home/DIY.

## Domain: Personal Finance

Candidate: "freelancer quarterly tax calculator"
- Query volume: 6,200/month (Estimated), rising
- Competitors: TurboTax (overkill, $120-250), Wave (free, minimal features), custom spreadsheets
- SERP composition: 1 tool, 4 articles = gap signal
- Subscores: D=7, S=8, M=8 (clear payer: freelancer), B=9 (buildable in days on Next+Supabase)
- Opportunity: 4,032
- Supply weaknesses: TurboTax is over-engineered and expensive, Wave lacks customization, no mobile-friendly option

## Domain: Small Business Ops

Candidate: "contractor invoice generator with retainer tracking"
- Query volume: 4,100/month (Estimated), flat
- Competitors: Stripe Invoicing (basic, $0-50/month but coupled to payments), Wave (free), custom tools
- SERP composition: 2 tools, 3 articles
- Subscores: D=6, S=7, M=8, B=9
- Opportunity: 3,024
- Supply weaknesses: No niche solution for retainer-specific logic, Wave is generic

## Domain: Legal/Admin Paperwork

Candidate: "LLC formation document checklist app"
- Query volume: 2,100/month (Estimated), rising
- Competitors: LegalZoom ($200-500), Rocket Lawyer ($99/month), DIY templates (free but unverified)
- SERP composition: 2 paid services, 1 article, heavy listicles
- Subscores: D=5, S=8, M=9 (premium service, high willingness to pay), B=7 (moderate complexity)
- Opportunity: 2,520
- Supply weaknesses: DIY path exists but risky, paid services are expensive/overkill for simple LLCs

## Domain: Home/DIY

Candidate: "deck design cost estimator with material calculator"
- Query volume: 1,800/month (Estimated), flat
- Competitors: Lowe's calculator (free, basic), custom spreadsheets, contractors' tools
- SERP composition: mostly articles and listicles, no dedicated tool visible
- Subscores: D=4, S=8, M=6 (monetization weak: one-time purchase only), B=8
- Opportunity: 1,536
- Supply weaknesses: Lowe's tool incomplete, expensive contractors needed for estimates

---

All kills at gates have been checked: none of these trip Gate 1-6. All passed kill-gate.md review.

What are the top 3 opportunities ranked by opportunity score? Should I pick one?
