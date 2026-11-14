#!/bin/sh
# Checks the repo against the public-repo rules in CLAUDE.md: trademarked
# names, personal details, home paths, and secret-looking files. Scans tracked
# files and every commit reachable from any ref, since history is public too.
# Exits non-zero when anything matches. Run before every push.
#
# CLAUDE.md and this script name the banned terms on purpose, so they are
# skipped. LICENSE carries the developer's legal name on purpose.

set -u
cd "$(dirname "$0")/.." || exit 2

# Checked everywhere, including history.
STRICT='D&D|Dungeons (&|and) Dragons|Wizards of the Coast|Hasbro|5e|Pathfinder|Svartveit|/Users/|\.claude/|[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'
# Checked only where it is listing or public-facing text. Developer docs may
# name Apple's tools, and Xcode writes "iPhone Developer" into the project.
APPLE='iPhone|iPad|App Store|TestFlight'

SKIP=':!CLAUDE.md :!scripts/public-check.sh :!LICENSE'
fail=0

echo "== tracked files: strict terms"
# shellcheck disable=SC2086
if git grep -I -n -E "$STRICT" -- . $SKIP | grep -v 'users\.noreply\.github\.com'; then
    fail=1
fi

echo "== public-facing text: Apple marks"
if git grep -I -n -E "$APPLE" -- README.md 'project.yml' ':!*.pbxproj'; then
    fail=1
fi

echo "== commit history: author, committer, message and file contents"
for rev in $(git rev-list --all); do
    if git log -1 --format='%an%n%cn%n%B' "$rev" | grep -v -E 'noreply' | grep -E "$STRICT" >/dev/null; then
        echo "$rev: author, committer or message matches"
        fail=1
    fi
done
# shellcheck disable=SC2086
if git grep -I -l -E "$STRICT" $(git rev-list --all) -- . $SKIP | sed 's/^[^:]*://' | sort -u | grep . ; then
    echo "^ history contains strict terms in the files listed"
    fail=1
fi

echo "== secret-looking paths in history"
if git log --all --name-only --format= | grep -i -E '\.p8$|mobileprovision$|\.p12$|\.cer$|\.env$|secret' | sort -u | grep . ; then
    fail=1
fi

if [ "$fail" -eq 0 ]; then
    echo "OK: nothing matched"
else
    echo "FAILED: fix the matches above (history needs a rewrite, which needs approval)"
fi
exit "$fail"
