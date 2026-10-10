---
name: observe-chat-search-observability
description: Instrument a chat agent tracking P95 latency, token costs, and search_web tool failures
tags: [observe]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

I built a chat agent that calls search_web for real-time data and then summarizes using Claude. It's handling 100 queries/day in production. I need to track P95 latency, token costs, and tool failures for search_web. How do I add observability?
