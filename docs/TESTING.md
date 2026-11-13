# Testing

Run from the repository root:

```bash
bash tests/run-tests.sh
```

The test suite uses Bash and standard GNU/Linux utilities. It creates its own
temporary directory and removes it on exit. It never installs into
`/usr/local/bin` or modifies a real user's shell startup files.

## Coverage

The initial suite has **93 checks**, including ordinary/negative timestamps,
subsecond precision, UTC independence from the local timezone, multiple values,
invalid input, consistent exit statuses, stdin/CRLF handling, dependency errors,
and the `gdate` fallback.

Installer checks cover per-user and custom-prefix destinations, executable
permissions, repeated installation, backup-before-replacement, symlink and
non-regular-file refusal, paths containing spaces, and missing source/runtime
dependencies. Tests use a literal command-looking input to check it is rejected
rather than evaluated.

## Initial local validation

The initial 1.0.0 package was validated on Linux with **Bash 5.2.37** and
**GNU coreutils 9.7**. All 93 checks passed. This establishes those tested
behaviours; it is not a full security audit or a portability guarantee.

The actual privileged `/usr/local/bin` installation was not performed in the
test suite. Its shared copy/permission logic was exercised using temporary
prefixes. Native macOS/BSD execution, very large workload performance, and
GitHub-hosted CI were not validated as part of that local run. The `gdate`
fallback was tested using a controlled PATH on Linux.

The publication helper requires real GitHub authentication and the
maintainer's signing key. No live account creation, remote push, or hardware
signing is performed by this test suite.

A separate local publication smoke check passed six checks using a disposable
GPG test key and a mocked `gh` executable. It exercised explicit-publication
consent, destination validation, a real locally signed/verified commit, the
exact intended file inventory, repeat-run refusal, and stopping before remote
creation when signing fails. This simulation did not contact GitHub and does
not validate the maintainer's real YubiKey or GitHub authentication.

## GitHub Actions

`.github/workflows/tests.yml` runs Bash syntax checks and this same test suite
on an Ubuntu runner for pushes and pull requests. The workflow exists in the
package; remote results are available only after publication and a successful
Actions run. No passing CI badge is assumed in advance.

The workflow uses read-only repository permissions and a pinned checkout action
with credential persistence disabled. Review and update that pin intentionally
when maintaining the workflow.
