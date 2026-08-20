# gitleaks-auto

Wires [Gitleaks](https://github.com/gitleaks/gitleaks) into a git pre-commit hook,
so a commit containing a secret gets blocked before it's made. Fires for any
client that runs `git commit` — terminal, IDE, Copilot, Claude Code — since they
all go through the real `git` binary.

## Install

**Global** — protects every repo on your machine:

```bash
brew tap anhducmata/gitleaks-auto
brew trust anhducmata/gitleaks-auto
brew install gitleaks-auto
```

Existing repos need `git init` re-run once to pick up the hook.

**Per-repo** (recommended for teams) — hook is committed to the repo:

```bash
curl -fsSL https://raw.githubusercontent.com/anhducmata/gitleaks-auto/main/install-repo.sh | bash
```

Commit the resulting `.githooks/` folder. Each teammate runs
`git config core.hooksPath .githooks` once after cloning.

**CI backstop** — catches anything that skips local hooks. Copy
[`templates/gitleaks-ci.yml`](templates/gitleaks-ci.yml) to
`.github/workflows/gitleaks.yml`.

## Coverage

| Scenario | Blocked? |
|---|---|
| Terminal / IDE / AI assistant running `git commit` | ✅ |
| `git commit --no-verify` | ❌ (bypasses all git hooks) |
| Commit via GitHub API / MCP write, no local `git` involved | ❌ (use CI backstop) |
| Machine/repo without the hook installed | ❌ (use CI backstop) |

Local hooks are machine- or repo-scoped and always skippable with `--no-verify` —
that's a property of git hooks, not this tool. Pair with the CI backstop for a
check nothing can bypass.

## Why not just use Gitleaks directly?

Gitleaks itself doesn't wire itself into git — you'd manually create the hook,
set `init.templateDir` for global coverage, or write your own `.githooks` +
`core.hooksPath` setup. This repo packages that setup into one command, at
whichever scope you need (machine, repo, or CI). It adds no detection logic —
just the wiring Gitleaks leaves as a manual step.

## Credits

All detection is [Gitleaks](https://github.com/gitleaks/gitleaks) (MIT). This repo
only installs it and wires the hook — no detection logic of its own.
