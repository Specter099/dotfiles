#!/usr/bin/env bash
# setup-signed-commits.sh
# Configures SSH-based commit signing globally and registers the key with GitHub
# Usage: ./setup-signed-commits.sh [--key-path ~/.ssh/id_ed25519] [--email you@example.com]
set -euo pipefail

# ── Colors ────────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }
success() { echo -e "${GREEN}[✓]${NC}    $*"; }

# ── Defaults ──────────────────────────────────────────────────────────────────
KEY_PATH=""
EMAIL=""
KEY_COMMENT=""

# ── Args ──────────────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case $1 in
    --key-path) KEY_PATH="$2"; shift 2 ;;
    --email)    EMAIL="$2";    shift 2 ;;
    --help|-h)
      echo "Usage: $0 [--key-path <path>] [--email <email>]"
      echo ""
      echo "  --key-path   Path to existing SSH key (default: auto-detect or generate)"
      echo "  --email      Email for new key generation"
      exit 0 ;;
    *) error "Unknown argument: $1" ;;
  esac
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  SSH Commit Signing Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── Prereqs ───────────────────────────────────────────────────────────────────
command -v git >/dev/null 2>&1  || error "git is not installed"
command -v ssh-keygen >/dev/null 2>&1 || error "ssh-keygen is not installed"

GH_AVAILABLE=false
if command -v gh >/dev/null 2>&1; then
  GH_AVAILABLE=true
fi

# ── Resolve key path ──────────────────────────────────────────────────────────
if [[ -z "$KEY_PATH" ]]; then
  # Prefer ed25519, fall back to rsa
  for candidate in ~/.ssh/id_ed25519 ~/.ssh/id_rsa; do
    if [[ -f "$candidate" ]]; then
      KEY_PATH="$candidate"
      info "Found existing SSH key: $KEY_PATH"
      break
    fi
  done
fi

if [[ -z "$KEY_PATH" ]]; then
  warn "No existing SSH key found. Generating a new ed25519 key."
  if [[ -z "$EMAIL" ]]; then
    read -rp "Enter your email address for the new key: " EMAIL
  fi
  KEY_PATH="$HOME/.ssh/id_ed25519"
  KEY_COMMENT="${EMAIL}"
  ssh-keygen -t ed25519 -C "$KEY_COMMENT" -f "$KEY_PATH" -N ""
  success "Generated new SSH key at $KEY_PATH"
fi

PUB_KEY="${KEY_PATH}.pub"
[[ -f "$PUB_KEY" ]] || error "Public key not found at $PUB_KEY"

PUB_KEY_CONTENT=$(cat "$PUB_KEY")
info "Using public key: $PUB_KEY"

# ── Git global config ─────────────────────────────────────────────────────────
info "Configuring global git settings..."

git config --global gpg.format ssh
git config --global user.signingkey "$PUB_KEY"
git config --global commit.gpgsign true
git config --global tag.gpgsign true

# Set up allowed_signers file (required for git log --show-signature verification)
ALLOWED_SIGNERS="$HOME/.ssh/allowed_signers"
GIT_EMAIL=$(git config --global user.email 2>/dev/null || echo "")
if [[ -z "$GIT_EMAIL" && -n "$EMAIL" ]]; then
  GIT_EMAIL="$EMAIL"
  git config --global user.email "$EMAIL"
fi

if [[ -n "$GIT_EMAIL" ]]; then
  echo "${GIT_EMAIL} $(cat "$PUB_KEY")" > "$ALLOWED_SIGNERS"
  git config --global gpg.ssh.allowedSignersFile "$ALLOWED_SIGNERS"
  success "Created allowed_signers at $ALLOWED_SIGNERS"
else
  warn "Could not determine git email — skipping allowed_signers. Run manually:"
  warn "  echo 'you@example.com \$(cat $PUB_KEY)' >> ~/.ssh/allowed_signers"
  warn "  git config --global gpg.ssh.allowedSignersFile ~/.ssh/allowed_signers"
fi

success "Git global config updated"

# ── Summary of git config ─────────────────────────────────────────────────────
echo ""
echo "  Current signing config:"
echo "  ┌─────────────────────────────────────────────"
git config --global --list | grep -E "(sign|gpg|signingkey)" | while IFS= read -r line; do
  echo "  │  $line"
done
echo "  └─────────────────────────────────────────────"
echo ""

# ── GitHub registration ───────────────────────────────────────────────────────
if $GH_AVAILABLE; then
  if gh auth status >/dev/null 2>&1; then
    info "GitHub CLI authenticated. Registering signing key..."
    KEY_TITLE="commit-signing-$(hostname)-$(date +%Y%m%d)"

    # Check if already registered (compare by fingerprint)
    KEY_FINGERPRINT=$(ssh-keygen -lf "$PUB_KEY" | awk '{print $2}')
    if gh ssh-key list 2>/dev/null | grep -qF "$KEY_FINGERPRINT"; then
      success "SSH key is already registered on GitHub"
    else
      gh ssh-key add "$PUB_KEY" --title "$KEY_TITLE" --type signing
      success "Signing key registered on GitHub as: $KEY_TITLE"
      echo ""
      warn "ACTION REQUIRED: Enable Vigilant Mode on GitHub"
      echo "  1. Go to: https://github.com/settings/ssh"
      echo "  2. Scroll to 'Vigilant mode'"
      echo "  3. Enable 'Flag unsigned commits as unverified'"
    fi
  else
    warn "GitHub CLI not authenticated. Run: gh auth login"
    warn "Then re-run this script to register your signing key."
  fi
else
  warn "GitHub CLI not found. Install with: brew install gh"
  warn "Then register your key manually:"
  echo "  1. Go to: https://github.com/settings/ssh"
  echo "  2. Click 'New SSH key' → type: Signing"
  echo "  3. Paste your public key:"
  echo ""
  echo "  $PUB_KEY_CONTENT"
  echo ""
  warn "  Then enable Vigilant Mode to flag unsigned commits."
fi

# ── Verification test ─────────────────────────────────────────────────────────
echo ""
info "Verifying signing works with a test signature..."
TEST_MSG="test-signing-$(date +%s)"
if echo "$TEST_MSG" | ssh-keygen -Y sign -f "$KEY_PATH" -n git > /dev/null 2>&1; then
  success "SSH signing is working correctly"
else
  warn "Test signature failed. Your key may require a passphrase — that's fine."
  warn "Commits will prompt for passphrase (or use ssh-agent to cache it)."
fi

# ── ssh-agent tip ─────────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Setup complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Every new commit and tag will be signed automatically."
echo "  Verify a commit with: git log --show-signature -1"
echo ""
echo "  Your .zshrc uses a persistent agent socket at ~/.ssh/agent.sock"
echo "  Keys are cached via macOS Keychain (ssh-add --apple-use-keychain)"
echo ""
