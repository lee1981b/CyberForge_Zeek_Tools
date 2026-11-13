<div align="center">
  <a href="https://github.com/lee1981b"><img src="https://avatars.githubusercontent.com/u/134842202?v=4" width="112" height="112" alt="lee1981b GitHub avatar"></a>
  <h1>The CyberForge<br><sub>Zeek Tools</sub></h1>
  <p><strong>Small tools. Clear evidence. Practical investigations.</strong></p>
  <p>
    <img src="https://img.shields.io/badge/epochutc-1.0.0-007EC6" alt="epochutc version 1.0.0">
    <img src="https://img.shields.io/badge/Bash-GNU%20date-005A9C" alt="Bash and GNU date">
    <img src="https://img.shields.io/badge/Runtime-offline-0087BD" alt="Offline runtime">
    <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-007EC6" alt="MIT license"></a>
  </p>
  <p><a href="#toolbox">Toolbox</a> &middot; <a href="#quick-start">Quick start</a> &middot; <a href="tools/epochutc/INSTALL.md">Installation</a> &middot; <a href="tools/epochutc/USAGE.md">Usage</a> &middot; <a href="CONTRIBUTING.md">Contributing</a></p>
</div>

---

## From an investigation to a useful little tool

A fractional timestamp in a Zeek log is precise, but not especially friendly
when you are piecing together an incident timeline. **epochutc** started as a
small CyberForge command to turn those numbers into readable UTC timestamps.

This repository gives that utility a home, with room for future Zeek scripts
and investigation tools. Each tool lives in its own directory, with its own
purpose, dependencies, installation instructions, and tests.

**Nothing is automatically loaded into Zeek.** Installing one tool does not
install the rest of the collection. This is an independent community project,
not an official Zeek Project package.

## Toolbox

| Tool | Purpose | Status |
| :--- | :--- | :--- |
| [epochutc](tools/epochutc/) | Convert Unix epoch seconds, including fractional values, to UTC | 1.0.0 |

## Quick start

Requires **Bash and GNU coreutils** on Linux. Zeek is not required to run the
converter. Always inspect downloaded scripts before installing them.

```bash
git clone https://github.com/lee1981b/CyberForge_Zeek_Tools.git
cd CyberForge_Zeek_Tools

# Test without installing anything.
bash tools/epochutc/epochutc.sh 1762865412.453821

# Install for your own account; no sudo needed.
bash tools/epochutc/install.sh --user

# This works even when ~/.local/bin is not yet on PATH.
"$HOME/.local/bin/epochutc" 1762865412.453821
```

```text
2025-11-11 12:50:12.453821 UTC
```

Once `~/.local/bin` is on your `PATH`, simply run:

```bash
epochutc 1762865412.453821
```

System-wide installation, suitable for `/usr/local/bin`:

```bash
sudo bash tools/epochutc/install.sh --system
```

Already running as root inside a Linux container? Omit `sudo`. An existing,
different `epochutc` is **not overwritten by default**; `--force` explicitly
backs up that copy before replacing it. See the [installation guide](tools/epochutc/INSTALL.md).

## A few examples

```bash
# Several timestamps, preserving their order.
epochutc 0 1762865412.453821

# Retain nine fractional digits in the displayed result.
epochutc --nanoseconds 1762865412.453821123

# Zeek TSV logs: extract the ts field, then convert it.
zeek-cut ts < conn.log | epochutc --stdin

# A text file containing one timestamp per line.
epochutc --stdin < timestamps.txt
```

The default output has six fractional digits, matching the original utility.
Extra fractional digits are truncated in the displayed UTC value, not rounded.
`--nanoseconds` displays all nine. Input is **seconds**, not milliseconds.

Zeek already provides timestamp formatting through `zeek-cut -u`. This tool
complements it: a small standalone command for copied timestamps and timestamp
streams, with explicit fractional output and no requirement to install Zeek.
See [upstream references](docs/REFERENCES.md).

## Designed to be easy to inspect

The converter runs locally, makes no network requests, and does not modify
input files. Valid results go to stdout; errors go to stderr. Invalid input
produces a nonzero exit status while remaining valid timestamps are processed.

The Linux installer sets mode `0755`, supports per-user and system-wide
locations, refuses destination symlinks, and never edits your shell profile or
runs `sudo` on your behalf.

## Repository layout

```text
CyberForge_Zeek_Tools/
|-- README.md                    # Toolbox home page
|-- LICENSE                      # MIT licence
|-- CHANGELOG.md
|-- CONTRIBUTING.md
|-- SECURITY.md
|-- assets/                      # Branding notes / future local artwork
|-- docs/
|   |-- ADDING_TOOLS.md           # Pattern for future tools
|   |-- PUBLISHING.md             # Maintainer's signed publication workflow
|   |-- REFERENCES.md
|   `-- TESTING.md
|-- tools/
|   `-- epochutc/
|       |-- epochutc.sh           # The actual standalone utility
|       |-- install.sh            # Opt-in Linux installer
|       |-- README.md
|       |-- INSTALL.md
|       `-- USAGE.md
|-- tests/run-tests.sh            # Temporary-directory regression tests
|-- scripts/publish-github.sh     # First-publication helper, not an installer
`-- .github/workflows/tests.yml   # Read-only GitHub Actions test workflow
```

## Development

```bash
bash tests/run-tests.sh
```

See [testing and limitations](docs/TESTING.md) for the environment actually
tested. Future tools should follow the [contribution guide](CONTRIBUTING.md)
and [tool template](docs/ADDING_TOOLS.md).

## Licence and attribution

Code and documentation are available under the [MIT licence](LICENSE).
Created by **The CyberForge** / [lee1981b](https://github.com/lee1981b).
The account avatar is reused by URL for branding; it is not included in the
software licence. Zeek and third-party names belong to their respective owners.

---

<div align="center"><strong>The CyberForge</strong><br>Built from real investigation needs. Shared for others to inspect, use, and improve.</div>
