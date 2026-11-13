# Installing epochutc

## Requirements and scope

The converter requires Bash and a GNU-compatible `date` command. It checks
`date` first, then `gdate`, using a fractional UTC conversion test. It does not
need Python, Zeek, an API key, a network connection, or root access to run.

The automated installer targets **Linux with GNU coreutils**. The converter's
`gdate` fallback is included for systems where GNU date has that name, but
native macOS/BSD operation has not been tested. Do not assume BSD or BusyBox
`date` can replace GNU date.

On Debian-family systems, missing runtime requirements can be installed with:

```bash
sudo apt install bash coreutils
```

All examples below start in the repository root unless stated otherwise.
Download or clone the repository, then inspect the scripts. The installer
copies only the already-downloaded `epochutc.sh`; it downloads nothing.

## Option A: installer, for your account

```bash
bash tools/epochutc/install.sh --user
```

Destination: `$HOME/.local/bin/epochutc`. Running the installer without options
also selects this per-user location. It creates the directory when necessary,
copies the script, and sets executable permissions to `0755`.

Try it using the full path first:

```bash
"$HOME/.local/bin/epochutc" 1762865412.453821
```

For the current shell, add the directory to your path when needed:

```bash
export PATH="$HOME/.local/bin:$PATH"
epochutc --version
```

For persistence, add that export once to the startup file appropriate for your
shell, such as `~/.bashrc` or `~/.zshrc`. The installer deliberately makes no
shell-startup changes itself. Use `command -v epochutc` to check which copy your
shell will run; use `hash -r` in Bash after replacing an existing command.

## Option B: installer, system-wide

```bash
sudo bash tools/epochutc/install.sh --system
```

Destination: `/usr/local/bin/epochutc`.

Inside a Linux container where you already have a root shell:

```bash
bash tools/epochutc/install.sh --system
```

The installer does not elevate privileges itself. `--system` requires root;
choose `--user` or an explicitly writable prefix instead for unprivileged use.

## Option C: a custom prefix

```bash
bash tools/epochutc/install.sh --prefix "$HOME/cyberforge"
"$HOME/cyberforge/bin/epochutc" 0
```

The prefix must be an absolute path other than `/`. The installer creates a
`bin` directory underneath it. Paths containing spaces are supported. Choose
a directory you control; installation into an adversary-controlled directory
is not supported.

## Existing copies and upgrades

A matching copy is left in place and made executable. A different existing
regular file causes installation to stop without overwriting it.

To deliberately upgrade an existing copy after reviewing it:

```bash
# Per-user installation:
bash tools/epochutc/install.sh --user --force

# Or system-wide installation:
sudo bash tools/epochutc/install.sh --system --force
```

`--force` creates an `epochutc.backup.<random-suffix>` file in the destination
`bin` directory before replacement and prints its exact path. Keep that backup
until you are satisfied with the new version. Symlinks, directories, and other
non-regular destinations are rejected even with `--force`.

## Option D: install manually

There is no need to run the installer. To copy the script for your own account
while refusing an existing destination:

```bash
mkdir -p "$HOME/.local/bin"
destination="$HOME/.local/bin/epochutc"
if [ -e "$destination" ] || [ -L "$destination" ]; then
    printf 'Not overwriting existing path: %s\n' "$destination" >&2
else
    install -m 0755 tools/epochutc/epochutc.sh "$destination"
fi
```

For a fresh system-wide manual installation:

```bash
if [ -e /usr/local/bin/epochutc ] || [ -L /usr/local/bin/epochutc ]; then
    printf '%s\n' 'Not overwriting existing /usr/local/bin/epochutc' >&2
else
    sudo install -d -m 0755 /usr/local/bin
    sudo install -m 0755 tools/epochutc/epochutc.sh /usr/local/bin/epochutc
fi
```

`install -m 0755` combines copying the file and setting its executable
permissions. When manually replacing a previous version, make and verify your
own backup first, or use the installer's explicit `--force` path.

## No-install use

```bash
bash tools/epochutc/epochutc.sh 1762865412.453821
```

No files are written by the converter.

## Containers

Install the command in the environment where you want to run it. A copy on
your host is not automatically available inside a container.

For a reproducible custom image, incorporate the file in your own Dockerfile
using the repository as build context:

```dockerfile
# Your base image must already provide Bash and GNU coreutils.
COPY tools/epochutc/epochutc.sh /usr/local/bin/epochutc
RUN chmod 0755 /usr/local/bin/epochutc
```

Installing into a running container's writable layer alone does not preserve
that change when the container is removed and recreated. Use your own image
or a deliberately configured persistent mount rather than relying on an
ad-hoc copy. See the Docker reference in [upstream references](../../docs/REFERENCES.md).

This repository does not change your Zeek image, container, capture settings,
package list, or `@load` configuration automatically.

## Remove the installed command

First confirm the path with `command -v epochutc`. Then remove only the copy
you installed:

```bash
# Per-user copy:
rm -- "$HOME/.local/bin/epochutc"

# OR system-wide copy:
sudo rm -- /usr/local/bin/epochutc
```

For a custom prefix, use that prefix's exact `bin/epochutc` path instead.
Backups are intentionally retained; review and remove them separately using
their exact names. Do not delete other tools in the directory.

[Usage guide](USAGE.md) | [Tool overview](README.md)
