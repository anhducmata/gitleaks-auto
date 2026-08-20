# gitleaks-auto

Install Gitleaks as a **global Git pre-commit hook** to prevent accidental secret leaks.

The hook runs `gitleaks protect --staged`, which scans your staged changes before
each commit and blocks the commit if a secret is found. It fires for `git commit`
from any client — terminal, VS Code, JetBrains, Copilot, Claude Code, etc. — since
they all invoke the real `git` binary, which is what runs the hook.

## Installation

```bash
brew tap anhducmata/gitleaks-auto
brew install gitleaks-auto
```

To apply the hook to a repo that already exists (created before installing), re-run `git init` inside it — the hook only attaches automatically on `git init`/`git clone`.

## Which ways of committing does this block?

Git hooks run based on the `git commit` porcelain command itself, not on whatever
triggered it — so this blocks a leaked secret regardless of how the commit was made,
as long as it goes through the real `git` binary. Verified to block secrets when
committing via:

- Plain terminal — `git commit`
- IDE git integrations — VS Code, JetBrains, etc. (they shell out to `git`)
- AI coding assistants — GitHub Copilot, Claude Code, and similar tools that run
  `git commit` on your behalf

What it does **not** block: commits made with `git commit --no-verify` (explicitly
skips hooks), and any commit made on a machine where this hook was never installed
(see Limitations below).

## Limitations

This is a **local, client-side** hook, so it has the same limits as any git hook:

- **Not retroactive** — repos created before running the installer need `git init` re-run inside them to pick up the hook.
- **Bypassable with `--no-verify`** — `git commit --no-verify` skips all hooks, including this one.
- **Machine-local only** — it protects commits made on machines where it's installed. It doesn't protect commits pushed from a machine that never ran the installer, and it isn't a server-side control.

For defense in depth, pair this with a server-side backstop such as GitHub secret scanning / push protection, or a CI job that re-runs `gitleaks detect` on every push or pull request.
