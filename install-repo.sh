#!/bin/bash
set -e

echo "🚀 [gitleaks-auto] Setting up repo-local Git hook..."

if [ ! -d ".git" ]; then
  echo "❌ Not a git repository root. Run this from the repo's top-level directory."
  exit 1
fi

if ! command -v gitleaks >/dev/null 2>&1; then
  echo "📦 Gitleaks not found. Installing via Homebrew..."
  if command -v brew >/dev/null 2>&1; then
    brew install gitleaks || {
      echo "❌ Failed to install gitleaks"
      exit 1
    }
  else
    echo "❌ Homebrew not found. Cannot install gitleaks automatically."
    exit 1
  fi
else
  echo "✅ Gitleaks already installed."
fi

mkdir -p .githooks
cat << 'EOF' > .githooks/pre-commit
#!/bin/bash
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
BOLD='\033[1m'
RESET='\033[0m'

echo -e "${BOLD}🔍 Running Gitleaks scan...${RESET}"
gitleaks protect --staged --source . --verbose --redact

if [ $? -ne 0 ]; then
    echo -e "${BOLD}${RED}🔴 CRITICAL: secrets detected — commit blocked.${RESET}"
    echo -e "${YELLOW}   Remove or rotate the secret, then re-stage and commit again.${RESET}"
    exit 1
fi

echo -e "${BOLD}${GREEN}🟢 PASSED: no secrets found — proceeding with commit.${RESET}"
exit 0
EOF

chmod +x .githooks/pre-commit

cat << 'EOF' > .githooks/prepare-commit-msg
#!/bin/bash
# Runs after pre-commit already passed, so reaching this point means
# gitleaks found no secrets in the staged changes.
COMMIT_MSG_FILE="$1"
GITLEAKS_VERSION="$(gitleaks version 2>/dev/null)"

if ! grep -q "^Gitleaks-Scanned:" "$COMMIT_MSG_FILE" 2>/dev/null; then
  printf '\nGitleaks-Scanned: passed (gitleaks %s)\n' "$GITLEAKS_VERSION" >> "$COMMIT_MSG_FILE"
fi
EOF

chmod +x .githooks/prepare-commit-msg
git config core.hooksPath .githooks

echo "✅ Repo-local Git hook installed at .githooks/pre-commit"
echo "💡 Commit .githooks/ so every clone gets the same hook."
echo "💡 Each teammate still needs to run this script once after cloning"
echo "   (git config core.hooksPath .githooks) — hooks are never auto-enabled"
echo "   by git itself for security reasons."
