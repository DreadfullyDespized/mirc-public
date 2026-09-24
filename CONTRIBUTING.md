# Contributing to mirc-public

**Repo label: PROD** — `main` = PROD, release-only (human merge only).
**Owner seat:** Rig (Stream Tools). **Fallback:** Muse on Grok Bot credit exhaustion.
**Tracking:** Issues here (public) and the Stream board https://trello.com/b/SgrUOXfX (Bug, Working, In Production, DONE, Maybe Later); the canonical change lands in private `mirc`.

Outside issues and PRs are welcome on mirc-public. This repo is **release-only**. Content changes land in the private `mirc` repo and publish through named version tags (the tag-publish automation opens a `release/<tag>` PR here). Outside PRs are not merged directly; accepted changes are re-landed in private `mirc` and arrive in the next tagged release. Humans (Dread) merge.

## Process (required for every change, no exceptions)
1. Open a GitHub issue first (here or in private `mirc`): problem, evidence, acceptance criteria.
2. Branch `cursor/<issue#>-<slug>` (or use the automation `release/<tag>` branch). Never commit directly to `main`.
3. One scoped PR per change. Body: link the tracking issue, what, why, evidence (run links/logs/file:line), test plan + results, risk/rollback.
4. CI green. Never skip hooks or checks; no force-push to shared branches.
5. Review by someone other than the author (grader ≠ doer); resolve all threads.
6. Merge: PROD → human (Dread) merge only. Outside content PRs are not merged here; they are re-landed in private `mirc` and arrive via the next tagged release.
7. After merge: confirm the tracking issue is updated and post-merge CI/deploy passed; update the tracking card with PR link + evidence.

## Releases
Content arrives only from a named version tag on the private `mirc` repo via the sync process (`sync_public.py`). No direct feature merges to this repo. Humans merge.

## Repo notes
Synced from the private mirc repo via `sync_public.py`; see Sync risk in #1. Visibility: public.

Images committed to this repo must be inside a password-protected archive.
