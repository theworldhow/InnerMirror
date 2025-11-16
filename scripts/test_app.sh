#!/bin/bash

# Quick test script for InnerMirror app

set -e

echo "🧪 Testing InnerMirror App"
echo ""

# Check if app is running
echo "1. Checking if app is installed..."
if flutter devices | grep -q "simulator\|mobile"; then
    echo "   ✅ Device found"
else
    echo "   ❌ No device found. Starting simulator..."
    ./scripts/run_ios_simulator.sh &
    sleep 10
fi

echo ""
echo "2. Running app with verbose logging..."
echo "   Watch for errors in the output below:"
echo ""

# Run app and show errors
flutter run --verbose 2>&1 | tee /tmp/flutter_run.log | grep -E "error|Error|ERROR|exception|Exception|EXCEPTION|failed|Failed|FAILED" || echo "✅ No errors found in initial output"

echo ""
echo "3. App should now be running!"
echo ""
echo "Testing Checklist:"
echo "   [ ] App shows loading spinner (black screen with white spinner)"
echo "   [ ] Onboarding screen appears (if first launch)"
echo "   [ ] Can swipe through onboarding"
echo "   [ ] Main screen shows after onboarding"
echo "   [ ] Can see 5 mirror cards"
echo "   [ ] Can swipe between mirrors"
echo "   [ ] Floating '+' button works"
echo ""
echo "To view full logs: tail -f /tmp/flutter_run.log"
echo "To stop: Press Ctrl+C"

