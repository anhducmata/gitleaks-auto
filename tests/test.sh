#!/bin/bash
# Regression test suite for the gitleaks-auto pre-commit hook.
# Sets up a repo-local hook in an isolated temp repo, then asserts
# block/allow behavior across a matrix of secret types and clean files.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKDIR="$(mktemp -d)"
PASS=0
FAIL=0

cleanup() { rm -rf "$WORKDIR"; }
trap cleanup EXIT

setup_repo() {
  rm -rf "$WORKDIR/repo"
  mkdir -p "$WORKDIR/repo"
  cd "$WORKDIR/repo"
  git init -q
  git config user.email test@test.com
  git config user.name Test
  bash "$REPO_ROOT/install-repo.sh" >/dev/null 2>&1
}

# assert_case NAME FILE_CONTENT EXPECT(block|allow)
assert_case() {
  local name="$1" content="$2" expect="$3"
  setup_repo
  printf '%s' "$content" > payload.txt
  git add payload.txt
  if git commit -m "test: $name" >/tmp/gl_test_out.log 2>&1; then
    result="allow"
  else
    result="block"
  fi

  if [ "$result" = "$expect" ]; then
    echo "✅ PASS  [$name] expected=$expect got=$result"
    PASS=$((PASS+1))
  else
    echo "❌ FAIL  [$name] expected=$expect got=$result"
    echo "   --- gitleaks output ---"
    sed 's/^/   /' /tmp/gl_test_out.log
    FAIL=$((FAIL+1))
  fi
}

echo "== gitleaks-auto regression tests =="
echo

assert_case "AWS access key"      $'AWS_ACCESS_KEY_ID=AKIAZ3X9QK2P7VN4RTYU\nAWS_SECRET_ACCESS_KEY=k8Hn2pQxR7mVzT9wLdFj4sYbC6eAgU1oXi0MnZrW' block
assert_case "Stripe secret key"   $'STRIPE_SECRET_KEY=sk_live_'"$(head -c 32 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 24)" block
assert_case "GitHub PAT"          $'GITHUB_TOKEN=ghp_u6MgWHdVbVWG7rviqzjpOO4cNV5CWFmoY0cY' block
assert_case "Generic high-entropy key" $'API_KEY=k8Hn2pQxR7mVzT9wLdFj4sYbC6eAgU1oXi0MnZrW9pQxLm' block
assert_case "RSA private key"     $'-----BEGIN RSA PRIVATE KEY-----\nMIIEpAIBAAKCAQEA1c7+9z5Pad7OejecsQ0bu3aumnAgggeEub4tHFa8McbqfNQO\n-----END RSA PRIVATE KEY-----' block
assert_case "Clean text file"     $'hello world\nthis is just a readme line\n' allow
assert_case "Known AWS doc example key (allowlisted)" $'AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE' allow

echo
echo "== Results: $PASS passed, $FAIL failed =="
[ "$FAIL" -eq 0 ]
