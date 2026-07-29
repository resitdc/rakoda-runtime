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
    curl -f -L -o "$PHP_FILE" "https://windows.php.net/downloads/releases/$PHP_FILE" || \
    curl -f -L -o "$PHP_FILE" "https://windows.php.net/downloads/releases/archives/$PHP_FILE" || \
    curl -f -L -o "$PHP_FILE" "https://downloads.php.net/~windows/releases/archives/$PHP_FILE"
    unzip -q "$PHP_FILE" -d "tmp_php"
    mv "tmp_php/php.exe" "$OUT_DIR/"
    rm -rf "tmp_php" "$PHP_FILE"
    ;;
  "android-arm64-v8a")
    ANDROID_ARCH="aarch64"
    echo "Downloading Android PHP and dependencies from Termux..."
    mkdir -p tmp_android && cd tmp_android
    
    echo "Fetching Termux Packages index..."
    curl -f -s -L -o Packages "https://grimler.se/termux/termux-main/dists/stable/main/binary-$ANDROID_ARCH/Packages"
    
    PKGS="php capstone libandroid-glob libandroid-support libbz2 libc++ boost libiconv liblzma zlib libandroid-wordexp libcurl libnghttp2 libnghttp3 libngtcp2 openssl ca-certificates libssh2 libffi libgmp libicu libresolv-wrapper resolv-conf libsqlite libxml2 libxslt libgcrypt libgpg-error libzip zstd oniguruma pcre2 readline ncurses tidy"
    
    for PKG in $PKGS; do
        FILENAME=$(grep -A 20 "^Package: $PKG\$" Packages | grep "^Filename: " | head -n 1 | awk '{print $2}')
        if [ -n "$FILENAME" ]; then
            echo "Downloading $PKG..."
            curl -f -s -L -o "$PKG.deb" "https://grimler.se/termux/termux-main/$FILENAME"
            
            ar x "$PKG.deb" 2>/dev/null || true
            tar -xf data.tar.xz 2>/dev/null || tar -xf data.tar.gz 2>/dev/null || echo "Failed to extract $PKG data"
            rm -f "$PKG.deb" data.tar.* control.tar.* debian-binary
        else
            echo "Warning: Package $PKG not found in Termux repo"
        fi
    done
    cd ..
    
    mkdir -p "$OUT_DIR/lib"
    if [ -f "tmp_android/data/data/com.termux/files/usr/bin/php" ]; then
        mv tmp_android/data/data/com.termux/files/usr/bin/php "$OUT_DIR/php.bin"
    else
        echo "Error: php binary not found!"
        exit 1
    fi
    
    if [ -d "tmp_android/data/data/com.termux/files/usr/lib" ]; then
        cp -a tmp_android/data/data/com.termux/files/usr/lib/*.so* "$OUT_DIR/lib/" 2>/dev/null || true
    fi
    
    rm -rf tmp_android
    
    cat << 'EOF' > "$OUT_DIR/php"
#!/system/bin/sh
DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "/system/bin/linker64" ] && [ -f "$DIR/php.bin" ]; then
    export LD_LIBRARY_PATH="$DIR/lib:$LD_LIBRARY_PATH"
    exec /system/bin/linker64 "$DIR/php.bin" "$@"
else
    export LD_LIBRARY_PATH="$DIR/lib:$LD_LIBRARY_PATH"
    exec "$DIR/php.bin" "$@"
fi
EOF
    chmod +x "$OUT_DIR/php"
    ;;
  *)
    echo "Unknown target: $TARGET"
    exit 1
    ;;
esac

# Download Composer
echo "Downloading Composer..."
curl -L -o "$OUT_DIR/composer.phar" "https://getcomposer.org/download/latest-stable/composer.phar"

if [ "$TARGET" == "windows-x64" ]; then
    cat << 'EOF' > "$OUT_DIR/composer.bat"
@echo off
"%~dp0php.exe" "%~dp0composer.phar" %*
EOF
else
    cat << 'EOF' > "$OUT_DIR/composer"
#!/system/bin/sh
DIR="$(cd "$(dirname "$0")" && pwd)"
exec "$DIR/php" "$DIR/composer.phar" "$@"
EOF
    chmod +x "$OUT_DIR/composer"
fi

echo "Build complete."
