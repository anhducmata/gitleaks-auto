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
echo "🔍 Running Gitleaks scan..."
gitleaks protect --staged --source . --verbose --redact

if [ $? -ne 0 ]; then
    echo "❌ Gitleaks detected secrets! Commit blocked."
    exit 1
fi

echo "✅ No secrets found. Proceeding with commit."
exit 0
EOF

chmod +x .githooks/pre-commit
git config core.hooksPath .githooks

echo "✅ Repo-local Git hook installed at .githooks/pre-commit"
echo "💡 Commit .githooks/ so every clone gets the same hook."
echo "💡 Each teammate still needs to run this script once after cloning"
echo "   (git config core.hooksPath .githooks) — hooks are never auto-enabled"
echo "   by git itself for security reasons."
