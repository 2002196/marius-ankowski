#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Sign/verify release artifacts with OpenSSH signatures.

Commands:
  sign   <dir> <identity> <keyfile> <namespace> [allowed_signers]
  verify <dir> <identity> <namespace> <allowed_signers>

Outputs inside <dir>:
  SHA256SUMS
  SHA256SUMS.sig

Examples:
  ./tools/sign_release.sh sign   release "mariusankowski@gmail.com" ~/.ssh/id_ed25519_ci_sign_nopass mi-release allowed_signers.example
  ./tools/sign_release.sh verify release "mariusankowski@gmail.com" mi-release allowed_signers.example
EOF
}

die(){ echo "ERROR: $*" >&2; exit 1; }

cmd="${1:-}"; shift || true

case "$cmd" in
  sign)
    dir="${1:-}"; identity="${2:-}"; keyfile="${3:-}"; namespace="${4:-}"; allowed="${5:-allowed_signers.example}"
    [[ -n "$dir" && -n "$identity" && -n "$keyfile" && -n "$namespace" ]] || { usage; exit 2; }
    [[ -d "$dir" ]] || die "dir not found: $dir"
    [[ -f "$keyfile" ]] || die "keyfile not found: $keyfile"

    # Prefer repo file if present
    if [[ -f "$allowed" ]]; then
      allowed_path="$allowed"
    elif [[ -f "$PWD/$allowed" ]]; then
      allowed_path="$PWD/$allowed"
    else
      allowed_path=""
    fi

    (
      cd "$dir"
      # hash all files in dir except the summary itself + signature
      find . -maxdepth 1 -type f ! -name 'SHA256SUMS' ! -name 'SHA256SUMS.sig' -print0 \
        | sort -z \
        | xargs -0 sha256sum > SHA256SUMS

      echo "Signing file SHA256SUMS"
      ssh-keygen -Y sign -f "$keyfile" -n "$namespace" -I "$identity" SHA256SUMS >/dev/null

      echo "Write signature to SHA256SUMS.sig"
      [[ -f SHA256SUMS.sig ]] || die "Expected SHA256SUMS.sig not created"
    )

    # Optional self-verify if allowed signers exists
    if [[ -n "${allowed_path:-}" ]]; then
      echo "Self-verify using allowed signers: $allowed_path"
      ssh-keygen -Y verify -f "$allowed_path" -I "$identity" -n "$namespace" -s "$dir/SHA256SUMS.sig" < "$dir/SHA256SUMS" >/dev/null
    fi

    echo "OK: created $dir/SHA256SUMS and $dir/SHA256SUMS.sig"
    ;;
  verify)
    dir="${1:-}"; identity="${2:-}"; namespace="${3:-}"; allowed="${4:-}"
    [[ -n "$dir" && -n "$identity" && -n "$namespace" && -n "$allowed" ]] || { usage; exit 2; }
    [[ -f "$allowed" ]] || die "allowed_signers not found: $allowed"
    [[ -f "$dir/SHA256SUMS" && -f "$dir/SHA256SUMS.sig" ]] || die "missing SHA256SUMS(.sig) in: $dir"

    ssh-keygen -Y verify -f "$allowed" -I "$identity" -n "$namespace" -s "$dir/SHA256SUMS.sig" < "$dir/SHA256SUMS"
    ( cd "$dir" && sha256sum -c SHA256SUMS )
    ;;
  -h|--help|"")
    usage
    ;;
  *)
    die "Unknown command: $cmd"
    ;;
esac
