#!/bin/bash

# Capture iOS App Store screenshots from simulator
# Usage: ./scripts/capture_screenshots.sh

set -e

cd "$(dirname "$0")/.."

# Create screenshots directory
SCREENSHOTS_DIR="screenshots"
mkdir -p "$SCREENSHOTS_DIR"

echo "📸 InnerMirror Screenshot Capture"
echo "=================================="
echo ""

# Check if simulator is running
if ! xcrun simctl list devices | grep -q "Booted"; then
    echo "❌ No iOS simulator is running."
    echo "   Please start a simulator first:"
    echo "   open -a Simulator"
    echo ""
    exit 1
fi

# Get booted device UDID
DEVICE_UDID=$(xcrun simctl list devices | grep "Booted" | head -1 | grep -oE '[A-F0-9-]{36}' | head -1)

if [ -z "$DEVICE_UDID" ]; then
    echo "❌ Could not find booted simulator device."
    exit 1
fi

echo "✅ Found booted simulator: $DEVICE_UDID"
echo ""

# Instructions
echo "📋 Instructions:"
echo "   1. Open the app in the simulator"
echo "   2. Open Debug screen (long press 'INNERMIRROR' or tap DEBUG button)"
echo "   3. Toggle 'Screenshot Mode: ON'"
echo "   4. Navigate to each mirror card (swipe left/right)"
echo "   5. Press Enter here to capture screenshots"
echo ""
read -p "Press Enter when ready to capture screenshots..."

# Capture screenshots for each mirror card
echo ""
echo "📸 Capturing screenshots..."

# Screenshot 1: Truth Mirror (first card)
echo "   • Truth Mirror..."
xcrun simctl io "$DEVICE_UDID" screenshot "$SCREENSHOTS_DIR/01-truth-mirror.png" 2>/dev/null || {
    echo "   ⚠️  Using alternative method..."
    screencapture -x "$SCREENSHOTS_DIR/01-truth-mirror.png" 2>/dev/null || echo "   ❌ Failed to capture Truth Mirror"
}

sleep 1

# Note: User needs to swipe to other cards manually
echo ""
echo "✅ Screenshot 1 captured: Truth Mirror"
echo ""
echo "📋 Next steps:"
echo "   1. Swipe left to Strength Mirror"
echo "   2. Press Enter to capture..."
read -p ""

echo "   • Strength Mirror..."
xcrun simctl io "$DEVICE_UDID" screenshot "$SCREENSHOTS_DIR/02-strength-mirror.png" 2>/dev/null || {
    screencapture -x "$SCREENSHOTS_DIR/02-strength-mirror.png" 2>/dev/null || echo "   ❌ Failed to capture Strength Mirror"
}

sleep 1

echo ""
echo "✅ Screenshot 2 captured: Strength Mirror"
echo ""
echo "📋 Next steps:"
echo "   1. Swipe left to Shadow Mirror"
echo "   2. Press Enter to capture..."
read -p ""

echo "   • Shadow Mirror..."
xcrun simctl io "$DEVICE_UDID" screenshot "$SCREENSHOTS_DIR/03-shadow-mirror.png" 2>/dev/null || {
    screencapture -x "$SCREENSHOTS_DIR/03-shadow-mirror.png" 2>/dev/null || echo "   ❌ Failed to capture Shadow Mirror"
}

sleep 1

echo ""
echo "✅ Screenshot 3 captured: Shadow Mirror"
echo ""
echo "📋 Next steps:"
echo "   1. Swipe left to Growth Mirror"
echo "   2. Press Enter to capture..."
read -p ""

echo "   • Growth Mirror..."
xcrun simctl io "$DEVICE_UDID" screenshot "$SCREENSHOTS_DIR/04-growth-mirror.png" 2>/dev/null || {
    screencapture -x "$SCREENSHOTS_DIR/04-growth-mirror.png" 2>/dev/null || echo "   ❌ Failed to capture Growth Mirror"
}

sleep 1

echo ""
echo "✅ Screenshot 4 captured: Growth Mirror"
echo ""
echo "📋 Next steps:"
echo "   1. Swipe left to Legacy Mirror"
echo "   2. Press Enter to capture..."
read -p ""

echo "   • Legacy Mirror..."
xcrun simctl io "$DEVICE_UDID" screenshot "$SCREENSHOTS_DIR/05-legacy-mirror.png" 2>/dev/null || {
    screencapture -x "$SCREENSHOTS_DIR/05-legacy-mirror.png" 2>/dev/null || echo "   ❌ Failed to capture Legacy Mirror"
}

echo ""
echo "✅ All screenshots captured!"
echo ""
echo "📁 Screenshots saved to: $SCREENSHOTS_DIR/"
echo ""
echo "📋 App Store Requirements:"
echo "   • iPhone 6.7\" (iPhone 14 Pro Max, 15 Pro Max): 1290 x 2796"
echo "   • iPhone 6.5\" (iPhone 11 Pro Max, XS Max): 1242 x 2688"
echo "   • iPhone 5.5\" (iPhone 8 Plus): 1242 x 2208"
echo ""
echo "💡 Tip: Use different simulator sizes to capture all required sizes"
echo "   Device > Window > Physical Size (or use different simulators)"
echo ""

