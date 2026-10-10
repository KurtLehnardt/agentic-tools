---
type: llm
weight: 1
---

PASS if:
- Identifies that filteredAndSorted is recomputed on every render unnecessarily
- Proposes wrapping filteredAndSorted in useMemo with dependencies [tasks, filter, sortBy]
- Identifies that toggleTask callback is recreated on every render, breaking child memoization
- Proposes using useCallback to memoize toggleTask with appropriate dependencies
- Shows code with useMemo(() => { ... }, [tasks, filter, sortBy])
- Shows code with useCallback(() => { ... }, [...dependencies])
- Explains that memoization prevents child component re-renders when callbacks don't change
- Recognizes that this reduces re-renders and improves UI performance

FAIL if:
- Does not identify the filtering/sorting as expensive computation
- Does not mention useMemo or useCallback
- Uses useMemo but with wrong dependencies or missing dependencies
- Wraps the entire component in React.memo without fixing the actual expensive computation
- Suggests caching at a different layer (server, global state) instead of component-level memoization
- Does not address the callback recreation issue
