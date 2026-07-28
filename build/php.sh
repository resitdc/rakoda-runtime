#!/bin/bash
set -e

VERSION=$1
TARGET=$2

if [ -z "$VERSION" ] || [ -z "$TARGET" ]; then
    echo "Usage: $0 <version> <target>"
    exit 1
fi

echo "Building PHP $VERSION for $TARGET..."

OUT_DIR="runtime/php/$VERSION/$TARGET"
mkdir -p "$OUT_DIR"

# Static PHP CLI provides statically compiled PHP binaries.
# They are perfect for Linux, macOS, and especially Android (aarch64) because they have no dependencies.
# Note: dl.static-php.dev might have 8.4.1 instead of 8.4.0, we will try to fetch the closest match.
# For simplicity, we just use the latest available if exact version isn't there, but let's try $VERSION first.
PHP_VER="8.3.0" # Fallback if 8.4.0 not found
if [[ "$VERSION" == *"8.4"* ]]; then PHP_VER="8.4.1"; fi

case "$TARGET" in
  "linux-x64")
    PHP_FILE="php-$PHP_VER-cli-linux-x86_64.tar.gz"
    echo "Downloading $PHP_FILE..."
    curl -L -o "$PHP_FILE" "https://dl.static-php.dev/static-php-cli/common/$PHP_FILE"
    tar -xzf "$PHP_FILE"
    mv php "$OUT_DIR/"
    rm -f "$PHP_FILE"
    ;;
  "linux-arm64")
    PHP_FILE="php-$PHP_VER-cli-linux-aarch64.tar.gz"
    echo "Downloading $PHP_FILE..."
    curl -L -o "$PHP_FILE" "https://dl.static-php.dev/static-php-cli/common/$PHP_FILE"
    tar -xzf "$PHP_FILE"
    mv php "$OUT_DIR/"
    rm -f "$PHP_FILE"
    ;;
  "macos-x64")
    PHP_FILE="php-$PHP_VER-cli-macos-x86_64.tar.gz"
    echo "Downloading $PHP_FILE..."
    curl -L -o "$PHP_FILE" "https://dl.static-php.dev/static-php-cli/common/$PHP_FILE"
    tar -xzf "$PHP_FILE"
    mv php "$OUT_DIR/"
    rm -f "$PHP_FILE"
    ;;
  "macos-arm64")
    PHP_FILE="php-$PHP_VER-cli-macos-aarch64.tar.gz"
    echo "Downloading $PHP_FILE..."
    curl -L -o "$PHP_FILE" "https://dl.static-php.dev/static-php-cli/common/$PHP_FILE"
    tar -xzf "$PHP_FILE"
    mv php "$OUT_DIR/"
    rm -f "$PHP_FILE"
    ;;
  "windows-x64")
    PHP_FILE="php-$VERSION-nts-Win32-vs16-x64.zip"
    echo "Downloading Windows PHP $PHP_FILE..."
    # Download official Windows PHP binary
    curl -L -o "$PHP_FILE" "https://windows.php.net/downloads/releases/$PHP_FILE" || \
    curl -L -o "$PHP_FILE" "https://windows.php.net/downloads/releases/archives/$PHP_FILE"
    unzip -q "$PHP_FILE" -d "tmp_php"
    mv "tmp_php/php.exe" "$OUT_DIR/"
    rm -rf "tmp_php" "$PHP_FILE"
    ;;
  "android-arm64-v8a")
    echo "Downloading Static PHP for Android..."
    PHP_FILE="php-$PHP_VER-cli-linux-aarch64.tar.gz"
    curl -L -o "$PHP_FILE" "https://dl.static-php.dev/static-php-cli/common/$PHP_FILE"
    tar -xzf "$PHP_FILE"
    mv php "$OUT_DIR/"
    rm -f "$PHP_FILE"
    ;;
  *)
    echo "Unknown target: $TARGET"
    exit 1
    ;;
esac

echo "Build complete."
