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

generate_sha256() {
    local file=$1
    local out=$2
    if command -v shasum &> /dev/null; then
        shasum -a 256 "$file" > "$out"
    elif command -v sha256sum &> /dev/null; then
        sha256sum "$file" > "$out"
    else
        powershell -Command "(Get-FileHash -Algorithm SHA256 -Path '$file').Hash.ToLower() + '  $file'" > "$out"
    fi
}


cd "runtime/$RUNTIME/$VERSION/$TARGET"

if [[ "$TARGET" == *"windows"* ]]; then
    if command -v 7z &> /dev/null; then
        7z a -tzip "${RUNTIME}-${TARGET}.zip" *
    else
        powershell -Command "Compress-Archive -Path * -DestinationPath ${RUNTIME}-${TARGET}.zip"
    fi
    generate_sha256 "${RUNTIME}-${TARGET}.zip" "${RUNTIME}-${TARGET}.sha256"
else
    tar -czf "${RUNTIME}-${TARGET}.tar.gz" *
    generate_sha256 "${RUNTIME}-${TARGET}.tar.gz" "${RUNTIME}-${TARGET}.sha256"
fi

echo "Compression complete."
