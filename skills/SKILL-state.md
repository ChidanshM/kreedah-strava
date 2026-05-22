---
type: skill-state
project: kreedah-strava
scope: sub-app
authoritative: true
last_edited: 260522_0021
---

# SKILL-state.md — Krīḍā · Strava · Living State

> **Living half of the sub-app skill pair.** Current state of `kreedah-strava` only. Platform-level state lives in `kreedah/skills/SKILL-state.md`. **This file wins on conflicts** with `SKILL-core.md` in this directory.
>
> **How updates work:** Claude cannot edit project files directly. At the end of any session that changes the codebase — new module, new function, resolved bug, completed phase, new pitfall — Claude flags which sections need updating. The user applies them to this file.
>
> **Staleness rule:** Do not let this file drift more than one session behind.

---

## 1. Changelog

| Date | Tag | Description |
|---|---|---|
| 2026-05-21 | [phase] | Phase 0 — sub-app scaffolded as part of Krīḍā platform initialization. Skill pair created. No code yet. |

---

## 2. Codebase Snapshot

**Phase:** 0a (local development setup)
**Files:** 0 application files
**Lines:** 0
**Tests:** 0

**Stack** (planned, not yet installed):
- Next.js 14+ (App Router)
- TypeScript (strict)
- Drizzle ORM + drizzle-kit
- PostgreSQL — local: Docker; production (Phase 0b): Neon
- Tailwind CSS
- Zod (boundary validation)
- neverthrow (Result types for external calls)
- Vitest (unit tests)
- Playwright (E2E, Phase 1+)
- Cloudflare Workers runtime (Phase 0b+)

---

## 3. Phase Status

**Active phase:** 0a — local development setup.

**Blocking next phase (0b):** project scaffolding not yet started. Sequence: scaffold Next.js project → set up Drizzle + local Docker Postgres → register Strava API app → implement OAuth flow → implement webhook handler with `cloudflared`/`ngrok` → implement first challenge discovery + manual challenge creation → verify end-to-end on localhost → only then proceed to Phase 0b deployment.

---

## 4. Architecture State

### What is fully implemented
Nothing yet. Phase 0a is just-scaffolded.

### What is not yet implemented
- Next.js project scaffold
- TypeScript + Drizzle + Tailwind configuration
- Docker Compose for local Postgres
- Initial DB schema and migrations
- Strava OAuth 2.0 flow (authorize, callback, token exchange, refresh)
- Strava webhook subscription + signature verification + event handler
- Rate limit tracker (`api_rate_limits` table + middleware)
- Challenge discovery (incremental ID loop, public page parser)
- Challenge progress computation (activity rollup against user-defined challenge rules)
- Dashboard UI (active challenges, future challenges, activity feed)
- "Powered by Strava" attribution component + brand assets
- Deauthorization handler (token + data deletion on athlete deauth)
- Multi-tenancy middleware (every query user-scoped)
- Error handling middleware (Result → HTTP translation)
- Dockerfile + docker-compose.yml for portable deployment

### Active architectural gaps
N/A at Phase 0. This section will populate as the codebase grows. Likely first entries: "no logging strategy", "no observability for webhook deliveries", "no shared error taxonomy".

---

## 5. Planned Dependencies (Not Yet Installed)

- `next`, `react`, `react-dom` — framework
- `typescript`, `@types/node`, `@types/react` — typing
- `drizzle-orm`, `drizzle-kit` — ORM + migrations
- `@neondatabase/serverless` — Neon driver (Phase 0b)
- `pg` — local Postgres driver (Phase 0a)
- `zod` — boundary validation
- `neverthrow` — Result types
- `tailwindcss`, `postcss`, `autoprefixer` — styling
- `vitest`, `@vitest/ui` — unit tests
- `@playwright/test` — E2E (Phase 1+)
- `wrangler` — Cloudflare Workers CLI (Phase 0b)
- `lucide-react` — icons
- `date-fns` and `date-fns-tz` — timezone-aware date math
- `cheerio` or similar — HTML parsing for challenge discovery scraping

---

## 6. Module Inventory

### Backend / lib

| Module | Status | Key functions |
|---|---|---|
| `lib/db/index.ts` | ⬜ Planned | DB connection (env-aware: local pg vs Neon serverless) |
| `lib/strava/client.ts` | ⬜ Planned | Authenticated Strava API client with rate-limit awareness |
| `lib/strava/oauth.ts` | ⬜ Planned | Authorization URL builder, code-for-token exchange, refresh |
| `lib/strava/webhooks.ts` | ⬜ Planned | Subscription mgmt, signature verification, event dispatch |
| `lib/strava/rate-limit.ts` | ⬜ Planned | Budget tracker, request gating, backoff |
| `lib/strava/deauth.ts` | ⬜ Planned | Handle deauthorization event (delete tokens + data) |
| `lib/challenges/discovery.ts` | ⬜ Planned | Incremental ID loop + page parser |
| `lib/challenges/progress.ts` | ⬜ Planned | Compute progress from activities against challenge rules |
| `lib/auth/middleware.ts` | ⬜ Planned | User-scoping middleware for all queries |
| `lib/errors/middleware.ts` | ⬜ Planned | Result → HTTP translation |

### Frontend / app + components

| Module | Status | Key role |
|---|---|---|
| `app/(dashboard)/page.tsx` | ⬜ Planned | Home dashboard |
| `app/(dashboard)/challenges/active/page.tsx` | ⬜ Planned | Active challenges view |
| `app/(dashboard)/challenges/upcoming/page.tsx` | ⬜ Planned | Future joined challenges view |
| `app/api/auth/strava/callback/route.ts` | ⬜ Planned | OAuth callback handler |
| `app/api/webhooks/strava/route.ts` | ⬜ Planned | Strava webhook event handler |
| `components/ChallengeCard.tsx` | ⬜ Planned | Display a single challenge with progress |
| `components/ProgressBar.tsx` | ⬜ Planned | Visual progress indicator |
| `components/StravaAttribution.tsx` | ⬜ Planned | "Powered by Strava" component (required on every data page) |

### Database

| Module | Status | Role |
|---|---|---|
| `db/schema.ts` | ⬜ Planned | Drizzle schema definitions |
| `db/migrations/` | ⬜ Planned | drizzle-kit migration files |

### Strava integration

Strava integration modules are cross-referenced in the Backend / lib table above (`lib/strava/*`). No separate folder; consolidated under `lib/strava/`.

---

## 7. Key Function Signatures

```typescript
// Will be populated as modules are implemented.
```

---

## 8. Database Schema Summary

```
// No schema yet. First migration will establish:
//   users
//   strava_tokens
//   challenges
//   challenge_memberships
//   strava_activities
//   api_rate_limits
//   ml_results
```

Detailed schema (columns, indexes, foreign keys, jsonb fields) will be filled in once `db/schema.ts` is written.

---

## 9. Strava API Patterns

### Rate limit handling

Will be populated as implementation progresses. Key facts to remember:
- 100 requests per 15-minute window per app
- 1000 requests per day per app
- Budget tracked in `api_rate_limits` table
- Refuse requests above 80% of either window per principle 15

### Webhook signature verification

Will be populated as implementation progresses. Strava uses HMAC-SHA256 with a shared signing secret; verification happens before any handler logic runs.

### OAuth token refresh flow

Will be populated as implementation progresses. Strava access tokens expire every 6 hours; refresh tokens are long-lived but must be rotated on use.

### Common response shape gotchas

Will be populated as implementation progresses. Known traps to document later:
- `start_date` (UTC) vs `start_date_local` (athlete local) — store both, per principle 13
- Activities may have `null` distances, durations, or athlete fields — Zod schemas must allow null
- Webhook `aspect_type` is `"create" | "update" | "delete"` — handle all three

---

## 10. Pitfalls Log

| # | Never | Cause / fix |
|---|---|---|
| 1 | Store Strava tokens or client secret in plaintext anywhere outside the encrypted DB column. | Strava revokes API access for credential leaks; git history is forever. Per principle 2. |
| 2 | Scrape any Strava URL other than `strava.com/challenges/{id}`. | The API Agreement allows revocation for site replication; narrow scraping is the only defensible scope. Per principle 4. |
| 3 | Poll the Activities API when a webhook subscription would do the job. | Burns rate limit (1000/day shared across all users) and introduces lag. Per principle 3. |
| 4 | Write a query that omits `user_id` scoping. | Multi-tenant from day 1; an unscoped query is a cross-tenant data leak waiting to happen. Per principle 11. |
| 5 | Use `TIMESTAMP` (without timezone) for any column storing time. | Fitness apps die on timezone bugs. Always `TIMESTAMPTZ`. Per principle 13. |
| 6 | Display Strava activity data without "Powered by Strava" attribution and a link back to the activity. | Contractual brand requirement; non-compliance has led to revoked API access. Per principle 16. |
| 7 | Use `useEffect` for data fetching in Client Components. | Causes waterfalls, no SSR, no streaming; App Router was designed to make this unnecessary. Per principle 10. |

---

## 11. Real Data Patterns

This section will accumulate Strava API quirks discovered during development (response shape inconsistencies, edge cases, undocumented fields). Empty at Phase 0; populate as you encounter them.

---

*Last updated: 2026-05-21. Update the changelog above whenever this file changes.*
