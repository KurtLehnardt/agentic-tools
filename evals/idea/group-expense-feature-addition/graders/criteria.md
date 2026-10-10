---
type: llm
weight: 1
---

PASS if:
- PRD recognizes this as feature addition to existing codebase, not greenfield
- Problem Statement references existing users and group split-expense need
- Success Criteria measurable: settlement minimizes transfers, splits reconcile in <5s, 100% accuracy, support <=20 members
- Functional Requirements numbered, RFC 2119, with testable acceptance (e.g., "transfer within 1s of settlement click", "webhook confirms status")
- Non-Functional Requirements specify: sub-5s settlement latency, 99.5% webhook reliability
- Technical Requirements respect existing stack (Next.js, Supabase, Stripe); specify webhooks and schema additions
- Service Manifest: Stripe (new routes), Supabase (new schema)
- Data Model: split_groups, split_ledger, settlement_transactions
- User Flows: group setup, add expense, view split, settle, confirm
- Risks address: payment failure mid-settlement (highest-stakes), race conditions, partial payment
- Scope Boundaries exclude: multi-currency, recurring splits, email invites, SMS

FAIL if:
- Suggests schema migration or treats it as greenfield project
