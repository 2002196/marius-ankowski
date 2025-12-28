#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  tools/rtag.sh v0.2.12 "message"

What it does:
  - checks clean git state
  - creates annotated SIGNED tag (-s)
  - pushes tag to origin
  - prints release + workflow info
EOF
}

if [[ "${1:-}" == "" || "${2:-}" == "" ]]; then
  usage
  exit 2
fi

TAG="$1"
MSG="$2"
REPO="${REPO:-2002196/marius-ankowski}"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "ERROR: not in a git repo"
  exit 1
fi

git fetch --tags -f origin >/dev/null 2>&1 || true

if git rev-parse -q --verify "refs/tags/$TAG" >/dev/null; then
  echo "ERROR: tag already exists locally: $TAG"
  exit 1
fi

if git ls-remote --tags origin "refs/tags/$TAG" | grep -q .; then
  echo "ERROR: tag already exists on origin: $TAG"
  exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "ERROR: working tree not clean. Commit/stash first."
  git status --porcelain
  exit 1
fi

echo "== creating signed annotated tag: $TAG"
git tag -a -s "$TAG" -m "$MSG"

echo "== pushing tag: $TAG"
git push origin "$TAG"

echo
echo "== release view (may appear after workflow finishes) =="
gh release view "$TAG" --repo "$REPO" || true

echo
echo "== latest runs =="
gh run list --repo "$REPO" --limit 8 || true
