#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  sign_release.sh sign   <dir> [identity] [key] [namespace]
  sign_release.sh verify <dir> [identity] [namespace] [allowed_signers]

Defaults:
  dir            = release
  identity       = mariusankowski@gmail.com
  key            = ~/.ssh/id_ed25519
  namespace      = mi-release
  allowed_signers= ~/.config/git/allowed_signers

Examples:
  ./tools/sign_release.sh sign release
  ./tools/sign_release.sh verify release
EOF
}

MODE="${1:-}"
DIR="${2:-release}"

IDENTITY_DEFAULT="mariusankowski@gmail.com"
KEY_DEFAULT="$HOME/.ssh/id_ed25519"
NS_DEFAULT="mi-release"
ALLOWED_DEFAULT="$HOME/.config/git/allowed_signers"

case "$MODE" in
  sign)
    IDENTITY="${3:-$IDENTITY_DEFAULT}"
    KEY="${4:-$KEY_DEFAULT}"
    NS="${5:-$NS_DEFAULT}"

    [[ -d "$DIR" ]] || { echo "No such dir: $DIR" >&2; exit 1; }
    [[ -f "$KEY" ]] || { echo "Missing private key: $KEY" >&2; exit 1; }

    pushd "$DIR" >/dev/null

    rm -f SHA256SUMS SHA256SUMS.sig

    shopt -s nullglob
    files=()
    while IFS= read -r -d '' f; do files+=("$f"); done < <(find . -maxdepth 1 -type f ! -name 'SHA256SUMS*' -print0 | sort -z)
    [[ ${#files[@]} -gt 0 ]] || { echo "No files to sign in $DIR" >&2; exit 1; }

    sha256sum "${files[@]}" > SHA256SUMS
    ssh-keygen -Y sign -f "$KEY" -n "$NS" SHA256SUMS >/dev/null

    echo "OK: created $DIR/SHA256SUMS and $DIR/SHA256SUMS.sig"
    echo "Verify:"
    echo "  ./tools/sign_release.sh verify $DIR '$IDENTITY' '$NS' '$ALLOWED_DEFAULT'"

    popd >/dev/null
    ;;

  verify)
    IDENTITY="${3:-$IDENTITY_DEFAULT}"
    NS="${4:-$NS_DEFAULT}"
    ALLOWED="${5:-$ALLOWED_DEFAULT}"

    [[ -d "$DIR" ]] || { echo "No such dir: $DIR" >&2; exit 1; }
    [[ -f "$ALLOWED" ]] || { echo "Missing allowed_signers: $ALLOWED" >&2; exit 1; }

    pushd "$DIR" >/dev/null
    [[ -f SHA256SUMS && -f SHA256SUMS.sig ]] || { echo "Missing SHA256SUMS or SHA256SUMS.sig in $DIR" >&2; exit 1; }

    ssh-keygen -Y verify -f "$ALLOWED" -I "$IDENTITY" -n "$NS" -s SHA256SUMS.sig < SHA256SUMS
    sha256sum -c SHA256SUMS

    echo "OK: signature + hashes verified."
    popd >/dev/null
    ;;

  ""|-h|--help|help)
    usage
    ;;

  *)
    echo "Unknown mode: $MODE" >&2
    usage
    exit 1
    ;;
esac
