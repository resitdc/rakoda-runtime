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
    if command -v shasum &> /dev/null; then
        shasum -a 256 "$file" > "${file%.*}.sha256"
    elif command -v sha256sum &> /dev/null; then
        sha256sum "$file" > "${file%.*}.sha256"
    else
        powershell -Command "(Get-FileHash -Algorithm SHA256 -Path '$file').Hash.ToLower() + '  $file'" > "${file%.*}.sha256"
    fi
}


cd "runtime/$RUNTIME/$VERSION/$TARGET"

mkdir -p "../../../../out"

if [[ "$TARGET" == *"windows"* ]]; then
    if command -v 7z &> /dev/null; then
        7z a -tzip "${RUNTIME}-${TARGET}.zip" *
    else
        powershell -Command "Compress-Archive -Path * -DestinationPath ${RUNTIME}-${TARGET}.zip"
    fi
    generate_sha256 "${RUNTIME}-${TARGET}.zip"
    mv "${RUNTIME}-${TARGET}.zip" "../../../../out/"
    mv "${RUNTIME}-${TARGET}.sha256" "../../../../out/"
else
    tar -czf "${RUNTIME}-${TARGET}.tar.gz" *
    generate_sha256 "${RUNTIME}-${TARGET}.tar.gz"
    mv "${RUNTIME}-${TARGET}.tar.gz" "../../../../out/"
    mv "${RUNTIME}-${TARGET}.sha256" "../../../../out/"
fi

echo "Compression complete. Files moved to out/ directory."
