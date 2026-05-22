# SKILL-core.md — Krīḍā · Strava

> **Stable half of the sub-app skill pair.** Sub-app-specific conventions and principles. Platform-wide concerns (commit format, license, naming pattern, meta-repo architecture) live in the umbrella `kreedah/skills/SKILL-core.md`. Current sub-app state lives in `SKILL-state.md` in this directory. **State wins on conflicts** with either core file.

**Krīḍā · Strava** is the first Krīḍā sub-app: a web dashboard for tracking Strava challenges. Activities are pulled via the Strava REST API v3 (OAuth 2.0 + webhooks). Challenge discovery uses light incremental scraping of public challenge pages (`strava.com/challenges/{id}`), exploiting the fact that Strava challenge IDs are sequentially numbered. Progress is computed locally against user-defined challenge rules. The sub-app will eventually contribute tools to the Krīḍā MCP server in Phase 3.

---

## 1. Relationship to the Platform

This sub-app is part of the Krīḍā platform. Platform-level conventions (commit message format, license, naming patterns, meta-repo architecture, 9 platform-wide principles) are defined in the umbrella `kreedah/skills/SKILL-core.md` and `SKILL-state.md`. This file covers Strava-sub-app-specific concerns only. **Conflicts with umbrella core are resolved in favor of the umbrella** — the platform sets the rules; sub-apps refine within them.

---

## 2. Mission and Three-Phase Roadmap

- **Phase 0a — Local development.** Everything runs on `localhost:3000` with local Postgres in Docker. OAuth callback configured to `localhost`. Webhooks tested via `ngrok` or `cloudflared tunnel`. Strava integration, challenge discovery, progress computation, and dashboard UI must all work end-to-end locally before deployment.
- **Phase 0b — First deployment.** Deploy to Cloudflare Workers + Neon Postgres + Hyperdrive. Drizzle schema migrates cleanly from local to Neon. App becomes accessible at a public URL with valid HTTPS for OAuth callback and webhook reception.
- **Phase 1 — Manual challenge tracker (production).** User defines or imports challenges (sport, target distance/time/elevation, start/end date). Activities pulled via Strava API + webhooks. Progress computed locally against user-defined rules. Challenge discovery via incremental ID loop: increment last-known `challenge_id` by 1, fetch the public page, parse title and status, store in DB, mark whether user has joined. Display active challenges (joined + within date window) and future joined challenges (joined + start date in future).
- **Phase 2 — Strava partner access.** Apply for official partner status to unlock the real Strava Challenges API. Migrate discovery and join-tracking to partner endpoints. Retire scraping.
- **Phase 3 — MCP contribution.** Contribute tools to the Krīḍā MCP server. Architecture (unified vs per-sub-app) per umbrella core §4 principle 7.

---

## 3. The 17 Architectural Principles

These apply to this sub-app only. Platform-wide principles (umbrella core §4) apply on top.

**1. The TypeScript app is the single source of truth.** All challenge and activity data lives in the Next.js + Postgres app. No external systems own state.
**Reason:** Multiple sources of truth diverge silently and cause data-integrity bugs that are nearly impossible to debug. One authoritative store with clearly defined inputs (Strava API, scraping, user actions) makes state predictable.

**2. OAuth secrets are never plaintext.** Strava client secret and user access/refresh tokens are stored encrypted in the database, never logged, never committed to git. Environment variables containing secrets are gitignored and listed in `.env.example` with placeholder values.
**Reason:** Strava revokes API access for apps that leak credentials. A single committed token in git history can compromise the entire app.

**3. Webhooks over polling.** When Strava can push updates (new activity, deauthorization), subscribe via the Webhook Events API. Never poll the Activities API on a schedule when a webhook would suffice.
**Reason:** Strava enforces 100 requests per 15-minute window and 1000 per day per app. Polling burns this budget for no gain and introduces lag. Strava actively encourages webhook adoption in their developer documentation.

**4. Scraping is narrow and throttled.** Only `strava.com/challenges/{id}` may be scraped, no other Strava URL pattern. Rate limit must be verified by the user before implementation. Stop after N consecutive 404s (suggested: 5). All scraped pages are logged with timestamp and outcome.
**Reason:** Strava's API Agreement allows revoking access for uses that "replicate Strava sites, services or products." Narrow, well-documented, throttled scraping for challenge discovery (a feature unavailable in the public API) is defensible; broad scraping is not.

**5. Strava API Agreement compliance.** Consult the Strava API Agreement before adding any feature that resembles existing Strava functionality. Never implement virtual races or competitions. Always handle the deauthorization webhook by deleting the athlete's tokens and data.
**Reason:** Strava revokes API access for non-compliance. Deauthorization handling is explicitly required by the agreement and is checked when applying for partner status or higher athlete capacity.

**6. Postgres-only persistence.** No Redis, no flat files, no JSON files on disk, no other databases. Caches live in Postgres tables. The one exception: raw Strava API response payloads may be stored as `jsonb` columns for replay/debugging, but parsed fields must also be extracted into typed columns.
**Reason:** Single-store architectures are easier to back up, migrate, and reason about. Multi-store systems introduce consistency bugs disproportionate to their performance gains at this scale.

**7. Heavy analytics happen in a Python sidecar, not the main app.** Clustering, ML, and statistical modeling run in separate Python notebooks (conda + uv hybrid environment per umbrella platform principle 10) reading Postgres via a read-only role. Results write back to a dedicated `ml_results` table that the TS dashboard reads. The TypeScript codebase never imports ML libraries or spawns Python subprocesses.
**Reason:** Python's ML ecosystem (scikit-learn, pandas, numpy) is unmatched. Forcing it into the TS app creates a polyglot deployment nightmare. Postgres is the perfect handoff layer because both languages speak it natively.

**8. The MCP server is read-only.** Phase 3 MCP tools let Claude query data, never write to Strava on the user's behalf. No "create activity", no "join challenge", no mutation tools.
**Reason:** Read-only MCP tools are low-risk and high-value. Write tools introduce auth complications (who authorized this write?), audit-trail requirements, and the possibility of Claude making destructive errors the user cannot easily reverse.

**9. TypeScript strict everywhere.** `strict: true` in `tsconfig.json`, no `any`, no implicit `any`. Zod schemas at all external boundaries: Strava API responses, MCP tool inputs, form submissions, scraped page parsing. Drizzle-inferred types everywhere internal.
**Reason:** Strava API responses are the #1 source of runtime surprises in this app. Zod validation at the boundary turns runtime crashes into typed error paths. Internal Drizzle types eliminate the "stale type" bug class.

**10. Next.js App Router conventions.** Server Components by default. Client Components only when interactivity demands them. No `useEffect` for data fetching. Mutations via Server Actions.
**Reason:** `useEffect` data fetching causes waterfalls, no SSR, no streaming. App Router was designed to make it unnecessary. Refetching on user action uses `router.refresh()` or Server Actions, not `useEffect`.

**11. Multi-tenancy from day 1, single user as default.** Every domain table has a `user_id` foreign key. Every query and mutation is user-scoped via middleware. The current "single-user mode" is `DEFAULT_USER_ID` set at runtime — there is no single-user code path.
**Reason:** Retrofitting multi-tenancy is one of the most painful refactors in web apps. Baking it in costs ~15% upfront and prevents an entire class of bugs (cross-tenant data leaks) forever. Open-source release becomes trivial.

**12. Deployment is replaceable, not load-bearing.** The app must be deployable to any Node + Postgres environment. Never adopt Workers-only APIs without a documented fallback. A working `Dockerfile` and `docker-compose.yml` must be maintained in the repo at all times.
**Reason:** Platform lock-in is seductive (free tiers, easy deploys) but kills open-source distribution. Portability is far cheaper to maintain than to retrofit.

**13. Timezones: store UTC, display local.** All database timestamps are `TIMESTAMPTZ` (UTC). Strava API responses provide both `start_date` (UTC) and `start_date_local` — store both; query in UTC, display in local. Challenge windows are interpreted in the athlete's timezone, not the server's.
**Reason:** Fitness apps live and die on timezone bugs. A run logged at 11:55 PM local time can get miscounted toward the wrong day, breaking streaks and challenge progress. Strava's dual-field design is a hint, not a suggestion.

**14. Error handling: typed Results at external boundaries, throw at internal edges.** External API calls (Strava, scraping) return typed `Result<T, E>` objects via `neverthrow`. Internal business logic throws; route handlers catch and translate to HTTP responses via a single error-handling middleware.
**Reason:** Strava API can fail in predictable ways (rate limit, token expired, athlete deauthorized, network) — these must be handled as data, not crashes. Internal bugs should crash loudly so they're noticed and fixed. Mixing both styles inconsistently is the worst of both worlds.

**15. Rate limit budget is shared and tracked.** Strava enforces 100 reqs/15min and 1000/day per app. The app maintains a real-time counter in Postgres (`api_rate_limits` table) and refuses requests that would exceed 80% of either window. Exponential backoff with retry on 429 responses.
**Reason:** Multi-tenant apps with many users will silently hit rate limits and break for everyone. A shared budget tracker is cheap insurance and avoids the worst failure mode (one user's bulk-sync request rate-limits everyone else).

**16. Strava attribution is not optional, not deferred.** Every page displaying Strava data must show "Powered by Strava" with the official Strava orange logo per brand guidelines. Activity displays must link back to the original activity on strava.com.
**Reason:** Strava brand guidelines are contractually enforced. Apps that omit attribution have had API access revoked. Adding it later as an afterthought is how attribution gets forgotten on new pages.

**17. Localhost-first development.** All features must run end-to-end on `localhost` with local Postgres (Docker) before any code is deployed. Deployment-specific code paths (Workers runtime quirks, Hyperdrive connection strings) are gated behind environment detection, never the default.
**Reason:** Strava integration has many moving parts (OAuth, webhooks, rate limits, token refresh). Verifying these on localhost — where you control everything, read logs freely, and iterate in seconds — surfaces bugs that would be painful to debug in production. Deployment becomes a packaging step, not a debugging environment.

---

## 4. Naming Conventions (Strava-Specific)

Platform naming conventions (umbrella core §8) apply. Strava-specific additions:

- npm package name: `kreedah-strava` (in `package.json`)
- DB name: `kreedah_strava` (local) / `kreedah_strava_prod` (Neon)
- Display name: "Krīḍā · Strava"
- Strava-specific tables prefixed: `strava_tokens`, `strava_activities`, `strava_webhooks`
- Cross-cutting tables unprefixed: `users`, `challenges`, `challenge_memberships`

---

## 5. Required Dev Tooling

- Node 20+, pnpm 9+
- Docker Desktop (for local Postgres via `docker compose up postgres`)
- `gh` CLI (for repo management, set up via platform `setup-repos.sh`)
- `cloudflared` or `ngrok` (for exposing localhost to Strava for webhook testing)
- `wrangler` CLI (Cloudflare Workers deployment, Phase 0b+)
- A registered Strava API application — create at https://www.strava.com/settings/api

---

## 6. Strava API Agreement: Do's and Don'ts

The Strava API Agreement is the contract; this is a summary, not a substitute. Read the full agreement before implementing any feature that resembles existing Strava functionality.

- **Always** handle the deauthorization webhook by deleting the athlete's tokens and data.
- **Always** show "Powered by Strava" attribution with the official orange logo on every page displaying Strava data.
- **Never** implement virtual races or competitions using Strava data.
- **Never** replicate the look and feel of strava.com.
- **Always** throttle scraping per principle 4; never broaden scraping beyond `strava.com/challenges/{id}`.

---

## 7. Testing Philosophy

- **Vitest** for unit tests, **Playwright** for E2E (Phase 1+).
- All tests headless and CI-runnable. No tests that require a browser GUI or external display.
- Test the boundaries heavily: Strava API response parsing, challenge page scraping, OAuth flow, token refresh, progress computation against user-defined rules, timezone-sensitive date math. Trust the framework (Next.js, Drizzle, Zod) lightly.
- No coverage minimum at Phase 0; revisit at Phase 2 when application complexity warrants it.
- Mock the Strava API at the HTTP boundary, not at the client layer — fixtures should be real recorded responses to catch shape drift.

---

## 8. Pointer to SKILL-state.md and Umbrella

- **`SKILL-state.md`** (this directory) is authoritative for current Strava-sub-app reality: code state, module status, schema, pitfalls discovered, last update.
- **`kreedah/skills/SKILL-core.md`** and **`kreedah/skills/SKILL-state.md`** (umbrella) are authoritative for platform-level concerns. When in doubt about a platform-wide convention, check the umbrella.

---

*This file is stable. Update only when sub-app-level conventions, principles, or roadmap change. For current code state, see `SKILL-state.md` in this directory.*
