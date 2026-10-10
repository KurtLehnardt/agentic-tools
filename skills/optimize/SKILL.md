---
name: optimize
description: "Performance optimization pass — caching, query parallelization, bundle size, rendering, database indexes. Creates a PR with improvements and tests. Trigger: optimize, performance, make it faster, speed up, optimize queries."
user-invocable: true
---

# /optimize — Performance Optimization Pass

You are an **orchestrator** that dispatches a performance optimization specialist to analyze and improve application performance, then validates the changes through critic review.

## Phase 1: ANALYZE & OPTIMIZE

Dispatch an **optimizer subagent** on an isolated worktree:

```
Subagent: Agent tool, subagent_type="general-purpose", isolation="worktree"
Prompt: You are a performance optimization specialist. Analyze the codebase and implement optimizations.

        ## What to optimize:

        ### 1. Query Parallelization
        - Find sequential `await` calls that can be `Promise.all`
        - Server components, server actions, API routes
        - Page data fetching (layout.tsx, page.tsx files)

        ### 2. N+1 Query Elimination
        - Find loops that make individual DB calls per item
        - Replace with batch queries using `.in()` or joins
        - Especially: lists with item counts, task completions per member

        ### 3. Database Indexes
        - Check existing migrations for index coverage
        - Add indexes for: frequently filtered columns, JOIN targets, ORDER BY columns
        - Create a new migration file (check existing numbering to avoid collisions)

        ### 4. Rendering Performance
        - Wrap expensive computations in `useMemo`
        - Wrap callback functions in `useCallback`
        - Ensure FlatList/virtualization for long lists
        - Check calendar views for per-render event filtering

        ### 5. Bundle Size
        - Lazy-load heavy components with `next/dynamic` or `React.lazy`
        - Candidates: AI generators, chart components, rich editors, image uploaders
        - Use `ssr: false` for client-only components

        ### 6. Data Caching
        - Add in-memory or sessionStorage caches for API responses (weather, search)
        - Set appropriate `Cache-Control` headers on API routes
        - Use Next.js `unstable_cache` or `revalidate` for server-side caching
        - Add `staleTime` to client-side queries

        ### 7. Column Selection
        - Replace `SELECT *` with specific columns where only a few fields are needed
        - Especially for member lookups (often only need id, name, color)

        ### 8. Image Optimization
        - Use `next/image` for web images
        - Preload critical images
        - Lazy-load below-fold images

        ## Commit Strategy
        Make separate commits per optimization area:
        1. `perf: parallelize sequential DB queries`
        2. `perf: eliminate N+1 queries with batch fetching`
        3. `perf: add database indexes for common queries`
        4. `perf: memoize expensive renders and lazy-load heavy components`
        5. `perf: add caching for API responses and weather data`

        ## Tests
        Add tests for:
        - Cache TTL behavior
        - Query result correctness after parallelization
        - Lazy-loaded component mounting

        Create a PR with: `gh pr create --title "perf: ..." --body "..."`
        Output TASK_COMPLETE with summary of all optimizations and expected impact.
```

## Phase 2: CRITIC REVIEW

Dispatch a **critic subagent** to review the optimizations:

```
Subagent: Agent tool, subagent_type="general-purpose"
Prompt: Review the performance optimization PR.
        Run: `gh pr diff <number> --patch 2>&1 | head -5000`

        For each optimization, verify:
        1. Correctness — does `Promise.all` preserve the same behavior as sequential?
        2. Error handling — if one parallel query fails, is the error propagated correctly?
        3. Cache invalidation — are caches cleared when data changes?
        4. No regressions — are existing features still working?
        5. Test quality — do tests actually verify the optimization?

        Score >= 9.6/10 to approve. List specific issues if below.
```

**Gate:** If critic < 9.6, dispatch optimizer again with feedback. Max 3 iterations.

## Phase 3: MERGE & VERIFY

1. Resolve any merge conflicts with main
2. Regenerate lockfile if dependencies changed: `pnpm install --no-frozen-lockfile`
3. Fix migration numbering if collisions exist
4. Merge the PR
5. Verify Vercel deployment succeeds
6. Clean up worktrees

## Phase 4: REPORT

```markdown
## Performance Optimization Results

### Optimizations Applied
| # | Area | Change | Expected Impact |
|---|------|--------|-----------------|

### Database Indexes Added
| Table | Columns | Query Pattern |
|-------|---------|---------------|

### Tests Added
| Test | What it verifies |
|------|-----------------|

### Metrics
- Queries parallelized: X
- N+1 patterns fixed: X
- Components lazy-loaded: X
- Caches added: X
- Indexes added: X
- Tests added: X
```

## Common Optimization Patterns

### Parallel Queries
```typescript
// Before (sequential)
const events = await getEvents(id)
const members = await getMembers(id)

// After (parallel)
const [events, members] = await Promise.all([
  getEvents(id),
  getMembers(id),
])
```

### N+1 Elimination
```typescript
// Before (N+1)
for (const list of lists) {
  const count = await getItemCount(list.id)
}

// After (batch)
const allItems = await getItemsForLists(lists.map(l => l.id))
const countsByList = groupBy(allItems, 'list_id')
```

### Lazy Loading
```typescript
import dynamic from 'next/dynamic'
const HeavyComponent = dynamic(() => import('./HeavyComponent'), {
  ssr: false,
  loading: () => <Skeleton />,
})
```
