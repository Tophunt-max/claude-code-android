#!/data/data/com.termux/files/usr/bin/bash
#
# Claude Code on Android — automated installer (proot-Ubuntu / Path B)
# Companion to the DevZoneX video. Run inside Termux on an unrooted Android phone.
#
# WHAT THIS DOES (README Chapters 1-3):
#   1. Termux packages: proot-distro, nodejs
#   2. Ubuntu container via proot-distro
#   3. Claude Code inside Ubuntu, via Anthropic's official installer
#
# WHAT THIS DOES NOT DO:
#   9Router setup, provider API keys, combos, and ~/.claude/settings.json.
#   Those need your own keys and a browser, so they stay manual.
#   The script prints the next steps when it finishes.
#
# Safe to re-run. Already-completed steps are detected and skipped.
#
# Version: 1.0 (2026-07-26)
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/iAmAjayTeli/claude-code-android/main/setup.sh -o setup.sh
#   cat setup.sh          # read it first
#   bash setup.sh

set -uo pipefail   # deliberately NOT -e: pkg upgrade can exit non-zero on
                   # harmless prompts. Every step below is checked explicitly.

VERSION="1.0"
MIN_FREE_MB=5000

say()  { printf '\n\033[1;36m==> %s\033[0m\n' "$1"; }
ok()   { printf '\033[1;32m  ✓ %s\033[0m\n' "$1"; }
warn() { printf '\n\033[1;33m!! %s\033[0m\n' "$1"; }
die()  { printf '\n\033[1;31mXX %s\033[0m\n\n' "$1" >&2; exit 1; }

# --- what runs INSIDE ubuntu ---------------------------------------------------
# Quoted heredoc: nothing expands here in Termux. $HOME resolves inside Ubuntu.
read -r -d '' UBUNTU_SETUP <<'EOS' || true
set -e
export DEBIAN_FRONTEND=noninteractive

# --force-confold keeps existing config files instead of stopping to ask.
# Without it an unattended apt upgrade can hang forever on a dpkg prompt.
APT_OPTS='-y -qq -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef'

echo "--- apt update / upgrade"
apt-get update -qq
# shellcheck disable=SC2086
apt-get upgrade $APT_OPTS

echo "--- installing curl git wget build-essential"
# shellcheck disable=SC2086
apt-get install $APT_OPTS curl git wget build-essential

if [ -x "$HOME/.local/bin/claude" ]; then
  echo "--- claude already present, skipping installer"
else
  echo "--- running Anthropic's official installer"
  # Download to a file first rather than piping straight into bash: with a
  # bare pipe, a failed download feeds bash an empty script that exits 0,
  # so the failure is silent and only shows up later as "command not found".
  curl -fsSL https://claude.ai/install.sh -o /tmp/claude-install.sh
  [ -s /tmp/claude-install.sh ] || { echo "!! installer download was empty"; exit 1; }
  bash /tmp/claude-install.sh
  rm -f /tmp/claude-install.sh
fi

# idempotent PATH line
if ! grep -q '.local/bin' "$HOME/.bashrc" 2>/dev/null; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
  echo "--- added ~/.local/bin to PATH in .bashrc"
fi

export PATH="$HOME/.local/bin:$PATH"

echo "--- verifying"
claude --version
EOS

# --- sanity checks -------------------------------------------------------------

printf '\n\033[1mClaude Code on Android — automated setup v%s\033[0m\n' "$VERSION"
printf 'Termux -> Ubuntu -> Claude Code. 9Router stays manual.\n'

[ -d /data/data/com.termux ] || die "This must run inside Termux.
Install Termux from F-Droid or GitHub Releases — NOT the Play Store."

arch=$(uname -m)
case "$arch" in
  aarch64|arm64) ok "architecture $arch" ;;
  *) die "Unsupported architecture: $arch
Claude Code needs aarch64. Some budget phones ship a 32-bit OS on 64-bit
hardware; there is no workaround for those." ;;
esac

avail_mb=$(df -m "$HOME" 2>/dev/null | awk 'NR==2 {print $4}')
if [ -n "${avail_mb:-}" ] && [ "$avail_mb" -lt "$MIN_FREE_MB" ]; then
  warn "Only ${avail_mb}MB free. Ubuntu is ~2GB and unpacks before cleanup;
${MIN_FREE_MB}MB recommended."
  printf '\nContinue anyway? [y/N] '
  read -r reply
  case "$reply" in [yY]*) ;; *) die "Stopped. Free up space and re-run." ;; esac
else
  ok "${avail_mb:-?}MB free"
fi

if command -v claude >/dev/null 2>&1; then
  warn "A 'claude' command already exists in TERMUX: $(command -v claude)
That is almost certainly a leftover native (Path A) install. It will not
interfere with the Ubuntu one, but having two different 'claude' commands
in two shells gets confusing. Consider removing it afterwards."
fi

# --- step 1: termux packages ---------------------------------------------------

say "Step 1/3 — Termux packages"
printf 'If asked about package maintainer configs, press y.\n\n'

pkg update -y
pkg upgrade -y
pkg install proot-distro nodejs -y

command -v proot-distro >/dev/null || die "proot-distro did not install.
Try 'pkg install proot-distro -y' manually and read the output."
ok "proot-distro ready"

if command -v node >/dev/null 2>&1; then
  ok "node $(node -v) — needed later for 9Router"
else
  warn "Node.js did not install. Claude Code does not need it, but 9Router
does. Fix with 'pkg install nodejs -y' before the 9Router step."
fi

# --- step 2: ubuntu ------------------------------------------------------------

# Check the rootfs directory directly rather than parsing `proot-distro list`.
# The --installed flag is not available on every proot-distro version, and if
# the check silently fails we would try to reinstall over a working container.
UBUNTU_ROOTFS="${PREFIX:-/data/data/com.termux/files/usr}/var/lib/proot-distro/installed-rootfs/ubuntu"

if [ -d "$UBUNTU_ROOTFS" ]; then
  say "Step 2/3 — Ubuntu already installed, skipping"
else
  say "Step 2/3 — installing Ubuntu (~2GB, usually 2-5 minutes)"
  if ! proot-distro install ubuntu; then
    if [ -d "$UBUNTU_ROOTFS" ]; then
      warn "Install reported an error but the container exists. Continuing."
    else
      die "Ubuntu install failed and no container was created.
Check your connection and free space, then re-run this script.

Only if a later run keeps failing on a half-written container should you
reset it — and be aware this DELETES everything inside Ubuntu:
  proot-distro remove ubuntu && proot-distro install ubuntu"
    fi
  fi
fi
ok "Ubuntu container ready"

# --- step 3: claude code inside ubuntu -----------------------------------------

say "Step 3/3 — installing Claude Code inside Ubuntu"
printf 'This runs apt and then Anthropic'\''s official installer. Output follows.\n'

if proot-distro login ubuntu -- bash -c "$UBUNTU_SETUP"; then
  ok "Claude Code installed and responding inside Ubuntu"
else
  die "The Ubuntu step failed. Run it by hand to see where:

  proot-distro login ubuntu
  apt update && apt upgrade -y
  apt install -y curl git wget build-essential
  curl -fsSL https://claude.ai/install.sh | bash
  echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.bashrc && source ~/.bashrc
  claude --version

See troubleshooting.md"
fi

# --- next steps ----------------------------------------------------------------

cat <<'EOF'

======================================================================
 Claude Code is installed. Two manual steps left — both need your own
 accounts, so they are not automated.
======================================================================

 FIRST, know which shell you are in. This trips up most people:

   Termux prompt:  ~ $              -> 9router lives HERE
   Ubuntu prompt:  root@...:~#      -> claude lives HERE

 ----------------------------------------------------------------------
 1. 9ROUTER  (in Termux, this session)

      npm install -g 9router
      9router

    Leave it running. Open http://localhost:20128 in your phone browser.
    Default dashboard password: 123456
    >> CHANGE IT. It is a published default. Do this before you use this
       phone on any shared or public network.

    Add your free providers, then create a priority-ordered combo and
    name it:  claude-opus-free

 ----------------------------------------------------------------------
 2. SETTINGS.JSON  (inside Ubuntu, in a NEW Termux session)

    Swipe from the left edge -> New session, then:

      proot-distro login ubuntu
      mkdir -p ~/.claude
      nano ~/.claude/settings.json

    This must be UBUNTU's home directory. A settings.json in Termux's
    home is silently ignored — no error, nothing works. Claude Code runs
    inside Ubuntu and only reads Ubuntu's home.

    Config to paste: README.md, Chapter 6.

 ----------------------------------------------------------------------
 THEN, daily use — two Termux sessions:

      session 1:  9router
      session 2:  proot-distro login ubuntu  ->  claude

 Stuck? -> troubleshooting.md
======================================================================

EOF
