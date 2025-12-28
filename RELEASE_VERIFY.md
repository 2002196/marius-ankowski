# Verify MI Release (SSH signatures)

This release is signed by **Marius Ankowski** using OpenSSH signatures.

## Requirements
- OpenSSH (ssh-keygen with `-Y`)
- sha256sum

## Verify on Linux/macOS
1) Download these assets from the GitHub Release:
   - SHA256SUMS
   - SHA256SUMS.sig
   - allowed_signers.example
   - (the artifact files, e.g. *.tar.gz / *.zip / *.iso)

2) Verify signature:
```bash
ssh-keygen -Y verify -f allowed_signers.example \
  -I "mariusankowski@gmail.com" -n "mi-release" \
  -s SHA256SUMS.sig < SHA256SUMS


