#!/usr/bin/env bash
# setup-ahk-executor.sh
#
# Stand up a headless AutoHotkey v2 executor on Linux so the benchmark can be
# graded locally (no Windows box, no CloudAHK server needed). Installs Wine and
# Xvfb, downloads the portable AHK v2 interpreter, and starts a virtual display.
#
# AHK is a Windows GUI app: even a console script that only does
# FileAppend(..., "*") needs a window station, so a virtual display (Xvfb) is
# required or Wine exits with "no driver could be loaded".
#
# Designed to be idempotent and safe to run from a Claude Code on the web setup
# script (its output is cached, so later sessions start with this in place).
#
# After running, grade generated scripts with:
#   DISPLAY=:99 WINEPREFIX="$HOME/.wine-ahk" node scripts/grade-local.mjs
#
set -euo pipefail

AHK_DIR="${AHK_DIR:-/tmp/ahk}"
AHK_ZIP_URL="${AHK_ZIP_URL:-https://www.autohotkey.com/download/ahk-v2.zip}"
export WINEPREFIX="${WINEPREFIX:-$HOME/.wine-ahk}"
export WINEDEBUG="${WINEDEBUG:--all}"
DISPLAY_NUM="${DISPLAY_NUM:-99}"

echo ">> Installing wine + xvfb (if missing) ..."
if ! command -v wine >/dev/null || ! command -v Xvfb >/dev/null; then
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y
  apt-get install -y --no-install-recommends wine64 wine xvfb
fi

echo ">> Fetching AutoHotkey v2 portable ..."
mkdir -p "$AHK_DIR"
if [ ! -f "$AHK_DIR/AutoHotkey64.exe" ]; then
  tmp_zip="$(mktemp --suffix=.zip)"
  curl -fsSL -o "$tmp_zip" "$AHK_ZIP_URL"
  if command -v unzip >/dev/null; then
    unzip -o -q "$tmp_zip" -d "$AHK_DIR"
  else
    python3 -c "import zipfile,sys;zipfile.ZipFile('$tmp_zip').extractall('$AHK_DIR')"
  fi
  rm -f "$tmp_zip"
fi
test -f "$AHK_DIR/AutoHotkey64.exe" || { echo "!! AutoHotkey64.exe not found after extract"; exit 1; }

echo ">> Initializing wine prefix ..."
wineboot -i >/dev/null 2>&1 || true

echo ">> Starting Xvfb on :$DISPLAY_NUM ..."
if ! pgrep -x Xvfb >/dev/null; then
  Xvfb ":$DISPLAY_NUM" -screen 0 1024x768x16 >/tmp/xvfb.log 2>&1 &
  sleep 2
fi
export DISPLAY=":$DISPLAY_NUM"

echo ">> Smoke test ..."
printf '#Requires AutoHotkey v2.0\nFileAppend("OK=" . (6*7), "*")\n' > /tmp/_ahk_smoke.ahk
out="$(timeout 60 wine "$AHK_DIR/AutoHotkey64.exe" /ErrorStdOut 'Z:\tmp\_ahk_smoke.ahk' 2>/dev/null | tr -d '\r')"
case "$out" in
  OK=42*) echo ">> Executor ready. AHK_EXE=$AHK_DIR/AutoHotkey64.exe DISPLAY=:$DISPLAY_NUM WINEPREFIX=$WINEPREFIX" ;;
  *) echo "!! Smoke test failed, got: '$out'"; exit 1 ;;
esac
