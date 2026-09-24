# Contributing to mirc-public

**Repo label: PROD** — `main` = PROD, release-only (human merge only).
**Owner seat:** Rig (Stream Tools). **Fallback:** Muse on Grok Bot credit exhaustion.
**Tracking:** Private `mirc` issues and the Stream board https://trello.com/b/SgrUOXfX (Bug, Working, In Production, DONE, Maybe Later); public issues are disabled.

This repo is **read, download, and fork only** for the public. Public Issues and pull requests are disabled. All tracking for `mirc-public` lives in issues on the private `mirc` repo.

Pull requests here come only from the tag-publish automation (a `v*` tag on private `mirc`, then the `release/<tag>` PR) or from the owner. Humans (Dread) merge.

## Process (required for every change, no exceptions)
1. Open an issue in the private `mirc` repo first: problem, evidence, acceptance criteria.
2. Branch `cursor/<issue#>-<slug>` (or use the automation `release/<tag>` branch). Never commit directly to `main`.
3. One scoped PR per change. Body: link the private `mirc` issue, what, why, evidence (run links/logs/file:line), test plan + results, risk/rollback.
4. CI green. Never skip hooks or checks; no force-push to shared branches.
5. Review by someone other than the author (grader ≠ doer); resolve all threads.
6. Merge: PROD → human (Dread) merge only.
7. After merge: confirm the private `mirc` issue is updated and post-merge CI/deploy passed; update the tracking card with PR link + evidence.

## Releases
Content arrives only from a named version tag on the private `mirc` repo via the sync process (`sync_public.py`). No direct feature PRs to this repo. Humans merge.

## Repo notes
Synced from the private mirc repo via `sync_public.py`; see Sync risk in #1. Visibility: public.

Images committed to this repo must be inside a password-protected archive.
