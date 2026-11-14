#!/bin/sh
# Checks the repo against the public-repo rules in CLAUDE.md: trademark names,
# personal details, home paths, and secret-looking files. Scans tracked files
# and every commit reachable from any ref, since history is public too.
# Exits non-zero when anything matches. Run before every push.
#
# The list of trademark names is kept out of the repo on purpose, in
# scripts/banned-terms.local (git-ignored). Each line is one extended regex.
# Lines starting with # are comments. Keep your own copy on each machine.

set -u
cd "$(dirname "$0")/.." || exit 2

TERMS=scripts/banned-terms.local
if [ ! -f "$TERMS" ]; then
    echo "missing $TERMS: create it from the names listed in CLAUDE.md's rules"
    exit 2
fi
TRADEMARKS=$(grep -v -E '^(#|$)' "$TERMS" | paste -sd'|' -)
# Personal and machine details, from the same rules.
PERSONAL='/Users/|\.claude/|[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'
STRICT="$TRADEMARKS|$PERSONAL"

# NOTICE carries the SRD 5.2.1 attribution statement verbatim, which the
# licence requires, so it is the one file skipped.
SKIP=':!NOTICE :!scripts/public-check.sh :!scripts/banned-terms.local'
fail=0

echo "== tracked files"
# shellcheck disable=SC2086
if git grep -I -n -E "$STRICT" -- . $SKIP | grep -v 'users\.noreply\.github\.com'; then
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
    echo "^ history contains banned terms in the files listed"
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
