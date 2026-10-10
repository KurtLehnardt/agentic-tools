---
name: contract-caching-strategy
description: Contract for GraphQL API caching with measurable thresholds
tags: [contract]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

/contract — define the contract for a caching strategy in our GraphQL API. Clients currently wait 3-5 seconds for product catalog queries. We need sub-1-second response time for 95th percentile at peak load (500 req/s). Cache coherency matters: stale data older than 30 minutes is acceptable, but any stale data must be marked with a 'stale' flag in the response. Success means 90%+ cache hit rate on repeat queries. Include the complete CONTRACT-*.md file in your reply.
