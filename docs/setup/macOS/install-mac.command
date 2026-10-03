#!/bin/bash
# ------------------------------------------------------------------------------
# Infinite Engine - macOS installer (Intel and Apple Silicon)
#
# Double-click to run. It installs Haxe, the project libraries and Lime.
# You only need to run it once, but running it again is harmless.
#
# It also works around a few known Mac problems:
#   - Intel Haxe mixed in on an Apple Silicon Mac
#   - the Neko path (NEKOPATH)
#   - Terminal running under Rosetta
#
# If something fails, the full log is here:
#   ~/Library/Logs/InfiniteEngine-install.log
# ------------------------------------------------------------------------------

set -eo pipefail

# Find the project root (the folder with Project.xml) by walking up from this
# file, so it works from any subfolder, like docs/setup/macOS.
ROOT="$(cd "$(dirname "$0")" && pwd)"
while [ "$ROOT" != "/" ] && [ ! -f "$ROOT/Project.xml" ]; do
  ROOT="$(dirname "$ROOT")"
done
cd "$ROOT"

LOG="$HOME/Library/Logs/InfiniteEngine-install.log"
mkdir -p "$(dirname "$LOG")"
exec > >(tee -a "$LOG") 2>&1

step()   { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
warn()   { printf '\033[1;33mHeads up: %s\033[0m\n' "$*"; }
pause()  { [ -n "$INFINITE_NO_PAUSE" ] && return 0; read -n 1 -s -r -p "Press any key to close this window..." || true; echo; }
fail()   { printf '\n\033[1;31mError: %s\033[0m\n' "$*"; echo "Full log: $LOG"; pause; exit 1; }

trap 'fail "Something broke on line $LINENO. Copy what you see here (or the log) and send it to whoever is helping you."' ERR

echo "Infinite Engine - Mac installer"
echo "Date: $(date)"

# --- Quick checks -------------------------------------------------------------
[ "$(uname -s)" = "Darwin" ] || fail "This installer only works on macOS."
{ [ -f Project.xml ] && [ -f hmm.json ]; } || fail "Can't find Project.xml and hmm.json. This script has to stay somewhere inside the Infinite-Engine folder."

ARCH="$(uname -m)"
if [ "$(sysctl -n sysctl.proc_translated 2>/dev/null || echo 0)" = "1" ]; then
  fail "Terminal is running under Rosetta (Intel mode), which would mix up versions. Close Terminal, turn off 'Open using Rosetta' in the Terminal app's info panel, and open this file again."
fi

if [ "$ARCH" = "arm64" ]; then
  BREW_BIN="/opt/homebrew/bin/brew"
else
  BREW_BIN="/usr/local/bin/brew"
fi
echo "Architecture: $ARCH"

# --- 1) Apple's command line tools --------------------------------------------
step "1/6 Apple command line tools"
if ! xcode-select -p >/dev/null 2>&1; then
  xcode-select --install || true
  fail "Apple's tools installer just opened. When it finishes, open this file again."
fi
echo "OK: $(xcode-select -p)"

# --- 2) Homebrew --------------------------------------------------------------
step "2/6 Homebrew"
if [ ! -x "$BREW_BIN" ]; then
  echo "Installing Homebrew (it'll ask for your Mac password)..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
[ -x "$BREW_BIN" ] || fail "Couldn't install Homebrew at $BREW_BIN."
eval "$("$BREW_BIN" shellenv)"

ZPROFILE="$HOME/.zprofile"
touch "$ZPROFILE"
if ! grep -qF "$BREW_BIN shellenv" "$ZPROFILE"; then
  echo "eval \"\$($BREW_BIN shellenv)\"" >> "$ZPROFILE"
fi
echo "OK: $(brew --version | head -n 1)"

# --- 3) Haxe ------------------------------------------------------------------
step "3/6 Haxe"
brew install haxe
hash -r

HAXE_BIN="$(command -v haxe || true)"
[ -n "$HAXE_BIN" ] || fail "Haxe didn't install."
case "$HAXE_BIN" in
  "$(brew --prefix)"/*) ;;
  *) warn "Using $HAXE_BIN instead of the Homebrew one. If the build fails, that old Haxe is probably why." ;;
esac

if [ "$ARCH" = "arm64" ]; then
  NEKO_INFO="$(file -L "$(command -v neko)")"
  case "$NEKO_INFO" in
    *arm64*) ;;
    *) fail "neko ($(command -v neko)) isn't built for Apple Silicon, so there's an Intel Haxe mixed in. Uninstall it and open this file again." ;;
  esac
fi
echo "OK: Haxe $(haxe --version)"

# --- 4) Paths -----------------------------------------------------------------
step "4/6 Setting up paths"
export NEKOPATH="$(brew --prefix)/lib/neko"
if ! grep -q "export NEKOPATH" "$ZPROFILE"; then
  echo "export NEKOPATH=\"$NEKOPATH\"" >> "$ZPROFILE"
fi
mkdir -p "$HOME/haxelib"
haxelib setup "$HOME/haxelib"
echo "OK: NEKOPATH=$NEKOPATH"

# --- 5) Project libraries -----------------------------------------------------
step "5/6 Project libraries (takes a few minutes, keep the window open)"
haxelib --global git hmm https://github.com/ALE-Psych-Crew/hmm
haxelib --global run hmm setup || warn "hmm setup didn't finish. Carrying on anyway."
haxelib --global run hmm install

# --- 6) Lime ------------------------------------------------------------------
step "6/6 Lime"
haxelib run lime setup -y || warn "lime setup didn't finish. Carrying on anyway."

step "Done"
echo "All set. Now open compile-mac.command to build and run the engine."
echo "The first build takes a few minutes."
trap - ERR
pause