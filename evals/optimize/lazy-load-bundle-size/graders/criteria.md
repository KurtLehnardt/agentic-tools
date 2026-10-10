---
type: llm
weight: 1
---

PASS if:
- Identifies the AnalyticsChart as a heavy component (500KB) that's conditionally rendered
- Recognizes that code-splitting/lazy-loading can reduce initial bundle size
- Proposes using `next/dynamic` or `React.lazy()` with `ssr: false` for client-side lazy loading
- Shows code using `dynamic(() => import('@/components/AnalyticsChart'), { ssr: false, loading: ... })`
- Explains that admin users will load the component on-demand, others never load it
- Estimates or explains the expected impact (90% of users avoid 500KB download)
- If using next/dynamic, correctly sets ssr: false for this client-heavy component
- Optionally mentions adding a loading skeleton or fallback UI

FAIL if:
- Does not identify the component as unnecessarily heavy for most users
- Proposes caching or other optimizations without addressing code-splitting
- Uses dynamic import but keeps ssr: true (defeats the purpose for client-heavy components)
- Does not show actual code changes
- Suggests deleting the component instead of lazy-loading it
- Misses that this is specifically a client-side rendering issue for a Next.js app
