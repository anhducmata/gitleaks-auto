# gitleaks-auto

Install Gitleaks as a **global Git pre-commit hook** to prevent accidental secret leaks.

The hook runs `gitleaks protect --staged`, which scans your staged changes before
each commit and blocks the commit if a secret is found. It fires for `git commit`
from any client — terminal, VS Code, JetBrains, Copilot, Claude Code, etc. — since
they all invoke the real `git` binary, which is what runs the hook.

## Installation

There are two ways to install the hook, depending on whether you want to protect
just your own machine or an entire team/repo.

### Option A: Global (protects every repo on your machine)

```bash
brew tap anhducmata/gitleaks-auto
brew install gitleaks-auto
```

To apply the hook to a repo that already exists (created before installing), re-run `git init` inside it — the hook only attaches automatically on `git init`/`git clone`.

This is quick for a solo developer, but it lives on your machine only — a
teammate who clones the repo, or CI, gets no protection unless they also
install it themselves.

### Option B: Per-repo (recommended for teams — travels with the repo)

```bash
curl -fsSL https://raw.githubusercontent.com/anhducmata/gitleaks-auto/main/install-repo.sh | bash
```

or clone this repo and run `install-repo.sh` from your project's root. This
installs Gitleaks (if needed) and writes a **tracked** `.githooks/pre-commit`
hook, then points the repo at it via `git config core.hooksPath .githooks`.

Commit the `.githooks/` folder so it ships with the repo. Each teammate still
needs to run `git config core.hooksPath .githooks` once after cloning (git
never auto-enables hooks from a fresh clone, for security reasons), but the
hook script itself is now version-controlled and identical for everyone —
no more "did you remember to install the global hook?" drift between machines.

### Option C: CI backstop (catches anything that slips past local hooks)

Local hooks — global or per-repo — can always be skipped with
`git commit --no-verify`, or simply not be installed on someone's machine.
For a check that can't be bypassed by the committing client, add
[`templates/gitleaks-ci.yml`](templates/gitleaks-ci.yml) to your repo as
`.github/workflows/gitleaks.yml`. It re-scans every push and pull request
server-side, independent of local setup.

## What's actually protected?

Git hooks fire based on the `git commit` porcelain command itself, not on whatever
triggered it — so this blocks a leaked secret regardless of how the commit was
made, as long as it goes through the real `git` binary and a hook is installed
(global or per-repo).

| Scenario | Protected? | Why |
|---|---|---|
| Plain terminal — `git commit` | ✅ Yes | Runs the real `git` binary, hook fires |
| IDE git integrations (VS Code, JetBrains, etc.) | ✅ Yes | They shell out to the real `git` binary |
| AI coding assistants (Claude Code, GitHub Copilot, etc.) running `git commit` normally | ✅ Yes | Same `git commit` path — verified by test, hook can't tell a human from an agent |
| A human or an AI agent deliberately running `git commit --no-verify` | ❌ No | `--no-verify` explicitly skips all git hooks — no client-side hook can stop this |
| A commit made via the GitHub API / a GitHub App / an MCP server that writes commits directly to the remote (bypassing local `git` entirely) | ❌ No | No local `git commit` ever runs, so there's no hook to trigger |
| A machine or CI runner that never installed the hook (global) and a repo without `.githooks` + `core.hooksPath` set (per-repo) | ❌ No | The hook simply doesn't exist there |
| Any of the above bypass cases | ✅ Covered by Option C | A CI backstop ([`templates/gitleaks-ci.yml`](templates/gitleaks-ci.yml)) re-scans server-side, independent of how the commit reached `origin` |

## Limitations

This is a **local, client-side** hook, so it has the same limits as any git hook:

- **Not retroactive** — repos created before running the installer need `git init` re-run inside them to pick up the hook.
- **Bypassable with `--no-verify`** — `git commit --no-verify` skips all hooks, including this one.
- **Machine-local only** — it protects commits made on machines where it's installed. It doesn't protect commits pushed from a machine that never ran the installer, and it isn't a server-side control.

For defense in depth, pair this with a server-side backstop such as GitHub secret scanning / push protection, or a CI job that re-runs `gitleaks detect` on every push or pull request.

## Credits

All secret detection here is done by [Gitleaks](https://github.com/gitleaks/gitleaks)
(MIT licensed) — this repo doesn't implement any detection logic itself. It's an
installer/wrapper that installs Gitleaks and wires it into a git pre-commit hook
(globally or per-repo). All credit for rule design, entropy detection, and the
scanning engine belongs to the Gitleaks project and its contributors.
