---
type: llm
weight: 1
---

PASS if:
- Executes Phase 2 (CREDENTIAL CHECK) in correct order: first checks .env/current shell, then calls 1Password CLI
- Uses `op item list --tags podcast-app` to retrieve vault items
- Categorizes credentials as READY (Supabase, Anthropic found in vault), PARTIAL (Firebase exists but outdated), MISSING (Stripe not found)
- Does not prompt for 1Password password interactively (only uses CLI if already authenticated)
- Includes Phase 3 output with status markers showing which services came from vault vs .env
- Lists direct Firebase console link and Stripe API key dashboard for MISSING services
- Validates that retrieved secrets from vault are not logged into chat

FAIL if:
- Checks credential sources out of order (should be: .env/shell → 1Password → AWS SSM → environment)
- Proposes prompting for 1Password password interactively
- Outputs vault-retrieved secrets into chat
- Fails to categorize credentials as READY/PARTIAL/MISSING
- Does not include Phase 3 .env output with status markers
- Commits .env or vault secrets to git
- Skips 1Password credential check
