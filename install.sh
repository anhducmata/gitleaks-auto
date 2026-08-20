#!/bin/bash

echo "🚀 [git-shield] Installing Gitleaks and setting up global Git hook..."

# Check if gitleaks is installed
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

# Create global pre-commit hook
HOOK_DIR="$HOME/.git-template/hooks"
mkdir -p "$HOOK_DIR"

cat << 'EOF' > "$HOOK_DIR/pre-commit"
#!/bin/bash
echo "🔍 Running Gitleaks scan..."
gitleaks protect --staged --source . --verbose --redact

if [ $? -ne 0 ]; then
    echo "❌ Gitleaks detected secrets! Commit blocked."
    exit 1
fi

echo "✅ No secrets found. Proceeding with commit."
exit 0
EOF

chmod +x "$HOOK_DIR/pre-commit"

cat << 'EOF' > "$HOOK_DIR/prepare-commit-msg"
#!/bin/bash
# Runs after pre-commit already passed, so reaching this point means
# gitleaks found no secrets in the staged changes.
COMMIT_MSG_FILE="$1"
GITLEAKS_VERSION="$(gitleaks version 2>/dev/null)"

if ! grep -q "^Gitleaks-Scanned:" "$COMMIT_MSG_FILE" 2>/dev/null; then
  printf '\nGitleaks-Scanned: passed (gitleaks %s)\n' "$GITLEAKS_VERSION" >> "$COMMIT_MSG_FILE"
fi
EOF

chmod +x "$HOOK_DIR/prepare-commit-msg"
git config --global init.templateDir "$HOME/.git-template"

echo "✅ Global Git hook installed."
echo "💡 To apply to existing repos, run: git init"
