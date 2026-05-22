# Contributing to Krīḍā · Strava

> Sub-app of the **Krīḍā** platform. This file covers Strava-sub-app-specific contribution flow. Platform-wide conventions (commit format, git identity, license, naming, branch protection) live in the umbrella [`kreedah/CONTRIBUTING.md`](https://github.com/<owner>/kreedah/blob/main/CONTRIBUTING.md). Read the umbrella file first if you haven't already — it covers the parts of the workflow shared across all Krīḍā sub-apps.

## Before you touch code

Read these in order:

1. [`../kreedah/skills/SKILL-core.md`](https://github.com/<owner>/kreedah/blob/main/skills/SKILL-core.md) — platform principles, commit format, license.
2. [`skills/SKILL-core.md`](./skills/SKILL-core.md) — the 17 Strava-sub-app principles, 3-phase roadmap, Strava API agreement summary.
3. [`skills/SKILL-state.md`](./skills/SKILL-state.md) — current sub-app state, planned modules, pre-seeded pitfalls.

The 17 principles in core are non-negotiable defaults. If you think one needs to change, propose it explicitly in a PR with reasoning — don't quietly work around it.

## Setup

### Prerequisites

- Node 20+
- pnpm 9+
- Docker Desktop (for local Postgres)
- `gh` CLI (optional, only for repo management)
- `cloudflared` or `ngrok` (for testing Strava webhooks locally)
- `wrangler` CLI (Phase 0b+, for Cloudflare Workers deploy)
- A registered Strava API application — create at <https://www.strava.com/settings/api>

### Clone and configure

```bash
git clone https://github.com/<owner>/kreedah-strava
cd kreedah-strava

# Per-repo git identity (no --global):
git config user.name  "Your Name"
git config user.email "you@example.com"
```

### TypeScript app

```bash
pnpm install
docker compose up -d postgres
cp .env.example .env.local        # then edit with your Strava client ID + secret
pnpm db:migrate                   # apply Drizzle migrations
pnpm dev                          # localhost:3000
```

### Webhook tunneling (when working on webhook handler)

Strava webhooks need a public HTTPS endpoint. For local dev:

```bash
cloudflared tunnel --url http://localhost:3000
# or
ngrok http 3000
```

Update your Strava API app's callback URL to the resulting public URL.

### Python sidecar (Phase 3+, when it exists)

The sidecar will live at `sidecar/` (not yet created). Setup will be:

```bash
cd sidecar
conda env create -f environment.yml
conda activate krida-strava-sidecar
uv pip sync requirements.lock
```

See umbrella `CONTRIBUTING.md` "Working on Python code" for the full pattern.

## Daily workflow

```bash
# Create a branch (use commit major_type as prefix):
git checkout -b feat/challenge-discovery

# Make changes, then commit using the kc helper:
git add .
./scripts/kc.sh feat "added incremental challenge ID discovery loop"

# Update SKILL-state.md if you changed anything load-bearing:
#   - new module       → update Module Inventory
#   - new function     → update Key Function Signatures
#   - new bug/gotcha   → update Pitfalls Log
#   - phase transition → update Phase Status + Changelog

# Push and open PR:
git push -u origin feat/challenge-discovery
gh pr create   # or open in browser
```

## What gets reviewed

- **All 17 principles** in [`skills/SKILL-core.md`](./skills/SKILL-core.md). The most common review comments cluster around:
  - **#9** — `any` slipped in, Zod missing at a boundary
  - **#10** — `useEffect` for data fetching, mixing Server/Client component concerns
  - **#11** — query without `user_id` scoping
  - **#13** — used `TIMESTAMP` instead of `TIMESTAMPTZ`
  - **#15** — call to Strava API not gated through the rate-limit tracker
  - **#16** — Strava attribution missing on a new page
- **Test coverage at boundaries:** Strava API response parsing, OAuth flow, token refresh, challenge progress computation against user-defined rules, timezone math. Trust the framework lightly; test the seams.
- **`SKILL-state.md` updated** to reflect your changes.
- **Commit format via `kc`** — direct `git commit` is rejected.

## Strava-specific gotchas to know

These live in the [`skills/SKILL-state.md`](./skills/SKILL-state.md) pitfalls log. The short version:

1. **Never store Strava tokens in plaintext** — encrypted DB column only.
2. **Never scrape any Strava URL other than `/challenges/{id}`** — see principle 4.
3. **Never poll the Activities API** when a webhook will do — burns shared rate limit.
4. **Every query is `user_id`-scoped** — multi-tenant from day 1.
5. **All timestamps `TIMESTAMPTZ`** — fitness apps die on timezone bugs.
6. **"Powered by Strava" attribution on every data page** — contractually required.
7. **No `useEffect` for data fetching** — Server Components or Server Actions.

Read the full pitfalls log before your first PR.

## When you find a new gotcha

Add it to the pitfalls log in [`skills/SKILL-state.md`](./skills/SKILL-state.md). Use the `[pitfall]` commit type:

```bash
./scripts/kc.sh pitfall "added pitfall #N about <topic>"
```

This is how Strava-specific institutional memory gets preserved across sessions.

## Phase awareness

The sub-app has a three-phase roadmap (`SKILL-core.md` §2). Before adding a feature, check what phase the sub-app is currently in (`SKILL-state.md` §3). Don't add Phase 2 features in Phase 0a — they'll be wrong (e.g., calling the partner API before partner status is granted).

## Questions

- "Where's the Strava partner application process?" → not yet started (Phase 2). See sub-app `SKILL-state.md` for status.
- "How do I test webhooks?" → cloudflared/ngrok section above + the webhook test fixtures (TBD).
- "Why aren't we using [feature X]?" → check `SKILL-core.md` principles for the constraint, and `SKILL-state.md` for any deferred decisions.

## License of contributions

By submitting a PR, you license your contribution under [PolyForm Noncommercial 1.0.0](./LICENSE), matching the platform license. Contributions made under any other license terms will be rejected.
