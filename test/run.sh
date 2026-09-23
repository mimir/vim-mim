#!/bin/sh
# Runs the test suite in Vim and in Neovim; an editor that is not installed is
# skipped.  Pass "vim" or "nvim" to run only that one.
#
#   test/run.sh          test/run.sh nvim          VIM=vim91 test/run.sh vim

set -eu

cd "$(dirname "$0")/.."

: "${VIM:=vim}"
: "${NVIM:=nvim}"

editors=${*:-vim nvim}
status=0
ran=0

for editor in $editors; do
  case $editor in
    vim)
      command -v "$VIM" >/dev/null 2>&1 || { echo "-- no $VIM, skipped"; continue; }
      ran=$((ran + 1))
      "$VIM" -es -N -i NONE -n -u test/minimal.vim -S test/run.vim </dev/null || status=1
      ;;
    nvim)
      command -v "$NVIM" >/dev/null 2>&1 || { echo "-- no $NVIM, skipped"; continue; }
      ran=$((ran + 1))
      "$NVIM" --headless -n -u test/minimal.vim -S test/run.vim </dev/null || status=1
      ;;
    *)
      echo "usage: $0 [vim] [nvim]" >&2
      exit 2
      ;;
  esac
done

[ "$ran" -gt 0 ] || { echo "neither Vim nor Neovim found" >&2; exit 2; }
exit "$status"
