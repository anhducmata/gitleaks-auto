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
gitleaks detect --source . --verbose --redact

if [ $? -ne 0 ]; then
    echo "❌ Gitleaks detected secrets! Commit blocked."
    exit 1
fi

echo "✅ No secrets found. Proceeding with commit."
exit 0
EOF

chmod +x "$HOOK_DIR/pre-commit"
git config --global init.templateDir "$HOME/.git-template"

echo "✅ Global Git hook installed."
echo "💡 To apply to existing repos, run: git init"
