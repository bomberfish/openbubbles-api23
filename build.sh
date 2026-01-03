#!/usr/bin/env bash

# Base directory
BASE_DIR=$(pwd)

# Pull openbubbles.so if it doesn't exist
if [ ! -f "$BASE_DIR"/android/app/src/main/jniLibs/arm64-v8a/openbubbles.so ]; then
  echo "openbubbles.so not found, downloading..."

  wget https://github.com/OpenBubbles/openbubbles-app/releases/download/v1.15.0%2B136/bluebubbles-linux-x86_64.tar
  mkdir bluebubbles-linux-x86_64
  tar -xvf bluebubbles-linux-x86_64.tar -C bluebubbles-linux-x86_64

  # Use appropriate checksum command for the platform
  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "f47fbd299bf5c83449bf6485a2c00c0f059d0e059646e20c64111bc5fac84b2a  bluebubbles-linux-x86_64/lib/librust_lib_bluebubbles.so" | shasum -a 256 -c || {
      echo "Checksum verification failed for bluebubbles-linux-x86_64/lib/librust_lib_bluebubbles.so"
      exit 1
    }
  else
    echo "f47fbd299bf5c83449bf6485a2c00c0f059d0e059646e20c64111bc5fac84b2a  bluebubbles-linux-x86_64/lib/librust_lib_bluebubbles.so" | sha256sum -c || {
      echo "Checksum verification failed for bluebubbles-linux-x86_64/lib/librust_lib_bluebubbles.so"
      exit 1
    }
  fi

  cp bluebubbles-linux-x86_64/lib/librust_lib_bluebubbles.so "$BASE_DIR"/android/app/src/main/jniLibs/arm64-v8a/openbubbles.so
else
  echo "openbubbles.so already exists, skipping download."
fi

# Pull submodules
git submodule update --init --recursive

# Build openbubbles-build-modules
cd rustpush/openbubbles-build-modules || exit
cargo build --release

# Copy openbubbles.so to current directory
cp "$BASE_DIR"/android/app/src/main/jniLibs/arm64-v8a/openbubbles.so .

# Extract FairPlay certificates
rm -r target/fairplay_certs || true
target/release/fairplay-certs || {
  echo "Failed to extract FairPlay certificates"
  exit 1
}

# Copy FairPlay certificates to rustpush
cp -r target/fairplay_certs "$BASE_DIR"/rustpush/certs/fairplay

# Build macos-validation-data for Linux target (if on macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
  echo "Detected macOS, building macos-validation-data with cross-compilation..."
  cd macos-validation-data || exit
  TARGET_CC=x86_64-unknown-linux-gnu cargo build --release --target x86_64-unknown-linux-gnu
  cd ..
  MACOS_VALIDATION_TARGET="x86_64-unknown-linux-gnu/release"
else
  MACOS_VALIDATION_TARGET="release"
fi

# Patch macos-validation-data for use with qemu
patchelf --set-interpreter ./ld-linux-x86-64.so.2 target/$MACOS_VALIDATION_TARGET/macos-validation-data

# Copy macos-validation-data binary
cp target/$MACOS_VALIDATION_TARGET/macos-validation-data "$BASE_DIR"/android/app/src/main/resources/lib/arm64-v8a/macos-validation-data

# Build APK
flutter build apk --flavor alpha --debug --target-platform android-arm64