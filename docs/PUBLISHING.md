# First publication on GitHub

Maintainer guide for **lee1981b / The CyberForge**.

Proposed public repository: `lee1981b/CyberForge_Zeek_Tools`.
These files are a ready-to-publish package. Their presence locally is not
confirmation that the GitHub repository exists or that CI has run remotely.

## Before publishing

Extract this package into its own directory, **outside** your Obsidian vault
and outside any other Git repository. Review the files and the MIT licence.
Do not copy your private Zeek script collection, PCAPs, logs, keys, or other
vault content into this public project.

The first-publication helper needs Bash, Git, GNU coreutils, GitHub CLI (`gh`),
and your existing local commit-signing setup. It does not need or request a
personal access token in a chat, a private-key export, or access to your
YubiKey from another machine.

On Kali/Debian, install `gh` only if it is missing:

```bash
sudo apt install gh
```

Check authentication, and log in interactively when necessary:

```bash
gh auth status --hostname github.com
# Run this only when authentication is not already configured:
gh auth login --hostname github.com
```

Check the existing Git identity and signing settings on your own computer:

```bash
git config --get user.name
git config --get user.email
git config --get user.signingkey
git config --get commit.gpgsign
```

Do not disable signing to make publication succeed. With a hardware-backed
key, have the YubiKey available and complete its normal PIN/touch prompt.

## Publish with the helper

From the freshly extracted repository root:

```bash
bash scripts/publish-github.sh --public \
  --repo lee1981b/CyberForge_Zeek_Tools
```

This is the step that makes the code and documentation **public**. The helper
runs the test suite, initializes a new local `main` branch, stages the explicit
package paths, creates a signed commit (`git commit -S`), verifies that
signature, and asks `gh` to create and push a new public repository.

It uses your existing Git identity and signing key. Only local repository
settings for signed commits/tags are set; your global Git configuration is
not rewritten. It refuses an existing remote, a directory already containing
Git metadata, and a directory nested inside another Git repository.

The helper is intentionally a **first-publication tool**, not a general sync
or update command. It does not force-push, amend existing history, or publish
another repository's contents.

## Manual publication / resuming an interrupted first attempt

Use these steps only in this package's separate directory. First inspect:

```bash
pwd
git status
git remote -v
```

For a brand-new directory with no `.git`, initialize it:

```bash
git init -b main
git config --local commit.gpgsign true
git config --local tag.gpgsign true
```

If the helper already performed `git init`, do not initialize again. Review
what is staged, then make the signed commit if none exists yet:

```bash
bash tests/run-tests.sh
git add -- README.md LICENSE CHANGELOG.md CONTRIBUTING.md SECURITY.md \
  .editorconfig .gitattributes .gitignore .github assets docs tools tests scripts
git diff --cached --stat
git commit -S -m 'feat: launch CyberForge Zeek Tools with epochutc 1.0.0'
git verify-commit HEAD
```

If a signed commit already exists and the working tree is clean, do not make
an unnecessary duplicate commit. Verify the existing one instead.

When the remote repository has **not** been created yet:

```bash
gh repo create lee1981b/CyberForge_Zeek_Tools \
  --public \
  --source=. \
  --remote=origin \
  --description 'Practical Zeek and DFIR utilities from The CyberForge.' \
  --disable-wiki \
  --push
```

When creation succeeded but the push failed, inspect the existing `origin`
and the repository's contents before resuming:

```bash
git remote -v
git log -1 --show-signature
# Only after confirming origin is the intended new, empty repository:
git push -u origin main
```

If GitHub has the new empty repository but there is no local `origin`, add
its URL after verifying the owner and name:

```bash
git remote add origin git@github.com:lee1981b/CyberForge_Zeek_Tools.git
git push -u origin main
```

If GitHub already contains unrelated commits or files, stop and reconcile
those deliberately. Do not use force-push as a shortcut.

## After the push

Open the new repository, check the README and file tree, and inspect the
initial commit signature. Local verification alone does not guarantee GitHub
will display its Verified badge; GitHub must recognize the signing key and
its association with the commit identity.

The included GitHub Actions workflow should start on push if Actions is
enabled for the repository/account. Its result is not known until GitHub
actually runs it. It has read-only repository permissions, disables checkout
credential persistence, and pins the checkout action to a full commit SHA.

An optional signed tool-specific release tag, after checking the release:

```bash
git tag -s epochutc-v1.0.0 -m 'epochutc 1.0.0'
git push origin epochutc-v1.0.0
```

Use normal signed commits for future updates. Add new tools in their own
folders rather than replacing this repository with a new unrelated project.

[Upstream Git/GitHub references](REFERENCES.md)
