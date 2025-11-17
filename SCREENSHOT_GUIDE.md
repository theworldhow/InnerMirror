# App Store Screenshot Guide

This guide explains how to capture App Store screenshots for InnerMirror.

## Screenshot Requirements

### Required Sizes
- **iPhone 6.7"** (iPhone 14 Pro Max, 15 Pro Max): 1290 x 2796 pixels
- **iPhone 6.5"** (iPhone 11 Pro Max, XS Max): 1242 x 2688 pixels  
- **iPhone 5.5"** (iPhone 8 Plus): 1242 x 2208 pixels

### Guidelines
- ✅ Pure black background (#000000)
- ✅ Show mirror cards with text blurred just enough to pass review
- ✅ White text on black
- ✅ Minimal, luxurious aesthetic
- ✅ No personal data visible
- ✅ Use real generated content (blur sensitive parts)

## Method 1: Automated Script

1. **Start iOS Simulator**
   ```bash
   open -a Simulator
   ```

2. **Select appropriate device size**
   - Device > Window > Physical Size
   - Or use iPhone 14 Pro Max (6.7"), iPhone 11 Pro Max (6.5"), or iPhone 8 Plus (5.5")

3. **Run the app**
   ```bash
   flutter run
   ```

4. **Enable Screenshot Mode**
   - Open Debug screen (long press "INNERMIRROR" text or tap DEBUG button)
   - Tap "Screenshot Mode: ON" button
   - You'll be returned to main screen with sample content and blurring

5. **Capture screenshots**
   ```bash
   ./scripts/capture_screenshots.sh
   ```
   - Follow the prompts to capture each mirror card
   - Screenshots will be saved to `screenshots/` directory

## Method 2: Manual Capture

1. **Enable Screenshot Mode** (same as above)

2. **Navigate to each mirror card**
   - Swipe left/right to navigate between cards
   - Cards: Truth → Strength → Shadow → Growth → Legacy

3. **Capture screenshots**
   - **Option A**: Use Xcode
     - Xcode > Open Developer Tool > Simulator
     - Device > Screenshot
   
   - **Option B**: Use command line
     ```bash
     # Get device UDID
     xcrun simctl list devices | grep Booted
     
     # Capture screenshot
     xcrun simctl io <DEVICE_UDID> screenshot screenshot.png
     ```
   
   - **Option C**: Use macOS screenshot (⌘ + S in Simulator)
     - Press ⌘ + S in Simulator window
     - Screenshot saved to Desktop

4. **Organize screenshots**
   - Name them: `01-truth-mirror.png`, `02-strength-mirror.png`, etc.
   - Save to `screenshots/` directory

## Screenshot Mode Features

When Screenshot Mode is enabled:
- ✅ Shows sample content for each mirror card
- ✅ Automatically blurs personal data (names, dates, numbers, quotes)
- ✅ Maintains structure and readability
- ✅ Shows "Updated 2 hours ago" timestamp
- ✅ All 5 mirror cards have sample content ready

## Recommended Screenshots

### Primary Screenshots (Required)
1. **Truth Mirror** - First card, shows the core concept
2. **Strength Mirror** - Demonstrates positive insights
3. **Shadow Mirror** - Shows self-awareness features
4. **Growth Mirror** - Highlights progress tracking
5. **Legacy Mirror** - Final card, shows long-term perspective

### Optional Screenshots
- Main screen with page indicators showing multiple cards
- Journal entry screen (if applicable)
- Secrets Vault screen (with blurred content)

## Tips

1. **Use Physical Size**: Set simulator to "Physical Size" to get accurate dimensions
2. **Hide Debug Elements**: Screenshot mode hides DEBUG button automatically
3. **Consistent Lighting**: Ensure simulator is in light mode (though app is dark)
4. **Clean State**: Restart app before capturing to ensure clean UI
5. **Multiple Sizes**: Capture all required sizes for App Store submission

## Post-Processing

After capturing:
1. Verify dimensions match requirements
2. Check that all personal data is blurred
3. Ensure black background is pure #000000
4. Verify text is readable but not revealing
5. Crop to exact dimensions if needed

## Troubleshooting

**Screenshot Mode not working?**
- Make sure you're in debug mode
- Restart the app after enabling screenshot mode
- Check that you tapped the button correctly

**Screenshots too small/large?**
- Change simulator device size
- Use "Physical Size" in Device > Window menu
- Verify simulator is set to 100% scale

**Blur not working?**
- Screenshot mode uses text replacement, not visual blur
- Personal data (names, dates, numbers) should be replaced with • symbols
- This is intentional to pass App Store review

