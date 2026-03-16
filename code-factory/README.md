# OpenClaw App Factory — Setup Guide

Automated setup script that converts a spare Windows laptop into a dedicated, security-hardened OpenClaw app factory running Ubuntu.

## What This Is

A single bash script that takes a fresh Ubuntu 24.04 Server installation and configures it as an autonomous app-building machine. OpenClaw runs inside a hardened Docker container, connects to Claude via your Pro Max subscription, and can create accounts and pay for services using Privacy.com virtual cards with fixed monthly budgets.

## Hardware Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| RAM | 8 GB | 16–32 GB |
| Storage | 128 GB SSD | 256 GB+ NVMe |
| CPU | 4 cores | 6+ cores |
| Network | Stable broadband | Wired ethernet |

This setup targets a 2021–2022 Windows laptop with 32 GB RAM being repurposed. No GPU required — all AI inference happens on Anthropic's side via your Claude Pro Max subscription.

## Prerequisites

Before running the script you need:

- **Ubuntu 24.04 LTS Server** freshly installed on the laptop (enable OpenSSH during install)
- **An Anthropic API key** from [console.anthropic.com](https://console.anthropic.com/settings/keys)
- **A Tailscale account** at [tailscale.com](https://tailscale.com) (free tier is fine)
- **A Privacy.com account** at [privacy.com](https://privacy.com) with KYC completed and a funding source linked
- **An SSH key pair** on the machine you'll use to manage the server remotely

## Quick Start

```bash
# 1. From your local machine, copy the script to the Ubuntu laptop
scp openclaw-factory-setup.sh youruser@<laptop-ip>:~/

# 2. SSH into the laptop
ssh youruser@<laptop-ip>

# 3. Make sure your SSH key is set up (critical — the script disables password auth)
#    If you haven't already:
ssh-copy-id youruser@<laptop-ip>

# 4. Run the script
chmod +x openclaw-factory-setup.sh
sudo ./openclaw-factory-setup.sh

# 5. After completion, log out and back in (for docker group), then start OpenClaw
cd ~/openclaw-factory
docker compose up -d
```

The script is interactive — it will pause at steps requiring your input (Tailscale auth, API key entry) and will warn you before making potentially destructive changes.

## What the Script Does

| Step | Action |
|------|--------|
| 1 | System update, base packages (curl, git, tmux, jq, lm-sensors, age) |
| 2 | Disable sleep/suspend/hibernate, ignore lid close for 24/7 operation |
| 3 | Harden SSH (key-only auth, no root login, fail limit of 3) |
| 4 | Configure UFW firewall (deny all inbound except SSH + Tailscale) |
| 5 | Install Tailscale VPN for secure remote access |
| 6 | Install Docker with log limits and no-new-privileges |
| 7 | Deploy OpenClaw in a hardened Docker container (read-only FS, all caps dropped, localhost-only gateway, resource limits) |
| 8 | Configure fail2ban and unattended security upgrades |
| 9 | Create monitoring, backup, and credential rotation scripts with cron jobs |
| 10 | Print summary with IPs, paths, and remaining manual steps |

## Directory Structure After Setup

```
~/openclaw-factory/
├── docker-compose.yml        # Hardened OpenClaw container config
├── .env                      # Secrets (API key, gateway token) — mode 600
├── .gitignore
├── .age-key.txt              # Age encryption key for backups — mode 600
├── config/
├── logs/
│   ├── backup.log
│   ├── health.log
│   └── rotation.log
├── scripts/
│   ├── health-check.sh       # System + container health report
│   ├── backup.sh             # Daily encrypted workspace backup (14-day retention)
│   └── rotate-gateway-token.sh  # Monthly gateway token rotation
└── workspace/
    ├── projects/             # Individual app projects
    ├── ledger/
    │   ├── spend-log.json    # Budget tracking and transaction log
    │   └── accounts.json     # Registry of created accounts
    ├── skills/               # Custom OpenClaw skills
    ├── templates/            # Project scaffolding templates
    ├── backups/              # Encrypted backup archives (.tar.gz.age)
    └── AGENT_RULES.md        # Agent behavior rules and constraints
```

## Budget Enforcement (Privacy.com)

The script scaffolds a budget system with five virtual card categories:

| Card | Monthly Limit | Purpose |
|------|---------------|---------|
| OC-Hosting | $30 | Hosting and deployment (Vercel, Railway, etc.) |
| OC-Domains | $20 | Domain name purchases |
| OC-APIs | $40 | Third-party API subscriptions |
| OC-SaaS | $30 | SaaS tools and services |
| OC-Emergency | $30 | Overflow and one-off purchases |

**Total: $150/month** (separate from your $100/month Claude Pro Max). Adjust the limits in `workspace/ledger/spend-log.json` and on your actual Privacy.com cards to match your comfort level.

You create the actual cards manually at [privacy.com](https://privacy.com) — the script only sets up the tracking ledger. Set each card's monthly spend limit to match the table above, and merchant-lock where possible.

## Remaining Manual Steps After Script Completes

1. **Start OpenClaw** — `cd ~/openclaw-factory && docker compose up -d`
2. **Configure OpenClaw** — Set your model provider (Claude), `allowFrom` whitelist, and `tools.profile` in the OpenClaw config
3. **Create Privacy.com cards** — Five virtual cards matching the budget table above
4. **Set up email aliases** — Catch-all domain, SimpleLogin, or Gmail plus-addressing for agent account creation
5. **Connect a messaging channel** — WhatsApp, Telegram, Discord, or Slack for remote interaction
6. **Review agent rules** — Customize `workspace/AGENT_RULES.md` to match your workflow preferences

## Included Utility Scripts

### `scripts/health-check.sh`

Prints system uptime, memory, disk, CPU temps, Docker container status, and Tailscale connectivity. Runs automatically every 6 hours via cron and logs to `logs/health.log`.

```bash
./scripts/health-check.sh
```

### `scripts/backup.sh`

Backs up the workspace ledger, skills, templates, agent rules, and secrets to an age-encrypted timestamped tarball. Retains 14 days. Runs daily at 3 AM via cron. To decrypt a backup: `age -d -i ~/openclaw-factory/.age-key.txt backup-file.tar.gz.age > backup.tar.gz`

```bash
./scripts/backup.sh
```

### `scripts/rotate-gateway-token.sh`

Generates a new random gateway auth token, updates `.env`, and restarts the container. Runs automatically on the 1st of each month at 4 AM via cron.

```bash
sudo ./scripts/rotate-gateway-token.sh
```

## Security Model

This setup implements defense in depth:

- **Network layer** — UFW denies all inbound except SSH and Tailscale. The OpenClaw gateway port (18789) is bound to localhost only and is never exposed to the internet. Remote access is exclusively through Tailscale VPN.
- **Host layer** — SSH is key-only with no root login. Fail2ban blocks brute-force attempts. Unattended-upgrades patches security vulnerabilities automatically.
- **Container layer** — OpenClaw runs as a non-root user in a read-only container with all Linux capabilities dropped, no-new-privileges set, and resource limits enforced. User namespace remapping was intentionally omitted to avoid permission conflicts with bind-mounted workspace volumes; security is enforced via the user directive, capability dropping, and read-only filesystem instead.
- **Application layer** — Gateway requires a 256-bit auth token. Messaging channels are restricted via allowFrom whitelists. Tool access follows least-privilege via tools.profile. Sandbox mode is enabled for command execution.
- **Financial layer** — Privacy.com virtual cards enforce hard monthly spend limits per category. Cards auto-decline transactions over budget. No real bank credentials are ever given to the agent.
- **Credential layer** — All secrets live in a single `.env` file with 600 permissions. Gateway tokens are rotated monthly via automated cron job. Backups are encrypted with age. The agent is prohibited from storing credentials in chat logs or session transcripts.

## Known Risks

- **OpenClaw is young software.** A serious WebSocket hijacking CVE was disclosed in January 2026 (CVE-2026-25253). Keep it updated and never expose the gateway to the internet.
- **ClawHub skills are community-uploaded code.** Malicious skills have been documented. Only install skills you have personally reviewed.
- **Prompt injection is a real threat.** Any untrusted content the agent reads (web pages, emails, fetched URLs) could contain injection attempts. Use frontier models (Claude Sonnet 4 / Opus 4) which are more robust, and treat all external content as untrusted in your skill prompts.
- **Laptops are not servers.** Monitor thermals, keep the lid open or on a cooling pad, and check CPU temps regularly. The health check script automates this.
- **Docker image is pulled without digest pinning.** The compose file uses `openclaw/openclaw:latest` which trusts Docker Hub. For higher assurance, pin to a specific digest after verifying: `docker pull openclaw/openclaw:latest && docker inspect --format='{{index .RepoDigests 0}}' openclaw/openclaw:latest` and replace the image tag in `docker-compose.yml` with the digest.

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Locked out of SSH | Boot with a monitor + keyboard, fix `/etc/ssh/sshd_config`, restart sshd |
| Container won't start | Check `docker compose logs`, verify `.env` exists and has correct permissions |
| Gateway unreachable | Confirm it's bound to 127.0.0.1, check `docker compose ps`, verify Tailscale is connected |
| High CPU temps | Elevate laptop, add cooling pad, check `sensors`, consider undervolting |
| Budget exceeded | Pause the relevant Privacy.com card immediately, review `spend-log.json` |
| Unexpected charges | Pause all cards, stop the container (`docker compose down`), audit session logs |
| Docker permission denied | Log out and back in after setup (docker group takes effect on new session) |
| Script failed mid-run | The script is idempotent — re-run it safely. If SSH is locked out, connect a monitor and keyboard, restore `/etc/ssh/sshd_config` from the `.bak.*` backup, and restart sshd |

## License

This project is licensed under the GNU General Public License v3.0. See [LICENSE](LICENSE) for details.
