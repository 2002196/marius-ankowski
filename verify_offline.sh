#!/usr/bin/env bash
set -euo pipefail

dir="${1:-}"
identity="${2:-mariusankowski@gmail.com}"
namespace="${3:-mi-release}"
allowed="${4:-allowed_signers.example}"

[[ -n "$dir" ]] || { echo "Usage: $0 <dir-with-assets> [identity] [namespace] [allowed_signers_path]" >&2; exit 2; }

command -v ssh-keygen >/dev/null 2>&1 || { echo "Missing: ssh-keygen" >&2; exit 1; }
command -v sha256sum >/dev/null 2>&1 || { echo "Missing: sha256sum" >&2; exit 1; }

[[ -d "$dir" ]] || { echo "Not a directory: $dir" >&2; exit 1; }
[[ -f "$dir/SHA256SUMS" ]] || { echo "Missing: $dir/SHA256SUMS" >&2; exit 1; }
[[ -f "$dir/SHA256SUMS.sig" ]] || { echo "Missing: $dir/SHA256SUMS.sig" >&

