# Contributing

Small, well-explained improvements are welcome. Start with an issue describing
the problem, expected behaviour, and a minimal synthetic example. Do not post
real credentials, private PCAPs, internal addresses, or sensitive logs.

For code changes, keep the utility easy to read, document changes to the public
interface, and add a regression test. Run `bash tests/run-tests.sh` before
submitting a pull request. Do not add network calls or new runtime dependencies
without an explicit, documented reason.

Use a separate directory for new tools and follow
[Adding another tool](docs/ADDING_TOOLS.md). Keep third-party attribution and
licences intact. Submissions must be yours to contribute under the applicable
licence; this project's code and documentation use MIT unless stated otherwise.

Maintainer commits and release tags should remain signed. Contributor signing
is encouraged, but no private key should ever be shared to obtain a signature.

Be constructive, respectful, and precise when reviewing one another's work.
