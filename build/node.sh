#!/bin/bash
set -e

VERSION=$1
TARGET=$2

if [ -z "$VERSION" ] || [ -z "$TARGET" ]; then
    echo "Usage: $0 <version> <target>"
    exit 1
fi

echo "Building Node.js $VERSION for $TARGET..."

OUT_DIR="runtime/node/$VERSION/$TARGET"
mkdir -p "$OUT_DIR"

case "$TARGET" in
  "linux-x64")
    NODE_FILE="node-v$VERSION-linux-x64.tar.gz"
    echo "Downloading $NODE_FILE..."
    curl -L -o "$NODE_FILE" "https://nodejs.org/dist/v$VERSION/$NODE_FILE"
    tar -xzf "$NODE_FILE"
    mv "${NODE_FILE%.tar.gz}/bin/node" "$OUT_DIR/"
    rm -rf "$NODE_FILE" "${NODE_FILE%.tar.gz}"
    ;;
  "linux-arm64")
    NODE_FILE="node-v$VERSION-linux-arm64.tar.gz"
    echo "Downloading $NODE_FILE..."
    curl -L -o "$NODE_FILE" "https://nodejs.org/dist/v$VERSION/$NODE_FILE"
    tar -xzf "$NODE_FILE"
    mv "${NODE_FILE%.tar.gz}/bin/node" "$OUT_DIR/"
    rm -rf "$NODE_FILE" "${NODE_FILE%.tar.gz}"
    ;;
  "macos-x64")
    NODE_FILE="node-v$VERSION-darwin-x64.tar.gz"
    echo "Downloading $NODE_FILE..."
    curl -L -o "$NODE_FILE" "https://nodejs.org/dist/v$VERSION/$NODE_FILE"
    tar -xzf "$NODE_FILE"
    mv "${NODE_FILE%.tar.gz}/bin/node" "$OUT_DIR/"
    rm -rf "$NODE_FILE" "${NODE_FILE%.tar.gz}"
    ;;
  "macos-arm64")
    NODE_FILE="node-v$VERSION-darwin-arm64.tar.gz"
    echo "Downloading $NODE_FILE..."
    curl -L -o "$NODE_FILE" "https://nodejs.org/dist/v$VERSION/$NODE_FILE"
    tar -xzf "$NODE_FILE"
    mv "${NODE_FILE%.tar.gz}/bin/node" "$OUT_DIR/"
    rm -rf "$NODE_FILE" "${NODE_FILE%.tar.gz}"
    ;;
  "windows-x64")
    NODE_FILE="node-v$VERSION-win-x64.zip"
    echo "Downloading $NODE_FILE..."
    curl -L -o "$NODE_FILE" "https://nodejs.org/dist/v$VERSION/$NODE_FILE"
    unzip -q "$NODE_FILE"
    mv "${NODE_FILE%.zip}/node.exe" "$OUT_DIR/"
    rm -rf "$NODE_FILE" "${NODE_FILE%.zip}"
    ;;
  "android-arm64-v8a")
    ANDROID_ARCH="aarch64"
    echo "Downloading Android Node.js and dependencies..."
    mkdir -p tmp_android && cd tmp_android
    
    echo "Fetching Termux Packages index..."
    curl -f -s -L -o Packages "https://grimler.se/termux/termux-main/dists/stable/main/binary-$ANDROID_ARCH/Packages"
    
    PKGS="nodejs libc++ openssl c-ares libicu libsqlite zlib libffi resolv-conf libandroid-support"
    
    for PKG in $PKGS; do
        FILENAME=$(grep -A 20 "^Package: $PKG\$" Packages | grep "^Filename: " | head -n 1 | awk '{print $2}')
        if [ -n "$FILENAME" ]; then
            echo "Downloading $PKG..."
            curl -f -s -L -o "$PKG.deb" "https://grimler.se/termux/termux-main/$FILENAME"
            
            # Extract deb
            ar x "$PKG.deb"
            tar -xf data.tar.xz || tar -xf data.tar.gz || echo "Failed to extract $PKG data"
            rm -f "$PKG.deb" data.tar.* control.tar.* debian-binary
        else
            echo "Warning: Package $PKG not found in Termux repo for $ANDROID_ARCH"
        fi
    done
    cd ..
    
    mkdir -p "$OUT_DIR/lib"
    # Move the node binary
    if [ -f "tmp_android/data/data/com.termux/files/usr/bin/node" ]; then
        mv tmp_android/data/data/com.termux/files/usr/bin/node "$OUT_DIR/node.bin"
    else
        echo "Error: node binary not found after extraction!"
        exit 1
    fi
    
    # Move all shared libraries needed by node
    if [ -d "tmp_android/data/data/com.termux/files/usr/lib" ]; then
        cp -a tmp_android/data/data/com.termux/files/usr/lib/*.so* "$OUT_DIR/lib/" 2>/dev/null || true
    fi
    
    # Clean up extraction temp folder
    rm -rf tmp_android Packages
    
    # Create wrapper script
    cat << 'EOF' > "$OUT_DIR/node"
#!/system/bin/sh
DIR="$(cd "$(dirname "$0")" && pwd)"
export HOME="$DIR"
export TMPDIR="$DIR/tmp"
mkdir -p "$TMPDIR"
export LD_LIBRARY_PATH="$DIR/lib:$LD_LIBRARY_PATH"
exec "$DIR/node.bin" "$@"
EOF
    chmod +x "$OUT_DIR/node"
    
    # We will need to pull libc++_shared.so and others, but let's try if it works first or let user know.
    # Note: A full offline node package for Android requires extracting libz, libc++, libssl, etc.
    # To keep this script simple, we package just the binary for now. Termux binaries often need
    # their own libcrypto.so etc. 
    rm -rf tmp_android
    ;;
  *)
    echo "Unknown target: $TARGET"
    exit 1
    ;;
esac

echo "Downloading NPM..."
mkdir -p "$OUT_DIR/lib/node_modules"
curl -sL "https://registry.npmjs.org/npm/-/npm-10.8.1.tgz" | tar -xz -C "$OUT_DIR/lib/node_modules"
mv "$OUT_DIR/lib/node_modules/package" "$OUT_DIR/lib/node_modules/npm"

echo "Downloading PNPM..."
curl -sL -o "$OUT_DIR/lib/node_modules/pnpm.cjs" "https://unpkg.com/pnpm@9.4.0/dist/pnpm.cjs"

if [ "$TARGET" == "windows-x64" ]; then
    cat << 'EOF' > "$OUT_DIR/npm.cmd"
@echo off
"%~dp0node.exe" "%~dp0lib\node_modules\npm\bin\npm-cli.js" %*
EOF
    cat << 'EOF' > "$OUT_DIR/npx.cmd"
@echo off
"%~dp0node.exe" "%~dp0lib\node_modules\npm\bin\npx-cli.js" %*
EOF
    cat << 'EOF' > "$OUT_DIR/pnpm.cmd"
@echo off
"%~dp0node.exe" "%~dp0lib\node_modules\pnpm.cjs" %*
EOF
else
    if [ "$TARGET" == "android-arm64-v8a" ]; then
        SH_PATH="#!/system/bin/sh"
    else
        SH_PATH="#!/bin/sh"
    fi

    cat << EOF > "$OUT_DIR/npm"
$SH_PATH
DIR="\$(cd "\$(dirname "\$0")" && pwd)"
export HOME="\$DIR"
export TMPDIR="\$DIR/tmp"
mkdir -p "\$TMPDIR"
export npm_config_cache="\$DIR/.npm-cache"
if [ -f "/system/bin/linker64" ] && [ -f "\$DIR/node.bin" ]; then
    export LD_LIBRARY_PATH="\$DIR/lib:\$LD_LIBRARY_PATH"
    exec /system/bin/linker64 "\$DIR/node.bin" "\$DIR/lib/node_modules/npm/bin/npm-cli.js" "\$@"
else
    exec "\$DIR/node" "\$DIR/lib/node_modules/npm/bin/npm-cli.js" "\$@"
fi
EOF

    cat << EOF > "$OUT_DIR/npx"
$SH_PATH
DIR="\$(cd "\$(dirname "\$0")" && pwd)"
export HOME="\$DIR"
export TMPDIR="\$DIR/tmp"
mkdir -p "\$TMPDIR"
export npm_config_cache="\$DIR/.npm-cache"
if [ -f "/system/bin/linker64" ] && [ -f "\$DIR/node.bin" ]; then
    export LD_LIBRARY_PATH="\$DIR/lib:\$LD_LIBRARY_PATH"
    exec /system/bin/linker64 "\$DIR/node.bin" "\$DIR/lib/node_modules/npm/bin/npx-cli.js" "\$@"
else
    exec "\$DIR/node" "\$DIR/lib/node_modules/npm/bin/npx-cli.js" "\$@"
fi
EOF

    cat << EOF > "$OUT_DIR/pnpm"
$SH_PATH
DIR="\$(cd "\$(dirname "\$0")" && pwd)"
export HOME="\$DIR"
export TMPDIR="\$DIR/tmp"
mkdir -p "\$TMPDIR"
export npm_config_cache="\$DIR/.npm-cache"
if [ -f "/system/bin/linker64" ] && [ -f "\$DIR/node.bin" ]; then
    export LD_LIBRARY_PATH="\$DIR/lib:\$LD_LIBRARY_PATH"
    exec /system/bin/linker64 "\$DIR/node.bin" "\$DIR/lib/node_modules/pnpm.cjs" "\$@"
else
    exec "\$DIR/node" "\$DIR/lib/node_modules/pnpm.cjs" "\$@"
fi
EOF

    chmod +x "$OUT_DIR/npm" "$OUT_DIR/npx" "$OUT_DIR/pnpm"
fi

echo "Build complete."
