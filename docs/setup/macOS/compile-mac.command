#!/bin/bash
# ------------------------------------------------------------------------------
# Infinite Engine - build and run on macOS
#
# Double-click to build the engine (debug mode) and launch it.
# Run install-mac.command first if you haven't yet.
#
# The first build takes a few minutes. After that it's much quicker.
# For a clean build, delete the "export" folder and run this again.
#
# Log: ~/Library/Logs/InfiniteEngine-build.log
# ------------------------------------------------------------------------------

set -eo pipefail

# Find the project root (the folder with Project.xml) by walking up from this
# file, so it works from any subfolder, like docs/setup/macOS.
ROOT="$(cd "$(dirname "$0")" && pwd)"
while [ "$ROOT" != "/" ] && [ ! -f "$ROOT/Project.xml" ]; do
  ROOT="$(dirname "$ROOT")"
done
cd "$ROOT"

LOG="$HOME/Library/Logs/InfiniteEngine-build.log"
mkdir -p "$(dirname "$LOG")"
exec > >(tee -a "$LOG") 2>&1

step()   { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
warn()   { printf '\033[1;33mHeads up: %s\033[0m\n' "$*"; }
pause()  { [ -n "$INFINITE_NO_PAUSE" ] && return 0; read -n 1 -s -r -p "Press any key to close this window..." || true; echo; }
fail()   { printf '\n\033[1;31mError: %s\033[0m\n' "$*"; echo "Full log: $LOG"; pause; exit 1; }

trap 'fail "Something broke on line $LINENO. Copy what you see here (or the log) and send it to whoever is helping you."' ERR

echo "Infinite Engine - build for Mac"
echo "Date: $(date)"

[ "$(uname -s)" = "Darwin" ] || fail "This only works on macOS."
{ [ -f Project.xml ] && [ -f hmm.json ]; } || fail "Can't find Project.xml. This script has to stay somewhere inside the Infinite-Engine folder."

if [ "$(sysctl -n sysctl.proc_translated 2>/dev/null || echo 0)" = "1" ]; then
  fail "Terminal is running under Rosetta (Intel mode). Turn off 'Open using Rosetta' in the Terminal app's info panel and try again."
fi

# --- Environment: Homebrew, Neko and the macOS SDK ----------------------------
if [ "$(uname -m)" = "arm64" ]; then
  BREW_BIN="/opt/homebrew/bin/brew"
else
  BREW_BIN="/usr/local/bin/brew"
fi
[ -x "$BREW_BIN" ] || fail "Homebrew isn't installed. Run install-mac.command first."
eval "$("$BREW_BIN" shellenv)"
hash -r

command -v haxelib >/dev/null 2>&1 || fail "Can't find haxelib. Run install-mac.command first."
[ -d .haxelib ] || fail "The project libraries are missing (no .haxelib folder). Run install-mac.command first."

export NEKOPATH="$(brew --prefix)/lib/neko"

# Fix for 'SDK "macosx26" cannot be located': hxcpp picks the wrong SDK name,
# so we tell it the exact version Xcode has.
MACOSX_VER="$(xcrun --sdk macosx --show-sdk-version 2>/dev/null || true)"
if [ -n "$MACOSX_VER" ]; then
  export MACOSX_VER
  echo "macOS SDK: $MACOSX_VER"
else
  warn "Couldn't detect the macOS SDK version. Trying to build anyway."
fi

# --- Build and run ------------------------------------------------------------
step "Building and running (debug mode)"
trap - ERR
if haxelib run lime test macos -debug; then
  step "Game closed"
else
  fail "The build or the game ended with an error. Copy the last lines from this window and send them to whoever is helping you."
fi
pause