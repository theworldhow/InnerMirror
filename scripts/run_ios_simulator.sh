#!/bin/bash

# Run InnerMirror on iOS Simulator (no code signing required)
# This is the easiest way to test the app without setting up certificates

set -e

echo "📱 Running InnerMirror on iOS Simulator..."

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode is not installed!"
    echo ""
    echo "Please install Xcode from the App Store first."
    exit 1
fi

# Check if CocoaPods is installed
if ! command -v pod &> /dev/null; then
    echo "⚠️  CocoaPods not installed. Installing via Homebrew..."
    if command -v brew &> /dev/null; then
        brew install cocoapods
    else
        echo "❌ Homebrew not found. Please install CocoaPods manually."
        exit 1
    fi
fi

# Install pods if needed
if [ ! -d "ios/Pods" ]; then
    echo "📦 Installing CocoaPods dependencies..."
    export LANG=en_US.UTF-8
    cd ios && pod install && cd ..
fi

# Get Flutter dependencies
flutter pub get

# Get the first available iPhone simulator ID
SIMULATOR_ID=$(xcrun simctl list devices available | grep -i "iphone" | head -1 | grep -oE '[A-F0-9-]{36}' | head -1)

if [ -z "$SIMULATOR_ID" ]; then
    echo "⚠️  No iPhone simulators found. Please open Xcode and create one."
    echo "   Xcode → Window → Devices and Simulators → Simulators → +"
    exit 1
fi

# Check if simulator is already booted
BOOTED_SIMULATOR=$(xcrun simctl list devices | grep "$SIMULATOR_ID" | grep "Booted")

if [ -z "$BOOTED_SIMULATOR" ]; then
    echo ""
    echo "📱 Booting iPhone simulator ($SIMULATOR_ID)..."
    # Boot the simulator
    xcrun simctl boot "$SIMULATOR_ID" 2>/dev/null || true
    # Open Simulator app (this ensures it's visible and ready)
    open -a Simulator
    # Wait for simulator to fully boot and be ready
    echo "   Waiting for simulator to be ready..."
    sleep 8
else
    echo "✅ Simulator already running"
fi

# Wait a bit more for Flutter to detect the simulator
echo "   Checking Flutter device detection..."
sleep 3

# List available devices
echo ""
echo "Available devices:"
flutter devices

# Get the Flutter device ID for the simulator
FLUTTER_DEVICE_ID=$(flutter devices | grep -i "simulator" | grep -oE '[A-F0-9-]{36}' | head -1)

# Run on simulator
echo ""
echo "🚀 Launching app on iOS Simulator..."
if [ -n "$FLUTTER_DEVICE_ID" ]; then
    echo "   Using Flutter device ID: $FLUTTER_DEVICE_ID"
    flutter run -d "$FLUTTER_DEVICE_ID"
elif [ -n "$SIMULATOR_ID" ]; then
    echo "   Using simulator ID: $SIMULATOR_ID"
    flutter run -d "$SIMULATOR_ID"
else
    echo "   Auto-detecting device..."
    flutter run
fi

