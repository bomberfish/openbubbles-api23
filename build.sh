#!/usr/bin/env bash

# Pull submodules
git submodule update --init --recursive --remote

# Set up fake certificates for FairPlay
mkdir -p rustpush/certs/fairplay

cert_names=(
  "4056631661436364584235346952193"
  "4056631661436364584235346952194"
  "4056631661436364584235346952195"
  "4056631661436364584235346952196"
  "4056631661436364584235346952197"
  "4056631661436364584235346952198"
  "4056631661436364584235346952199"
  "4056631661436364584235346952200"
  "4056631661436364584235346952201"
  "4056631661436364584235346952208"
)

for name in "${cert_names[@]}"; do
    touch rustpush/certs/fairplay/$name.pem
    touch rustpush/certs/fairplay/$name.crt
done

# Build APK
flutter build apk --flavor alpha --debug --target-platform android-arm64