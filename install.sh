#!/bin/bash

echo "🚀 Installing Gitleaks and setting up global Git hook..."

if ! command -v gitleaks &> /dev/null
then
    echo "📦 Installing Gitleaks..."
    brew install gitleaks
else
    echo "✅ Gitleaks already installed."
fi

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

echo "✅ Gitleaks global hook installed."
echo "💡 Run 'git init' inside existing repos to activate the hook."
