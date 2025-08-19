#!/usr/bin/env sh

SCRIPT_DIR_PATH="$(
    cd -- "$(dirname "$0")" >/dev/null 2>&1
    pwd -P
)"

if ! type cargo >/dev/null 2>/dev/null; then
    echo "Cargo not found, aborting..."
    exit 1
fi

if [ $# != 1 ] || { [ "$1" != "release" ] && [ "$1" != "debug" ] && [ "$1" != "clean" ]; }; then
    echo "Usage: build.sh <release|debug|clean>"
    exit 1
fi

case "$1" in
release)
    cargo build --release
    cp "$SCRIPT_DIR_PATH/target/release/libmaterial_you_derive_palette.so" "$SCRIPT_DIR_PATH"
    ;;
debug)
    cargo build
    cp "$SCRIPT_DIR_PATH/target/debug/libmaterial_you_derive_palette.so" "$SCRIPT_DIR_PATH"
    ;;
clean)
    cargo clean
    ;;
esac
