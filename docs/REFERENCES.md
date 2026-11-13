# Upstream references

The tool itself is deliberately small. These are the primary references for
its underlying behaviour and the surrounding workflows.

- [GNU date: seconds since the epoch](https://www.gnu.org/software/coreutils/manual/html_node/Seconds-since-the-Epoch.html) - the `@seconds` form, fractional/negative values, platform range, and leap-second caveats.
- [GNU date: time conversion specifiers](https://www.gnu.org/software/coreutils/manual/html_node/Time-conversion-specifiers.html) - time output and `%N` fractions.
- [GNU date: padding and other flags](https://www.gnu.org/software/coreutils/manual/html_node/Padding-and-other-flags.html) - field widths and fractional output.
- [Zeek log formats and inspection](https://docs.zeek.org/en/current/log-formats.html) - TSV logs and field extraction with `zeek-cut`.
- [Zeek's `zeek-cut` documentation source](https://github.com/zeek/zeek-docs/blob/master/log-formats.rst) - built-in `-u` UTC formatting as an alternative.
- [Docker storage overview](https://docs.docker.com/engine/storage/) - container writable layers and persistence.
- [Git commit documentation](https://git-scm.com/docs/git-commit) - signed commits using `-S`.
- [Git verify-commit documentation](https://git-scm.com/docs/git-verify-commit) - checking commit signatures.
- [GitHub CLI: gh repo create](https://cli.github.com/manual/gh_repo_create) - creating a new repository from a local directory.
- [GitHub: signature verification](https://docs.github.com/en/authentication/managing-commit-signature-verification/about-commit-signature-verification) - conditions for GitHub's verification status.
- [actions/checkout](https://github.com/actions/checkout) - the CI checkout action; the initial workflow pins the checked `v7` ref to `3d3c42e5aac5ba805825da76410c181273ba90b1`.
- [SPDX: MIT licence](https://spdx.org/licenses/MIT.html) - standard licence text.

The script and documentation are a CyberForge implementation, not copied
third-party Zeek detection scripts. No private logs, PCAPs, or external API
credentials are included.
