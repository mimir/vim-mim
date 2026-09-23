#!/bin/sh
# Runs the test suite in Vim and in Neovim; an editor that is not installed is
# skipped.  Pass "vim" or "nvim" to run only that one.  $VIM_BIN and $NVIM_BIN
# select which binary to use - and note that $VIM and $NVIM are *not* free to
# use for that: Vim looks up its runtime files via $VIM, and Neovim reports a
# running instance in $NVIM.
#
#   test/run.sh     test/run.sh nvim     VIM_BIN=/opt/vim91/bin/vim test/run.sh vim

set -eu

cd "$(dirname "$0")/.."

: "${VIM_BIN:=vim}"
: "${NVIM_BIN:=nvim}"

editors=${*:-vim nvim}
status=0
ran=0

for editor in $editors; do
  case $editor in
    vim)
      command -v "$VIM_BIN" >/dev/null 2>&1 || { echo "-- no $VIM_BIN, skipped"; continue; }
      ran=$((ran + 1))
      "$VIM_BIN" -es -N -i NONE -n -u test/minimal.vim -S test/run.vim </dev/null || status=1
      ;;
    nvim)
      command -v "$NVIM_BIN" >/dev/null 2>&1 || { echo "-- no $NVIM_BIN, skipped"; continue; }
      ran=$((ran + 1))
      "$NVIM_BIN" --headless -n -u test/minimal.vim -S test/run.vim </dev/null || status=1
      ;;
    *)
      echo "usage: $0 [vim] [nvim]" >&2
      exit 2
      ;;
  esac
done

[ "$ran" -gt 0 ] || { echo "neither Vim nor Neovim found" >&2; exit 2; }
exit "$status"
