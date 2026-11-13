# Adding another CyberForge tool

Keep each tool self-contained and independently installable:

```text
tools/tool-name/
|-- README.md
|-- INSTALL.md
|-- USAGE.md
|-- tool-name.sh       # Or the tool's appropriate implementation
`-- install.sh        # Only when an installer is appropriate
```

Describe the actual purpose, supported environment, dependencies, input/output,
errors, limitations, and any network or filesystem side effects. Add the tool
to the root README's toolbox table and record changes in `CHANGELOG.md`.

For native `.zeek` scripts, explain precisely how to load them and what they
change. Supply package metadata only when the tool is actually prepared for
that package manager. Do not load the entire repository by default.

## Review before inclusion

A collected third-party script is not automatically ours to redistribute or
safe to run. Establish its source and licence, retain required attribution,
review its behaviour/dependencies, and check that its licence is compatible
with its proposed inclusion. Do not apply this repository's MIT licence to
someone else's code without permission.

Inspect external requests, command execution, file writes, hard-coded secrets,
credential/body capture, excessive logging, and resource use. Test explicitly
against authorized, preferably synthetic data in a suitable isolated setup.
Record compatibility and known limitations rather than claiming universal
support based on a successful syntax check.

Only approved tools belong in the public toolbox. Keep private review queues,
real logs, PCAPs, tokens, and unreviewed script collections elsewhere.

## Tests and releases

Add regression tests covering ordinary input, invalid input, and the tool's
side effects. Use temporary directories; never write to a developer's actual
system installation during tests. Keep the CI workflow's permissions minimal.

Use tool-specific version numbers and tags, for example `epochutc-v1.0.0`, so
one tool can change without implying that every tool has changed.
