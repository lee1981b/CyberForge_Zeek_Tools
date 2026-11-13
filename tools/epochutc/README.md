# epochutc

**Unix epoch seconds to UTC, built for Zeek investigations.**

```bash
epochutc 1762865412.453821
# 2025-11-11 12:50:12.453821 UTC
```

Version: **1.0.0**. Runtime: **Bash + GNU date**. Network: **none**.

The script is intentionally standalone. Copy `epochutc.sh`, run it with Bash,
or install it as the command `epochutc`. It is a shell utility, **not** a `.zeek`
script or a `zkg` package. Do not add it to Zeek's `@load` configuration.

## Start here

[Installation](INSTALL.md) covers the installer, manual copying, upgrades,
removal, and containers. [Usage](USAGE.md) covers timestamps, pipes, precision,
errors, and examples.

From the repository root:

```bash
bash tools/epochutc/epochutc.sh --help
bash tools/epochutc/install.sh --user
```

From this tool's directory:

```bash
bash epochutc.sh 1762865412.453821
bash install.sh --user
```

## Changes from the original snippet

The conversion remains GNU `date -u -d "@..."` with six fractional digits by
default. The packaged version adds help/version output, explicit validation,
correct failure exit codes, piped input, GNU `gdate` fallback, and an optional
nine-digit display. It passes the decimal timestamp directly to GNU date;
it does not convert timestamps through shell floating-point calculations.

[Back to the toolbox](../../README.md)
