#!/bin/bash
set -e

RUNTIME=$1
VERSION=$2
TARGET=$3

if [ -z "$RUNTIME" ] || [ -z "$VERSION" ] || [ -z "$TARGET" ]; then
    echo "Usage: $0 <runtime> <version> <target>"
    exit 1
fi

echo "Compressing $RUNTIME $VERSION for $TARGET..."

cd "runtime/$RUNTIME/$VERSION/$TARGET"

if [[ "$TARGET" == *"windows"* ]]; then
    zip -r "${RUNTIME}.zip" *
    shasum -a 256 "${RUNTIME}.zip" > "${RUNTIME}.sha256"
else
    # Fallback to tar.gz if zstd is not installed in runner
    if command -v zstd &> /dev/null; then
        tar --zstd -cf "${RUNTIME}.tar.zst" *
        shasum -a 256 "${RUNTIME}.tar.zst" > "${RUNTIME}.sha256"
    else
        tar -czf "${RUNTIME}.tar.gz" *
        shasum -a 256 "${RUNTIME}.tar.gz" > "${RUNTIME}.sha256"
    fi
fi

echo "Compression complete."
