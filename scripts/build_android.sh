#!/bin/bash

# Build Android AAB for Google Play
# This script generates a signed AAB ready for upload

set -e

echo "🔨 Building InnerMirror for Android..."

# Check if Android SDK is available
if ! flutter doctor | grep -q "Android toolchain.*✓"; then
    echo "⚠️  Android toolchain not fully configured"
    echo "Run 'flutter doctor' to see what's missing"
    echo ""
    echo "Typically you need:"
    echo "1. Install Android Studio: https://developer.android.com/studio"
    echo "2. Install Android SDK through Android Studio"
    echo "3. Run: flutter doctor --android-licenses"
    echo ""
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build AAB
echo "🔨 Building AAB..."
flutter build appbundle --release

echo "✅ AAB built successfully!"
echo "📦 Location: build/app/outputs/bundle/release/app-release.aab"
echo ""
echo "Next steps:"
echo "1. Upload to Google Play Console: https://play.google.com/console"
echo "2. Go to Production > Create new release"
echo "3. Upload app-release.aab"
echo "4. Complete store listing and submit for review"

