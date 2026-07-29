#!/bin/bash
INDEX="Packages"
if [ ! -f "$INDEX" ]; then
    curl -s -L -o "$INDEX" "https://grimler.se/termux/termux-main/dists/stable/main/binary-aarch64/Packages"
fi
DEPS="php"
SEEN="php"

function resolve() {
    local PKG=$1
    local DEPS_STR=$(grep -A 20 "^Package: $PKG\$" "$INDEX" | grep "^Depends: " | head -n 1 | sed 's/Depends: //' | sed 's/,//g' | sed 's/ (.*)//g')
    for D in $DEPS_STR; do
        # Ignore package versions in parentheses if they exist, though sed removed them
        D=$(echo "$D" | awk '{print $1}')
        if [[ ! " $SEEN " =~ " $D " ]]; then
            SEEN="$SEEN $D"
            resolve "$D"
        fi
    done
}
resolve php
echo "$SEEN"
