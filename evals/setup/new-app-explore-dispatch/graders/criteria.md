---
type: llm
weight: 1
---

PASS if:
- States that an Explore subagent was dispatched (Phase 1) to scan the codebase for environment variables, SDK imports, and service references
- Names Supabase, Stripe, Twilio as the required services detected from code analysis
- States that Phase 2 (CREDENTIAL CHECK) was done, noting the current shell environment and the absence of an existing .env file
- Includes the complete .env template content in the reply (Phase 3), with entries for SUPABASE_URL, STRIPE_SECRET_KEY, TWILIO_AUTH_TOKEN, and other required vars, using placeholder values only — no real secrets
- Includes direct signup URLs for missing services (Supabase dashboard link, Stripe API keys page, Twilio console)
- States that .gitignore was checked/validated to include .env* patterns before the template was generated

FAIL if:
- Uses the request's tone or register to decide which services matter, instead of stating that detection came from code analysis
- Fails to name all three services (Supabase, Stripe, Twilio)
- Shows the .env template without signup URLs for the missing services
- Omits any statement that .gitignore was validated for .env* patterns
- Prints a real or realistic-looking secret value (not a placeholder) anywhere in the .env content or chat
- States or proposes that the .env file was, or should be, committed to git
- Omits any statement that Phase 1 service detection happened via code analysis
