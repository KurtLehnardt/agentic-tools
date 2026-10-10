---
name: sandbox-violation-telemetry
description: Enable real-time violation logging and feed to /observe for anomaly detection
tags: [sandbox]
allowed_tools: [Read, Glob, Grep, Skill]
max_turns: 10
---

I'm running an untrusted agent and want real-time visibility into what it tries to do that's blocked — denied writes, denied egress, anything that looks like an exfil attempt. How do I set up telemetry and feed it to /observe for anomaly detection?
