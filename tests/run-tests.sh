#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Local tests use temporary directories only, never /usr/local/bin.
set -uo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
TOOL=$ROOT/tools/epochutc/epochutc.sh
INSTALLER=$ROOT/tools/epochutc/install.sh
BASH_BIN=$(type -P bash)
DATE_BIN=$(type -P date)
TMP=$(mktemp -d)
trap 'rm -rf -- "$TMP"' EXIT
passed=0
failed=0
OUT=''
ERR=''
RC=0

pass() { passed=$((passed + 1)); printf 'PASS %s\n' "$1"; }
fail() { failed=$((failed + 1)); printf 'FAIL %s\n' "$1" >&2; }
run() {
    "$@" >"$TMP/stdout" 2>"$TMP/stderr"
    RC=$?
    OUT=$(<"$TMP/stdout")
    ERR=$(<"$TMP/stderr")
}
expect() {
    local label=$1 wanted_rc=$2 wanted_out=$3
    shift 3
    run "$@"
    if [[ $RC == "$wanted_rc" && $OUT == "$wanted_out" ]]; then
        pass "$label"
    else
        fail "$label (exit $RC; wanted $wanted_rc)"
        printf '  actual stdout: %q\n  wanted stdout: %q\n  stderr: %q\n' "$OUT" "$wanted_out" "$ERR" >&2
    fi
}
check() {
    local label=$1
    shift
    if "$@"; then pass "$label"; else fail "$label"; fi
}
stdin_case() {
    local payload=$1
    shift
    printf '%s' "$payload" | "$BASH_BIN" "$TOOL" "$@"
}

printf 'CyberForge epochutc test suite\n\n'
check 'converter syntax' "$BASH_BIN" -n "$TOOL"
check 'installer syntax' "$BASH_BIN" -n "$INSTALLER"
expect 'original Zeek example' 0 '2025-11-11 12:50:12.453821 UTC' "$BASH_BIN" "$TOOL" 1762865412.453821
expect 'epoch zero' 0 '1970-01-01 00:00:00.000000 UTC' "$BASH_BIN" "$TOOL" 0
expect 'whole seconds' 0 '1970-01-01 00:00:01.000000 UTC' "$BASH_BIN" "$TOOL" 1
expect 'positive sign' 0 '1970-01-01 00:00:01.000000 UTC' "$BASH_BIN" "$TOOL" +1
expect 'leading zeroes' 0 '1970-01-01 00:00:01.000000 UTC' "$BASH_BIN" "$TOOL" 0001
expect 'fraction padded to six places' 0 '1970-01-01 00:00:00.100000 UTC' "$BASH_BIN" "$TOOL" 0.1
expect 'six-place fraction retained' 0 '1970-01-01 00:00:00.123456 UTC' "$BASH_BIN" "$TOOL" 0.123456
expect 'default precision truncates, not rounds' 0 '1970-01-01 00:00:00.123456 UTC' "$BASH_BIN" "$TOOL" 0.123456789
expect 'nanosecond output' 0 '1970-01-01 00:00:00.123456789 UTC' "$BASH_BIN" "$TOOL" --nanoseconds 0.123456789
expect 'short nanosecond option' 0 '1970-01-01 00:00:01.000000000 UTC' "$BASH_BIN" "$TOOL" -n 1
expect 'negative seconds' 0 '1969-12-31 23:59:59.000000 UTC' "$BASH_BIN" "$TOOL" -1
expect 'negative fraction' 0 '1969-12-31 23:59:59.900000 UTC' "$BASH_BIN" "$TOOL" -0.1
expect 'negative nanosecond boundary' 0 '1969-12-31 23:59:59.999999999 UTC' "$BASH_BIN" "$TOOL" -n -0.000000001
expect 'post-2038 on this platform' 0 '2038-01-19 03:14:08.000000 UTC' "$BASH_BIN" "$TOOL" 2147483648
expect 'multiple arguments keep order' 0 $'1970-01-01 00:00:00.000000 UTC\n1970-01-01 00:00:01.250000 UTC' "$BASH_BIN" "$TOOL" 0 1.25
expect 'timezone does not change UTC output' 0 '1970-01-01 00:00:00.000000 UTC' env TZ=Pacific/Honolulu "$BASH_BIN" "$TOOL" 0
expect 'end-of-options marker' 0 '1969-12-31 23:59:59.000000 UTC' "$BASH_BIN" "$TOOL" -- -1
expect 'version' 0 'epochutc 1.0.0' "$BASH_BIN" "$TOOL" --version
run "$BASH_BIN" "$TOOL" --help
check 'help documents usage' test "$RC" -eq 0
check 'help has Usage section' test "${OUT#*Usage:}" != "$OUT"
expect 'no input is a usage error' 2 '' "$BASH_BIN" "$TOOL"
expect 'unknown option' 2 '' "$BASH_BIN" "$TOOL" --made-up
expect 'empty timestamp is invalid' 1 '' "$BASH_BIN" "$TOOL" ''
expect 'text is invalid' 1 '' "$BASH_BIN" "$TOOL" not-a-time
expect 'scientific notation is rejected' 1 '' "$BASH_BIN" "$TOOL" 1e3
expect 'comma decimal is rejected' 1 '' "$BASH_BIN" "$TOOL" 1,25
expect 'bare decimal fraction is rejected' 1 '' "$BASH_BIN" "$TOOL" .5
expect 'trailing decimal point is rejected' 1 '' "$BASH_BIN" "$TOOL" 1.
expect 'more than nine fractional digits is rejected' 1 '' "$BASH_BIN" "$TOOL" 1.1234567890
expect 'leading whitespace is rejected' 1 '' "$BASH_BIN" "$TOOL" ' 1'
expect 'unrepresentable timestamp is rejected' 1 '' "$BASH_BIN" "$TOOL" 99999999999999999999999999999999999999
expect 'failure does not stop subsequent conversions' 1 $'1970-01-01 00:00:00.000000 UTC\n1970-01-01 00:00:01.000000 UTC' "$BASH_BIN" "$TOOL" 0 bad 1
check 'invalid timestamp diagnostic is on stderr' test -n "$ERR"
expect 'shell content is not executed' 1 '' "$BASH_BIN" "$TOOL" "\$(touch '$TMP/should-not-exist')"
check 'no command-injection file was created' test ! -e "$TMP/should-not-exist"
expect 'stdin line stream' 0 $'1970-01-01 00:00:00.000000 UTC\n1970-01-01 00:00:01.250000 UTC' stdin_case $'0\n1.25\n' --stdin
expect 'stdin short option' 0 '1970-01-01 00:00:00.000000 UTC' stdin_case $'0\n' -s
expect 'stdin dash alias' 0 '1970-01-01 00:00:00.000000 UTC' stdin_case $'0\n' -
expect 'CRLF stdin' 0 $'1970-01-01 00:00:00.000000 UTC\n1970-01-01 00:00:01.250000 UTC' stdin_case $'0\r\n1.25\r\n' --stdin
expect 'stdin without final newline' 0 '1970-01-01 00:00:01.250000 UTC' stdin_case '1.25' --stdin
expect 'blank stdin lines are skipped' 0 '1970-01-01 00:00:00.000000 UTC' stdin_case $'\n  \n\t\n0\n\n' --stdin
expect 'empty stdin reports usage error' 2 '' stdin_case '' --stdin
expect 'blank-only stdin reports usage error' 2 '' stdin_case $'\n \n' --stdin
expect 'invalid stdin does not stop later rows' 1 $'1970-01-01 00:00:00.000000 UTC\n1970-01-01 00:00:01.000000 UTC' stdin_case $'0\nbad\n1\n' --stdin
expect 'stdin nanoseconds' 0 '1970-01-01 00:00:00.123456789 UTC' stdin_case $'0.123456789\n' -n --stdin
expect 'stdin cannot be combined with arguments' 2 '' "$BASH_BIN" "$TOOL" --stdin 0
expect 'raw Zeek rows are not silently accepted' 1 '' stdin_case $'0\tuid123\n' --stdin

mkdir -p "$TMP/no-date" "$TMP/fallback"
expect 'missing compatible date exits three' 3 '' env PATH="$TMP/no-date" "$BASH_BIN" "$TOOL" 0
expect 'version works without GNU date' 0 'epochutc 1.0.0' env PATH="$TMP/no-date" "$BASH_BIN" "$TOOL" --version
printf '#!/bin/sh\nexit 1\n' > "$TMP/fallback/date"
chmod 0755 "$TMP/fallback/date"
ln -s "$DATE_BIN" "$TMP/fallback/gdate"
expect 'gdate fallback' 0 '1970-01-01 00:00:00.000000 UTC' env PATH="$TMP/fallback" "$BASH_BIN" "$TOOL" 0

printf '\nInstaller tests (temporary prefixes only)\n'
run "$BASH_BIN" "$INSTALLER" --help
check 'installer help succeeds' test "$RC" -eq 0
expect 'installer missing prefix argument' 1 '' "$BASH_BIN" "$INSTALLER" --prefix
expect 'installer rejects relative prefix' 1 '' "$BASH_BIN" "$INSTALLER" --prefix relative
expect 'installer rejects root prefix' 1 '' "$BASH_BIN" "$INSTALLER" --prefix /
expect 'installer rejects conflicting locations' 1 '' "$BASH_BIN" "$INSTALLER" --user --system
expect 'installer rejects unknown argument' 1 '' "$BASH_BIN" "$INSTALLER" --anything
prefix=$TMP/custom
run "$BASH_BIN" "$INSTALLER" --prefix "$prefix"
check 'custom-prefix installation succeeds' test "$RC" -eq 0
check 'installed file matches source' cmp -s "$TOOL" "$prefix/bin/epochutc"
check 'installed file is executable' test -x "$prefix/bin/epochutc"
check 'installed permissions are 0755' test "$(stat -c '%a' "$prefix/bin/epochutc")" = 755
expect 'installed command works' 0 '2025-11-11 12:50:12.453821 UTC' "$prefix/bin/epochutc" 1762865412.453821
run "$BASH_BIN" "$INSTALLER" --prefix "$prefix"
check 'identical installation is idempotent' test "$RC" -eq 0
check 'idempotent install reports existing copy' test "${OUT#Already installed}" != "$OUT"
chmod 0644 "$prefix/bin/epochutc"
run "$BASH_BIN" "$INSTALLER" --prefix "$prefix"
check 'matching nonexecutable file gets executable permission' test -x "$prefix/bin/epochutc"
printf '#!/usr/bin/env bash\nprintf old-version\n' > "$prefix/bin/epochutc"
cp "$prefix/bin/epochutc" "$TMP/old-version"
run "$BASH_BIN" "$INSTALLER" --prefix "$prefix"
check 'different existing file is refused' test "$RC" -ne 0
check 'refused existing file is unchanged' cmp -s "$TMP/old-version" "$prefix/bin/epochutc"
run "$BASH_BIN" "$INSTALLER" --prefix "$prefix" --force
check 'explicit force installation succeeds' test "$RC" -eq 0
check 'forced new version matches source' cmp -s "$TOOL" "$prefix/bin/epochutc"
shopt -s nullglob
backups=("$prefix"/bin/epochutc.backup.*)
check 'force creates exactly one backup' test "${#backups[@]}" -eq 1
if (( ${#backups[@]} > 0 )); then
    check 'backup preserves the previous contents' cmp -s "$TMP/old-version" "${backups[0]}"
fi
leftovers=("$prefix"/bin/.epochutc.install.*)
check 'installation leaves no temporary files' test "${#leftovers[@]}" -eq 0

mkdir -p "$TMP/symlink/bin"
printf 'untouched\n' > "$TMP/victim"
ln -s "$TMP/victim" "$TMP/symlink/bin/epochutc"
run "$BASH_BIN" "$INSTALLER" --prefix "$TMP/symlink" --force
check 'symlink destination is refused with force' test "$RC" -ne 0
check 'symlink is retained' test -L "$TMP/symlink/bin/epochutc"
check 'symlink target is untouched' test "$(<"$TMP/victim")" = untouched
mkdir -p "$TMP/dangling/bin"
ln -s "$TMP/absent" "$TMP/dangling/bin/epochutc"
run "$BASH_BIN" "$INSTALLER" --prefix "$TMP/dangling" --force
check 'dangling destination symlink is refused' test "$RC" -ne 0
mkdir -p "$TMP/directory/bin/epochutc"
run "$BASH_BIN" "$INSTALLER" --prefix "$TMP/directory" --force
check 'directory destination is refused' test "$RC" -ne 0
mkdir -p "$TMP/fifo/bin"
mkfifo "$TMP/fifo/bin/epochutc"
run "$BASH_BIN" "$INSTALLER" --prefix "$TMP/fifo" --force
check 'FIFO destination is refused' test "$RC" -ne 0
run "$BASH_BIN" "$INSTALLER" --prefix "$TMP/path with spaces"
check 'prefix with spaces works' test "$RC" -eq 0
check 'space-containing destination is executable' test -x "$TMP/path with spaces/bin/epochutc"
run "$BASH_BIN" "$INSTALLER" --prefix "$TMP/trailing/"
check 'trailing slash in prefix works' test "$RC" -eq 0
mkdir -p "$TMP/source with spaces"
cp "$TOOL" "$INSTALLER" "$TMP/source with spaces/"
run "$BASH_BIN" "$TMP/source with spaces/install.sh" --prefix "$TMP/from copied source"
check 'installer works from source path containing spaces' test "$RC" -eq 0
run env HOME="$TMP/user-home" "$BASH_BIN" "$INSTALLER" --user
check 'user installation succeeds without system writes' test "$RC" -eq 0
check 'user destination is correct' test -x "$TMP/user-home/.local/bin/epochutc"
check 'installer did not create shell profile' test ! -e "$TMP/user-home/.bashrc"
run env HOME="$TMP/default-home" "$BASH_BIN" "$INSTALLER"
check 'default installation is per-user' test -x "$TMP/default-home/.local/bin/epochutc"
mkdir -p "$TMP/missing-source"
cp "$INSTALLER" "$TMP/missing-source/install.sh"
run "$BASH_BIN" "$TMP/missing-source/install.sh" --prefix "$TMP/should-not-install"
check 'missing source is refused' test "$RC" -ne 0
check 'missing source creates no destination' test ! -e "$TMP/should-not-install"
mkdir -p "$TMP/without-date"
for dependency in bash install mktemp cmp cp mv ln chmod rm dirname; do
    ln -s "$(type -P "$dependency")" "$TMP/without-date/$dependency"
done
run env PATH="$TMP/without-date" "$BASH_BIN" "$INSTALLER" --prefix "$TMP/dependency-failure"
check 'installer refuses missing GNU date' test "$RC" -ne 0
check 'dependency failure creates no destination' test ! -e "$TMP/dependency-failure"

mkdir -p "$TMP/private-bin/bin"
chmod 0700 "$TMP/private-bin/bin"
run "$BASH_BIN" "$INSTALLER" --prefix "$TMP/private-bin"
check 'installation into existing private bin succeeds' test "$RC" -eq 0
check 'existing bin permissions are preserved' test "$(stat -c '%a' "$TMP/private-bin/bin")" = 700

printf '\nResults: %s passed; %s failed.\n' "$passed" "$failed"
(( failed == 0 ))
