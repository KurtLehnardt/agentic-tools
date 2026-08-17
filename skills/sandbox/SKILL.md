---
name: sandbox
description: "Bound an agent's blast radius with a deny-by-default sandbox policy — read allowed, writes whitelisted, egress denied — plus a per-server policy for each MCP server and violation telemetry. Contains a prompt-injected, trojaned, or rug-pulled agent; it does not stop the injection. Trigger: sandbox the agent, lock down permissions, egress policy, sandbox MCP servers, contain the agent, deny by default, blast radius, srt policy."
user-invocable: true
---

# /sandbox — Blast-Radius Containment

You are an **orchestrator** setting the policy for what an agent can touch. The threat model: **prompt injection yields code execution under your UID.** Injection is still unsolved — you cannot reliably stop the agent from being tricked — but **policy determines what a tricked agent can reach.** What an attacker does with execution falls into three classes; the policy targets each:

| Class | What it does | Policy defense |
|-------|-------------|----------------|
| **Egress** | Exfiltrate data / secrets to an attacker endpoint | deny-by-default network, no bypass |
| **Destructive** | Delete, overwrite, corrupt files or infra | write deny-by-default + narrow whitelist |
| **Persistence** | Install a foothold that survives (cron, hook, dotfile, dependency) | write whitelist excludes autostart/config surfaces |

## The Baseline Policy (deny-by-default)

1. **Read** — allowed by default (agents need to see the codebase).
2. **Write** — **denied by default**, with a *specific* whitelist of paths the task legitimately needs. Not a broad `~/` grant. Exclude persistence surfaces (shell rc files, cron, `.claude/` hooks, package manifests) unless the task is explicitly about them.
3. **Egress** — **denied by default, no bypass.** Whitelist only the exact hosts the task requires. Remember: **allowed egress is reachable egress** — every host you permit is a channel an injected agent can exfil through, so keep the list minimal and audit it (Phase 3).

Setting this up is deliberately tedious — that tedium *is* the security. Don't shortcut it with a wildcard.

### The runtime — Anthropic Sandbox Runtime (`srt`)

Verified against `@anthropic-ai/sandbox-runtime` ([repo](https://github.com/anthropic-experimental/sandbox-runtime), [docs](https://docs.claude.com/en/docs/claude-code/sandboxing)). It enforces the policy at the OS level — no container — via `sandbox-exec`/Seatbelt on macOS (stable), `bubblewrap` + seccomp on Linux (stable), WFP on Windows (alpha).

```bash
npm install -g @anthropic-ai/sandbox-runtime
srt npm test                     # run a command inside the sandbox
srt --debug curl https://x.com   # verbose: shows what got denied
srt --settings ./srt.json <cmd>  # explicit policy file (default: ~/.srt-settings.json)
```

Policy lives in `~/.srt-settings.json`. The fields map exactly onto the baseline above:

```json
{
  "filesystem": {
    "denyRead":  ["/Users/me/.ssh", "/Users/me/.aws"],
    "allowRead": [],
    "allowWrite": [".", "src/", "test/", "/tmp"],
    "denyWrite":  [".git/hooks", "package.json"]
  },
  "network": {
    "allowedDomains": ["api.internal.example.com:443"],
    "deniedDomains":  [],
    "deniedDomainReasons": {}
  }
}
```

`deny*` takes precedence over `allow*`. Reads are allowed unless a region is denied; writes and network are deny-by-default (empty allow list = no access).

## Phase 1: DERIVE THE POLICY FROM THE CONTRACT

Read the `CONTRACT-*.md` / task scope. The write-whitelist and egress-allow list should be the *minimum* the acceptance criteria require — nothing "just in case." If a task needs no network, egress stays fully denied.

## Phase 2: SANDBOX EACH MCP SERVER SEPARATELY

Every MCP server process gets **its own policy**. A server that only reads the calendar gets no filesystem write and no arbitrary egress. This way a **trojaned or rug-pulled MCP server is contained independently** — one compromised server can't reach another's data or the wider filesystem. (Relevant when many servers are connected: mail, drive, source control, browser, database.)

Wrap each server's launch command with `srt` in your MCP config so the server process starts already sandboxed:

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "srt",
      "args": ["npx", "-y", "@modelcontextprotocol/server-filesystem", "/safe/root"]
    }
  }
}
```

Give each server a least-privilege policy (per-invocation `customConfig`/`commandId`, or a dedicated settings file via `--settings`) and deny cross-server reach.

## Phase 3: VIOLATION TELEMETRY

Turn on violation logging and watch it during runs — a denied write or denied egress attempt is a signal, often the first sign of an injection:

- `srt --debug <cmd>` surfaces denials verbosely.
- Programmatically, the library exports `SandboxViolationStore` (`import { SandboxManager, SandboxViolationStore } from '@anthropic-ai/sandbox-runtime'`) with `getViolationsForCommand(key)` and `annotateStderrWithSandboxFailures(key, stderr)`. On **macOS** it taps the system sandbox violation log store for real-time alerts.
- **Linux caveat:** kernel-level violation monitoring is listed as future work — inspect with `strace` manually. So telemetry coverage is strong on macOS, thin on Linux today.
- Feed violations to `/observe` as anomaly signals and alert on egress-denied events.

## Honest Limits

- This **does not stop the injection** — it bounds what a successful injection can do.
- **Allowed egress is reachable egress.** Audit the allow-list as an attack surface, not a convenience list.
- Violations are **not uniformly visible** across platforms/tools — treat telemetry as best-effort, not a guarantee.
- Sandboxing is necessary, not sufficient. Pair with `/constitution` (prompt-integrity) and `/observe` (detection).

## Output

Report, concise:

> "Policy: read=allow, write=[3 paths], egress=deny (allow: api.internal only). Per-server: N servers, least-privilege each. Violation telemetry → /observe. Note: bounds blast radius; does not prevent injection."

## Handoff

- **`/constitution`** — defends the prompt itself from the injection this can't stop.
- **`/observe`** — receives violation telemetry as security anomalies.
- **`/verdict`** — a merge gate can require "zero unexplained egress-denied violations during the run."

> Verified Aug 2026 against `@anthropic-ai/sandbox-runtime` (research preview / experimental). The `srt` CLI, `~/.srt-settings.json` fields, MCP wrapping, and `SandboxViolationStore` above are real; still pin the version and re-check the [docs](https://docs.claude.com/en/docs/claude-code/sandboxing), since an experimental tool's flags can shift. Windows support is alpha. Never weaken a policy to make a task pass; fix the whitelist deliberately or escalate.
