---
type: llm
weight: 1
---

PASS if:
- Dispatches Explore subagent (Phase 1) to scan codebase for environment variables, SDK imports, and service references
- Detects Supabase, Stripe, Twilio as required services from code analysis
- Executes Phase 2 (CREDENTIAL CHECK) examining current shell environment and missing .env file
- Generates .env template (Phase 3) with entries for SUPABASE_URL, STRIPE_SECRET_KEY, TWILIO_AUTH_TOKEN, and other required vars
- Includes direct signup URLs for missing services (Supabase dashboard link, Stripe API keys page, Twilio console)
- Validates .gitignore includes .env* patterns before generation

FAIL if:
- Uses request tone or register to determine which services are important instead of reading code
- Fails to detect all three services (Supabase, Stripe, Twilio) from codebase analysis
- Generates .env without signup URLs for MISSING services
- Does not validate .gitignore .env* patterns
- Outputs actual secret values into chat
- Proposes committing .env file to git
- Skips Phase 1 service detection via code analysis
