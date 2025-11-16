#!/bin/bash

# Upload to TestFlight using fastlane (if configured)
# Requires: fastlane installed and configured

set -e

echo "🚀 Uploading to TestFlight..."

if ! command -v fastlane &> /dev/null; then
    echo "❌ fastlane not found. Install with: sudo gem install fastlane"
    exit 1
fi

cd ios

# Build and upload
fastlane beta

echo "✅ Uploaded to TestFlight!"
echo "Check App Store Connect for processing status"

