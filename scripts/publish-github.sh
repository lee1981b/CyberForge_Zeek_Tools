#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# First publication only. Requires the maintainer's local Git/GPG/gh setup.
# Never uploads credentials, rewrites history, or disables commit signing.
set -euo pipefail

usage() {
    cat <<'HELP'
Publish a fresh CyberForge Zeek Tools directory as a NEW public repository.

Usage:
  bash scripts/publish-github.sh --public [--repo OWNER/NAME]

Default repository: lee1981b/CyberForge_Zeek_Tools

--public is mandatory: running this command publishes the included code
and documentation publicly on GitHub. Run only from a freshly extracted
package, outside any existing Git repository. Inspect the files first.

Requires Git, GitHub CLI (gh), authenticated GitHub access, and a working
local signing key. Your normal Git identity/signing settings are retained.
A YubiKey may require a PIN and physical touch on your computer.

This helper refuses an existing local repository or existing remote repo.
If a first attempt fails after git init, use docs/PUBLISHING.md to resume.
HELP
}

die() { printf 'publish: %s\n' "$*" >&2; exit 1; }
# Pin all gh operations to the user's requested public GitHub host.
export GH_HOST=github.com
repository='lee1981b/CyberForge_Zeek_Tools'
public=0
while (( $# > 0 )); do
    case $1 in
        --public) public=1; shift ;;
        --repo)
            (( $# >= 2 )) || die '--repo requires OWNER/NAME.'
            repository=$2; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) die "unknown argument: $1" ;;
    esac
done
(( public == 1 )) || { usage >&2; exit 2; }
[[ $repository =~ ^[A-Za-z0-9][A-Za-z0-9-]*/[A-Za-z0-9][A-Za-z0-9._-]*$ ]] || die 'repository must be OWNER/NAME.'
for dependency in bash git gh; do
    command -v "$dependency" >/dev/null 2>&1 || die "missing dependency: $dependency; see docs/PUBLISHING.md."
done
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
cd -- "$root"
# Do not inherit repository-location overrides from the caller.
for variable in GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR; do
    [[ -z ${!variable:-} ]] || die "unset $variable before publishing."
done
[[ ! -e .git && ! -L .git ]] || die 'this directory already has Git metadata; see docs/PUBLISHING.md to resume safely.'
if git rev-parse --show-toplevel >/dev/null 2>&1; then
    die 'this directory is inside another Git repository; extract it somewhere separate.'
fi
[[ -n $(git config user.name || true) ]] || die 'configure your Git author name locally before publishing.'
[[ -n $(git config user.email || true) ]] || die 'configure your Git author email locally before publishing.'
gh auth status --hostname github.com || die 'authenticate with gh auth login --hostname github.com first.'
login=$(gh api --hostname github.com user --jq '.login')
[[ ${repository%%/*} == "$login" ]] || die "signed in as $login; the helper only creates a repository owned by that account."
if gh repo view "github.com/$repository" --json name >/dev/null 2>&1; then
    die 'that remote repository already exists; nothing has been changed.'
fi

printf 'Running the local test suite before publication...\n'
bash tests/run-tests.sh
printf '\nCreating a NEW PUBLIC repository: %s\n' "$repository"
printf 'Only this package is included. No other local repositories are read or pushed.\n'
git init -b main
git config --local commit.gpgsign true
git config --local tag.gpgsign true
# Explicit paths, rather than git add ., avoid unrelated files at the root.
git add -- README.md LICENSE CHANGELOG.md CONTRIBUTING.md SECURITY.md \
    .editorconfig .gitattributes .gitignore .github assets docs tools tests scripts
git diff --cached --stat
if ! git commit -S -m 'feat: launch CyberForge Zeek Tools with epochutc 1.0.0'; then
    die 'signed commit failed; nothing was published. See docs/PUBLISHING.md to resume without disabling signing.'
fi
git verify-commit HEAD || die 'signature verification failed; nothing was published.'
if ! gh repo create "$repository" --public --source=. --remote=origin \
    --description 'Practical Zeek and DFIR utilities from The CyberForge. Starting with epochutc: Unix epoch seconds to UTC.' \
    --disable-wiki --push; then
    die 'repository creation or push failed. A remote may now exist; inspect git remote -v and follow docs/PUBLISHING.md. Do not force-push.'
fi
printf '\nPublished: https://github.com/%s\n' "$repository"
printf 'The initial commit was signed with your configured local key.\n'
