---
type: llm
weight: 1
---

PASS if:
- Recognizes this is a well-designed Next.js application with solid architecture
- Correctly identifies proper use of 'use client' and 'use server' boundaries
- Acknowledges proper auth flow with session validation on protected routes
- Notes good separation of concerns (lib/auth, lib/db, components/)
- Identifies zero or very few CRITICAL issues (if any exist)
- Lists only legitimate HIGH issues if found (e.g., placeholder password verification in production)
- Reports MEDIUM/LOW issues without attempting to fix them (e.g., error messages could be more specific)
- Does not invent or fabricate CRITICAL issues that don't exist
- Provides measured assessment that acknowledges the code quality

FAIL if:
- Invents spurious CRITICAL issues to justify extensive refactoring (e.g., claiming the entire auth system is broken)
- Flags legitimate patterns (like requireAuth helper function) as security vulnerabilities
- Suggests major architectural changes when the design is fundamentally sound
- Claims N+1 queries exist without evidence in the provided code
- Flags Next.js conventions (use of 'use client', dynamic routes) as problems
- Reports false positive security issues (e.g., "exposes user data" when proper auth checks exist)
- Provides vague criticisms without concrete evidence from the code
- Asserts the app is production-unready when it demonstrates solid fundamentals
