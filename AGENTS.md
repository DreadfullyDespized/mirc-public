# AGENTS.md

Short outline for agents. Process detail lives in CONTRIBUTING.md.

## What this repo is for

The public, release-only copy of Dread's mIRC scripts. Content arrives only from a named version tag on the private `mirc` repo, through a `release/<tag>` PR. This is a PROD repo: Dread merges.

## What is allowed in this repo

- `release/<tag>` PRs opened by the publish workflow.
- Issues and outside PRs as reports; accepted changes are re-landed in private `mirc`.
- Upkeep of `CONTRIBUTING.md`, `README.md`, `AGENTS.md` and `.github/`.

## What is NOT allowed

- Direct content or feature merges here.
- Passwords or secrets in git (cleartext or otherwise documented in-repo); use env vars or a secret store.
- Code comments in added lines.
- Images outside a password-protected archive.
- Pushing to `main`, force-pushing, or any bot merging a PR.

## Prove a change

No Python check harness on `main`. For a docs-only change (this PR): confirm `AGENTS.md` still has every Required H2 (What this repo is for, What is allowed in this repo, What is NOT allowed, Prove a change, Pointers) and that CONTRIBUTING.md still describes release-only flow. Release PRs are proven by `release-on-merge.yml` on merge of `release/<tag>`.

## Grader and merge

Grader starts at FAIL. The person who wrote the change does not grade it. PROD = Dread merges only.

## Correction loop

No correction-loop doc yet — follow CONTRIBUTING if present.

## Landmines

- Never commit passwords/secrets → reviewers + CONTRIBUTING (no check harness on main yet)
- Never merge feature content directly here → reviewers + CONTRIBUTING release rules
- Never commit secrets or private config → reviewers + CONTRIBUTING
- Never skip the Required AGENTS.md headings → reviewers (no headings CI yet)
- Never let a bot merge a PR → PROD human-merge only

## Pointers

- Process and releases: [CONTRIBUTING.md](CONTRIBUTING.md)
- Environment and usage: [README.md](README.md)
- CI checks: `.github/workflows/release-on-merge.yml` (headings CI skipped — no Python check harness)
