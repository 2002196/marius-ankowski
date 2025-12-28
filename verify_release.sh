#!/usr/bin/env bash
set -euo pipefail

repo="${1:-2002196/marius-ankowski}"
tag="${2:-}"
identity="${3:-mariusankowski@gmail.com}"
namespace="${4:-mi-release}"
workdir="${5:-./_verify_release}"

[[ -n "$tag" ]] || { echo "Usage: $0 <owner/repo> <tag> [identity] [namespace] [workdir]" >&2; exit 2; }

command -v gh >/dev/null 2>&1 || { echo "Missing: gh (GitHub CLI)" >&2; exit 1; }
command -v ssh-keygen >/dev/null 2>&1 || { echo "Missing: ssh-keygen" >&2; exit 1; }
command -v sha256sum >/dev/null 2>&1 || { echo "Missing: sha256sum" >&2; exit 1; }

mkdir -p "$workdir"
cd "$workdir"

echo "Downloading assets: $repo@$tag -> $workdir"
gh release download "$tag" --repo "$repo" \
  -p "SHA256SUMS" -p "SHA256SUMS.sig" -p "allowed_signers.example" \
  -p "*.iso" -p "*.tar.gz" -p "*.zip" >/dev/null

echo "Verify signature..."
ssh-keygen -Y verify -f allowed_signers.example \
  -I "$identity" -n "$namespace" \
  -s SHA256SUMS.sig < SHA256SUMS >/dev/null

echo "Verify hashes..."
sha256sum -c SHA256SUMS

echo "OK: verified $repo@$tag"
