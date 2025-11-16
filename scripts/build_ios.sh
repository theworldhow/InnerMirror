#!/bin/bash

# Build iOS IPA for App Store Connect
# This script generates an archive ready for TestFlight/App Store

set -e

echo "🍎 Building InnerMirror for iOS..."

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode is not installed!"
    echo ""
    echo "Please install Xcode:"
    echo "1. Open App Store"
    echo "2. Search for 'Xcode'"
    echo "3. Install (free, ~15GB)"
    echo "4. Then run:"
    echo "   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer"
    echo "   sudo xcodebuild -runFirstLaunch"
    echo "   sudo gem install cocoapods"
    exit 1
fi

# Check if CocoaPods is installed
if ! command -v pod &> /dev/null; then
    echo "⚠️  CocoaPods not installed. Installing via Homebrew..."
    if command -v brew &> /dev/null; then
        brew install cocoapods
    else
        echo "❌ Homebrew not found. Please install CocoaPods manually:"
        echo "   brew install cocoapods"
        echo "   OR"
        echo "   sudo gem install cocoapods"
        exit 1
    fi
fi

# Install pods
echo "📦 Installing CocoaPods dependencies..."
export LANG=en_US.UTF-8
cd ios && pod install && cd ..

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Check code signing status
echo "🔍 Checking code signing setup..."
if ! xcodebuild -showBuildSettings -project ios/Runner.xcodeproj -scheme Runner 2>/dev/null | grep -q "CODE_SIGN_IDENTITY"; then
    echo ""
    echo "⚠️  Code signing not configured!"
    echo ""
    echo "To build for App Store, you need to set up code signing:"
    echo "1. Open Xcode: open ios/Runner.xcworkspace"
    echo "2. Select Runner project → Runner target → Signing & Capabilities"
    echo "3. Select your Development Team"
    echo "4. Run this script again"
    echo ""
    echo "For testing, use the simulator instead (no signing needed):"
    echo "  ./scripts/run_ios_simulator.sh"
    echo ""
    echo "See CODE_SIGNING_SETUP.md for detailed instructions."
    exit 1
fi

# Build iOS (requires Xcode and signing setup)
echo "🔨 Building IPA..."
flutter build ipa --release

echo "✅ IPA built successfully!"
echo "📦 Location: build/ios/ipa/innermirror.ipa"
echo ""
echo "Next steps:"
echo "1. Open Xcode: open ios/Runner.xcworkspace"
echo "2. Product > Archive"
echo "3. Window > Organizer"
echo "4. Distribute App > App Store Connect"
echo "5. Upload to TestFlight or submit for review"

