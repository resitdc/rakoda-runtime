#!/bin/bash
set -e

VERSION=$1
TARGET=$2

if [ -z "$VERSION" ] || [ -z "$TARGET" ]; then
    echo "Usage: $0 <version> <target>"
    exit 1
fi

echo "Building PHP $VERSION for $TARGET..."
# TODO: Implement actual build logic using dockcross or native toolchains
# For Android, use builders/php/Dockerfile.android
# For Linux, use builders/php/Dockerfile.linux

mkdir -p "runtime/php/$VERSION/$TARGET"
echo "Dummy binary for PHP $VERSION on $TARGET" > "runtime/php/$VERSION/$TARGET/php"
chmod +x "runtime/php/$VERSION/$TARGET/php"
echo "Build complete."
