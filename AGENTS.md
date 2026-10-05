# AGENTS.md

Short outline for agents. Process detail lives in CONTRIBUTING.md; this file does not repeat it.

## What this repo is for

The public, release-only copy of Dread's mIRC scripts. Content arrives only from a named version tag on the private `mirc` repo, through a `release/<tag>` PR. PROD: Dread merges.

## What is allowed in this repo

- `release/<tag>` PRs opened by the publish workflow.
- Issues and outside PRs as reports; accepted changes are re-landed in private `mirc`.
- Upkeep of `CONTRIBUTING.md`, `README.md`, `AGENTS.md` and `.github/`.

## What is NOT allowed

- Direct content or feature merges here.
- Secrets, tokens or private config.
- Code comments in added lines.
- Images outside a password-protected archive.
- Pushing to `main`, force-pushing, or any bot merging a PR.

## Pointers

- Process and releases: [CONTRIBUTING.md](CONTRIBUTING.md)
- Environment and usage: [README.md](README.md)
- CI checks: `.github/workflows/release-on-merge.yml`
