# Quick Start: Capture App Store Screenshots

## 3-Step Process

### 1. Enable Screenshot Mode
```
1. Open app in iOS Simulator
2. Long press "INNERMIRROR" text (top-left) OR tap DEBUG button (top-right)
3. Tap "Screenshot Mode: ON" button
4. Go back to main screen
```

### 2. Navigate to Each Mirror Card
```
- Swipe left/right to navigate between cards
- Cards: Truth → Strength → Shadow → Growth → Legacy
- Each card will show sample content with blurred personal data
```

### 3. Capture Screenshots
```bash
# Option A: Automated script
./scripts/capture_screenshots.sh

# Option B: Manual (⌘ + S in Simulator)
# Press ⌘ + S for each card

# Option C: Command line
xcrun simctl io <DEVICE_UDID> screenshot screenshot.png
```

## What Screenshot Mode Does

✅ Shows sample content for all 5 mirror cards  
✅ Blurs personal data (names, dates, numbers, quotes)  
✅ Hides DEBUG button  
✅ Maintains structure and readability  
✅ Ready for App Store submission  

## Required Screenshot Sizes

- **iPhone 6.7"**: 1290 x 2796 (iPhone 14/15 Pro Max)
- **iPhone 6.5"**: 1242 x 2688 (iPhone 11 Pro Max, XS Max)
- **iPhone 5.5"**: 1242 x 2208 (iPhone 8 Plus)

**Tip**: Use different simulator devices to capture all sizes.

## Troubleshooting

**Cards not showing sample content?**
- Swipe to a different card and back
- Or restart the app after enabling screenshot mode

**Need to disable screenshot mode?**
- Go back to Debug screen
- Tap "Screenshot Mode: OFF"

