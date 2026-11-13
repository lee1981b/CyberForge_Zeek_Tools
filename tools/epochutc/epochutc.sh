#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 The CyberForge
# Convert Unix epoch seconds to UTC without shell floating-point arithmetic.

set -u

VERSION='1.0.0'
FORMAT='+%Y-%m-%d %H:%M:%S.%6N UTC'
DATE_BIN=''

usage() {
    cat <<'HELP'
epochutc - Unix epoch seconds to UTC, built for Zeek investigations

Usage:
  epochutc [--nanoseconds] <timestamp> [timestamp ...]
  epochutc [--nanoseconds] --stdin
  epochutc --help
  epochutc --version

Options:
  -h, --help         Show this help.
  -V, --version      Show the version.
  -n, --nanoseconds  Print nine fractional digits instead of six.
  -s, --stdin, -     Read one timestamp per line from standard input.
  --                End option parsing.

Examples:
  epochutc 1762865412.453821
  epochutc 0 -1 1762865412.453821
  printf '%s\n' 0 1.25 | epochutc --stdin
  zeek-cut ts < conn.log | epochutc --stdin

Input is Unix seconds, not milliseconds. Decimal fractions may contain
1-9 digits. Whole seconds and negative timestamps are accepted.
Blank stdin lines are skipped. Input may use LF or CRLF line endings.
No network access, Zeek installation, or elevated privileges are needed.

Exit codes: 0 success; 1 invalid timestamp(s); 2 usage/empty input;
            3 missing compatible GNU date (date or gdate).
HELP
}

find_date() {
    local candidate resolved probe
    for candidate in date gdate; do
        resolved=$(type -P "$candidate") || continue
        probe=$(LC_ALL=C "$resolved" -u -d '@0.123456789' \
            '+%Y-%m-%d %H:%M:%S.%9N UTC' 2>/dev/null) || continue
        if [[ $probe == '1970-01-01 00:00:00.123456789 UTC' ]]; then
            DATE_BIN=$resolved
            return 0
        fi
    done
    printf '%s\n' 'epochutc: GNU date is required (GNU coreutils; date or gdate on PATH).' >&2
    return 3
}

convert_timestamp() {
    local timestamp=$1
    # Restrict input to literal decimal seconds; never interpret commands.
    if [[ ! $timestamp =~ ^[+-]?[0-9]+([.][0-9]{1,9})?$ ]]; then
        printf 'epochutc: invalid timestamp: %q\n' "$timestamp" >&2
        return 1
    fi
    if ! LC_ALL=C "$DATE_BIN" -u -d "@$timestamp" "$FORMAT" 2>/dev/null; then
        printf 'epochutc: timestamp cannot be represented: %q\n' "$timestamp" >&2
        return 1
    fi
}

main() {
    local from_stdin=0 status=0 count=0 timestamp
    while (( $# > 0 )); do
        case $1 in
            -h|--help) usage; return 0 ;;
            -V|--version) printf 'epochutc %s\n' "$VERSION"; return 0 ;;
            -n|--nanoseconds) FORMAT='+%Y-%m-%d %H:%M:%S.%9N UTC'; shift ;;
            -s|--stdin|-) from_stdin=1; shift ;;
            --) shift; break ;;
            --*|-[a-zA-Z]*)
                printf 'epochutc: unknown option: %q\n' "$1" >&2
                return 2 ;;
            *) break ;;
        esac
    done

    if (( from_stdin && $# > 0 )); then
        printf '%s\n' 'epochutc: use timestamps OR --stdin, not both.' >&2
        return 2
    fi
    if (( ! from_stdin && $# == 0 )); then
        usage >&2
        return 2
    fi
    find_date || return 3

    if (( from_stdin )); then
        # The second condition also processes a final line without a newline.
        while IFS= read -r timestamp || [[ -n $timestamp ]]; do
            timestamp=${timestamp%$'\r'}
            [[ $timestamp =~ ^[[:space:]]*$ ]] && continue
            count=$((count + 1))
            convert_timestamp "$timestamp" || status=1
        done
        if (( count == 0 )); then
            printf '%s\n' 'epochutc: no timestamps were read from standard input.' >&2
            return 2
        fi
    else
        for timestamp in "$@"; do
            convert_timestamp "$timestamp" || status=1
        done
    fi
    return "$status"
}

main "$@"
