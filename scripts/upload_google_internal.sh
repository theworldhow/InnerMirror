#!/bin/bash

# Upload to Google Play Internal Testing
# Requires: Google Play Console API access and service account

set -e

echo "🚀 Uploading to Google Play Internal Testing..."

AAB_PATH="build/app/outputs/bundle/release/app-release.aab"

if [ ! -f "$AAB_PATH" ]; then
    echo "❌ AAB not found. Run ./scripts/build_android.sh first"
    exit 1
fi

# Using fastlane (if configured)
if command -v fastlane &> /dev/null; then
    cd android
    fastlane internal
    echo "✅ Uploaded to Google Play Internal Testing!"
else
    echo "⚠️  fastlane not configured. Manual upload:"
    echo "1. Go to Google Play Console"
    echo "2. Testing > Internal testing > Create new release"
    echo "3. Upload: $AAB_PATH"
fi

