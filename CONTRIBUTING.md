# Contributing to mirc-public

**Repo label: PROD** — `main` = PROD, release-only (human merge only).
**Owner seat:** Rig (Stream Tools). **Fallback:** Muse on Grok Bot credit exhaustion.
**Tracking:** Stream board https://trello.com/b/SgrUOXfX (Bug, Working, In Production, DONE, Maybe Later).

## Process (required for every change, no exceptions)
1. Open a GitHub issue first: problem, evidence, acceptance criteria.
2. Branch `cursor/<issue#>-<slug>`. Never commit directly to `main`.
3. One scoped PR per issue. Body: `Closes #<issue>`, what, why, evidence (run links/logs/file:line), test plan + results, risk/rollback.
4. CI green. Never skip hooks or checks; no force-push to shared branches.
5. Review by someone other than the author (grader ≠ doer); resolve all threads.
6. Merge: TEST → the owner merges when steps 1–5 are done. PROD → human merge only.
7. After merge: confirm the issue closed and post-merge CI/deploy passed; update the tracking card with PR link + evidence.

## Releases
Content arrives only from a named version tag on the private `mirc` repo via the sync process (`sync_public.py`). No direct feature PRs to this repo. Humans merge.

## Repo notes
Synced from the private mirc repo via `sync_public.py`; see Sync risk. Visibility: public.

Images committed to this repo must be inside a password-protected archive.
