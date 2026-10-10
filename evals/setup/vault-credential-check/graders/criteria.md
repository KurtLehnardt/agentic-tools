---
type: llm
weight: 1
---

PASS if:
- States that Phase 2 (CREDENTIAL CHECK) was done in the correct order: first checking .env/current shell, then calling the 1Password CLI
- States that `op item list --tags podcast-app` was used to retrieve vault items
- Categorizes credentials as READY (Supabase, Anthropic found in vault), PARTIAL (Firebase exists but outdated), MISSING (Stripe not found)
- States that no 1Password password prompt occurred (CLI assumed already authenticated)
- Includes the complete Phase 3 .env content in the reply, with status markers showing which services came from vault vs .env, using placeholder values only — no real secrets
- Lists a direct Firebase console link and the Stripe API key dashboard link for the MISSING/outdated services
- States that vault-retrieved secrets were not logged into chat

FAIL if:
- States or implies credential sources were checked out of order (correct order: .env/shell → 1Password → AWS SSM → environment)
- Proposes prompting for a 1Password password interactively
- Prints a real or realistic-looking secret value (not a placeholder) retrieved from the vault or anywhere in the .env content
- Fails to categorize credentials as READY/PARTIAL/MISSING
- Omits the Phase 3 .env content with status markers
- States or proposes that the .env file or vault secrets were, or should be, committed to git
- Omits any statement that the 1Password credential check happened
