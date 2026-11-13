#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 The CyberForge
# Linux installer. No downloads, shell-profile edits, or automatic sudo.

set -euo pipefail

usage() {
    cat <<'HELP'
Install CyberForge epochutc on Linux.

Usage:
  bash install.sh [--user] [--force]
  sudo bash install.sh --system [--force]
  bash install.sh --prefix /absolute/path [--force]

Options:
  --user        Install to $HOME/.local/bin (default; no sudo required).
  --system      Install to /usr/local/bin (requires root).
  --prefix DIR  Install to DIR/bin; DIR must be an absolute path.
  --force       Replace a different existing regular file, keeping a backup.
  -h, --help    Show this help.

A matching copy is left in place and made executable. Symlinks and
non-regular destination files are never replaced, even with --force.
This installs only epochutc, not a Zeek package or a background service.
HELP
}

die() { printf 'install: %s\n' "$*" >&2; exit 1; }

mode='user'
prefix=''
force=0
selected=0
while (( $# > 0 )); do
    case $1 in
        --user|--system)
            (( selected == 0 )) || die 'choose only one installation location.'
            mode=${1#--}; selected=1; shift ;;
        --prefix)
            (( selected == 0 )) || die 'choose only one installation location.'
            (( $# >= 2 )) || die '--prefix requires an absolute directory.'
            mode='prefix'; prefix=$2; selected=1; shift 2 ;;
        --force) force=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *) die "unknown argument: $1 (see --help)." ;;
    esac
done

case $mode in
    user)
        [[ -n ${HOME:-} && $HOME == /* ]] || die 'HOME must be an absolute directory.'
        prefix=$HOME/.local ;;
    system)
        (( EUID == 0 )) || die 'system installation requires root; use sudo or --user.'
        prefix=/usr/local ;;
    prefix)
        [[ $prefix == /* && $prefix != '/' ]] || die '--prefix requires an absolute directory other than /.' ;;
esac

for dependency in bash install mktemp cmp cp mv ln chmod rm dirname; do
    command -v "$dependency" >/dev/null 2>&1 || die "missing dependency: $dependency"
done
# Atomic replacement/no-clobber below uses GNU coreutils -T semantics.
mv --version >/dev/null 2>&1 || die 'this installer needs GNU coreutils; use the manual installation guide.'

source_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
source_file=$source_dir/epochutc.sh
[[ -f $source_file && -r $source_file ]] || die "cannot read $source_file"
# Check runtime compatibility before creating a destination directory.
bash "$source_file" 0 >/dev/null || die 'epochutc dependency check failed; nothing was installed.'

bindir=${prefix%/}/bin
target=$bindir/epochutc
[[ ! -L $target ]] || die "refusing to replace symlink: $target"
if [[ -e $target ]]; then
    [[ -f $target ]] || die "destination is not a regular file: $target"
    if cmp -s -- "$source_file" "$target"; then
        chmod 0755 -- "$target"
        printf 'Already installed and executable: %s\n' "$target"
        exit 0
    fi
    (( force == 1 )) || die "a different file exists at $target; review it and use --force to keep a backup and replace it."
fi

if [[ ! -d $bindir ]]; then
    install -d -m 0755 -- "$bindir"
fi
temporary=''
cleanup() { if [[ -n $temporary ]]; then rm -f -- "$temporary"; fi; }
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
temporary=$(mktemp -- "$bindir/.epochutc.install.XXXXXX")
install -m 0755 -- "$source_file" "$temporary"

# Recheck immediately before writing. Install only into a trusted directory.
[[ ! -L $target ]] || die "refusing to replace symlink: $target"
if [[ -e $target ]]; then
    [[ -f $target ]] || die "destination is not a regular file: $target"
    (( force == 1 )) || die "a file appeared at $target; refusing to overwrite it."
    backup=$(mktemp -- "$bindir/epochutc.backup.XXXXXX")
    cp -p -- "$target" "$backup"
    printf 'Previous copy backed up to: %s\n' "$backup"
    mv -fT -- "$temporary" "$target"
    temporary=''
else
    # A hard link fails rather than overwriting a file created concurrently.
    ln -T -- "$temporary" "$target"
fi
printf 'Installed: %s\n' "$target"
printf 'Try: %s 1762865412.453821\n' "$target"
case :${PATH:-}: in
    *:"$bindir":*) ;;
    *) printf 'Not currently on PATH. Add this directory yourself: %s\n' "$bindir" ;;
esac
