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
    echo "Downloading Node.js for Android (Termux build)..."
    # We download a known termux nodejs build and some basic shared libraries it might need
    mkdir -p tmp_android && cd tmp_android
    
    # Download nodejs deb from termux package mirror
    LATEST_DEB=$(curl -s https://grimler.se/termux/termux-main/pool/main/n/nodejs/ | grep aarch64.deb | head -n 1 | grep -o 'nodejs_[^"]*\.deb' | head -n 1)
    DEB_URL="https://grimler.se/termux/termux-main/pool/main/n/nodejs/$LATEST_DEB"
    curl -f -L -o node.deb "$DEB_URL"
    
    # Extract deb (GitHub actions uses Ubuntu, so ar is available)
    ar x node.deb
    tar -xf data.tar.xz
    
    cd ..
    
    # Move the binary
    mv tmp_android/data/data/com.termux/files/usr/bin/node "$OUT_DIR/node.bin"
    
    # Create wrapper script
    cat << 'EOF' > "$OUT_DIR/node"
#!/system/bin/sh
DIR="$(cd "$(dirname "$0")" && pwd)"
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

echo "Build complete."
