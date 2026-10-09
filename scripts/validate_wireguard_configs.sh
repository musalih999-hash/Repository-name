#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIR="$ROOT/assets/wireguard"
failed=0
for file in "$DIR"/*.conf; do
  [[ -e "$file" ]] || continue
  echo "Checking $(basename "$file")"
  grep -q '^\[Interface\]' "$file" || { echo "  missing [Interface]"; failed=1; }
  grep -q '^\[Peer\]' "$file" || { echo "  missing [Peer]"; failed=1; }
  grep -q '^AllowedIPs' "$file" || { echo "  missing AllowedIPs"; failed=1; }
  if grep -Eq '<(CLIENT_PRIVATE_KEY|SERVER_PUBLIC_KEY|OPTIONAL_PRESHARED_KEY)>' "$file"; then
    echo "  template placeholders present (expected for preview)"
  fi
done
if [[ "$failed" -ne 0 ]]; then exit 1; fi
echo "WireGuard templates look structurally valid. Replace placeholders before production."
