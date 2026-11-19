#!/usr/bin/env bash
set -euo pipefail

ENV="${1:-}"
if [[ -z "$ENV" || ! "$ENV" =~ ^(dev|staging|production)$ ]]; then
  echo "Usage: $0 <dev|staging|production>" >&2
  exit 1
fi

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/firebase/$ENV/GoogleService-Info.plist"
DEST="$ROOT/ios/Runner/GoogleService-Info.plist"

if [[ ! -f "$SRC" ]]; then
  echo "Missing $SRC. Copy the .example file and fill in Firebase console values." >&2
  exit 1
fi

cp "$SRC" "$DEST"
echo "Copied $SRC -> $DEST"
