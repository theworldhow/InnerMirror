# InnerMirror Testing Guide.

## Quick Start Testing

### 1. Run on iOS Simulator
```bash
./scripts/run_ios_simulator.sh
```

### 2. Run on Android Emulator
```bash
# Start an Android emulator first, then:
flutter run
```

### 3. Run on Physical Device
```bash
# Connect device via USB, then:
flutter devices  # List available devices
flutter run -d <device-id>
```

## Testing Features

### First Launch Flow

1. **Onboarding Screen** (First time only)
   - You should see 3 onboarding screens
   - Swipe through them (dark, unsettling aesthetic)
   - Tap "Let the mirror see you" button on the last screen
   - This sets `onboarding_complete = true`
   - ✅ **Expected**: Smooth transitions, black background, minimal text

2. **Victory Screen** (After onboarding)
   - Shows: "The mirror is awake. There is nowhere left to hide."
   - Black background with centered text
   - Tap "Begin" button
   - This sets `has_seen_victory = true`
   - ✅ **Expected**: Dramatic, minimal design

3. **Main Screen** (After victory)
   - Should show the 5 mirror cards in horizontal PageView
   - Black background (#000000)
   - "INNERMIRROR" text top-left (gray, uppercase)
   - "You can't hide from you." tagline centered below branding
   - Page indicator dots at bottom (5 dots)
   - Floating "+" button bottom-right (white circle with glow)
   - Top-right indicators: "Soul awake ✓" (when model loaded) and "Memory: X moments"
   - ✅ **Expected**: All UI elements visible, smooth transitions

### Main Features to Test

#### 1. Mirror Cards (Swipe left/right)

**Testing Steps:**
- Swipe left/right through all 5 mirrors
- Watch page indicator dots update
- Feel for haptic feedback on each swipe
- Check each mirror displays correct content

**Mirrors:**
- **Truth Mirror** (Card 1) - Shows placeholder text
- **Strength Mirror** (Card 2) - Shows placeholder text
- **Shadow Mirror** (Card 3) - Shows placeholder text
- **Growth Mirror** (Card 4) - Shows placeholder text
- **Legacy Mirror** (Card 5) - Shows placeholder text (uses LLM stub when model is loaded)

**Expected Behavior:**
- ✅ Smooth page transitions
- ✅ Haptic feedback on each swipe (`HapticFeedback.selectionClick()`)
- ✅ Page indicator dots update correctly
- ✅ Breathing animation on black background when model is "thinking" (if implemented)
- ✅ Text appears with fade-in animation

**Special Test:**
- Tap "Mirrors" button in bottom nav when already on Mirrors tab
- ✅ Should scroll back to first mirror (Truth) with smooth animation

#### 2. Journal Button (+ button)

**Testing Steps:**
1. Tap the floating "+" button (bottom-right)
2. Should open full-screen journal modal
3. Test text input - type some text
4. Test voice-to-text button (if permissions granted)
5. Test save functionality
6. Close journal and verify entry is saved

**Expected Behavior:**
- ✅ Full-screen journal opens with dark theme
- ✅ Text input field works
- ✅ Voice-to-text button appears (if microphone permission granted)
- ✅ Can save journal entries
- ✅ Journal closes properly

**Permission Testing:**
- Deny microphone permission - voice button should handle gracefully
- Grant microphone permission - voice-to-text should work

#### 3. Bottom Navigation

**Testing Steps:**
1. Tap "Mirrors" tab (left) - should show mirror cards
2. Tap "Vault" tab (middle, lock icon) - should show Secrets Vault
3. Tap "Future You" tab (right, voice icon) - should show Future You messages
4. Navigate between tabs multiple times
5. Test back buttons on Vault and Future You screens

**Expected Behavior:**
- ✅ **Mirrors tab** (default, index 0):
  - Shows 5 mirror cards in PageView
  - Tapping while already on Mirrors resets to first card
  
- ✅ **Vault tab** (index 1, lock icon):
  - Shows Secrets Vault screen
  - Back button in AppBar returns to Mirrors
  - Biometric authentication prompt appears
  
- ✅ **Future You tab** (index 2, voice icon):
  - Shows Future You messages list
  - Back button in AppBar returns to Mirrors
  - Can tap messages to play

**Visual Checks:**
- ✅ Selected tab highlighted in white
- ✅ Unselected tabs gray
- ✅ Icons display correctly (auto_awesome, lock, record_voice_over)

#### 4. Secrets Vault

**Testing Steps:**

1. **Initial State:**
   - Tap Vault tab in bottom navigation
   - ✅ Should show lock screen with "Unlock Vault" button

2. **Biometric Authentication:**
   - Tap "Unlock Vault" button
   - ✅ Face ID/Touch ID prompt should appear
   - Test successful authentication - vault should unlock
   - Test failed authentication (cancel) - vault stays locked
   - Test password fallback - after 2 failed Face ID attempts, password option should appear
   - ✅ Enter device password - vault should unlock

3. **When Unlocked:**
   - ✅ Should show empty state or list of secrets
   - ✅ Can add new secrets (text or voice)
   - ✅ Can view existing secrets
   - ✅ Back button returns to Mirrors tab

4. **Add Secret:**
   - Tap to add secret
   - Enter text or record voice
   - Save secret
   - ✅ Secret should appear in list
   - ✅ Should be sorted by most recent first

5. **Burn Day (December 31st):**
   - If it's December 31st, special dialog should appear
   - Tests "Burn Day" functionality
   - ✅ All secrets deleted permanently

**Expected Behavior:**
- ✅ Biometric auth works with Face ID/Touch ID
- ✅ Password fallback works after 2 failed attempts
- ✅ Secrets stored securely in file storage
- ✅ No crashes when unlocking (biometric or password)
- ✅ Smooth animations and transitions

#### 5. Future You Messages

**Testing Steps:**

1. **Initial State:**
   - Tap "Future You" tab in bottom navigation
   - ✅ Should show list of Future You voice messages (or empty state)

2. **Message List:**
   - ✅ Shows last 10 messages
   - ✅ Each message shows date/time
   - ✅ Can tap to play message

3. **Message Playback:**
   - Tap a message to play
   - ✅ Full-screen playback screen appears
   - ✅ Waveform visualization (or placeholder)
   - ✅ Play/pause controls
   - ✅ Message starts with "Hey 2025 me —"
   - ✅ Message ends with "Trust the muscle memory."

4. **Back Navigation:**
   - ✅ Back button returns to message list
   - ✅ Can navigate back to Mirrors tab

**Expected Behavior:**
- ✅ Messages generated every Sunday at 8:00 AM (test manually)
- ✅ Last 10 messages saved and accessible
- ✅ Playback works smoothly
- ✅ Dark aesthetic maintained

#### 6. Debug Screen

**Access:**
- Shake device **twice quickly** (within 2 seconds)
- ✅ Should open debug screen as full-screen dialog

**What to Test:**

1. **Information Display:**
   - ✅ Last ingestion time (or "Never" if not ingested)
   - ✅ Total moments count
   - ✅ Last 10 raw entries from `life_log.jsonl`

2. **Action Buttons:**
   - **"Force Ingest Now"**: Triggers data ingestion immediately
     - ✅ Should show progress
     - ✅ Memory counter should update after completion
     
   - **"Regenerate Mirrors Now"**: Triggers mirror generation
     - ✅ Should refresh all 5 mirrors
     - ✅ Mirrors should update with new content
     
   - **"Legacy Export"** ($99 paywall): Opens RevenueCat purchase flow
     - ✅ Should show purchase dialog
     - ✅ Behind paywall (requires RevenueCat setup)

3. **Raw Entries Display:**
   - ✅ Shows last 10 entries in JSON format
   - ✅ Scrollable if many entries
   - ✅ Helps verify data ingestion worked

**Expected Behavior:**
- ✅ Debug screen opens reliably on double shake
- ✅ All buttons work
- ✅ Data displays correctly
- ✅ Can close debug screen

### Testing Data Ingestion

**Testing Steps:**

1. **Force Data Ingestion:**
   - Shake device twice → Debug screen
   - Tap "Force Ingest Now"
   - ✅ Wait for completion (may take a few seconds)
   - ✅ Check "Total Moments" count increases in debug screen
   - ✅ Check top-right "Memory: X moments" updates on main screen

2. **Check Memory Counter:**
   - Top-right corner should show "Memory: X moments"
   - ✅ Format: "Memory: 1,234 moments" (with comma formatting)
   - ✅ Updates after ingestion
   - ✅ Persists across app restarts

3. **Verify Data Storage:**
   - Data stored in `/innermirror/memory/life_log.jsonl`
   - ✅ Check debug screen shows recent entries
   - ✅ Entries should be valid JSON

**Data Sources Ingested:**
- SMS/Messages (last 60 days + new ones)
- Photos (with face clustering analysis)
- Screen time per app
- Health data (HRV, sleep, steps)
- Location history (significant places)

**Expected Behavior:**
- ✅ Ingestion completes without crashing
- ✅ Memory counter updates
- ✅ Debug screen shows new entries
- ✅ Data persists

### Testing Model Download

**Testing Steps:**

1. **First Launch (No Model):**
   - If model doesn't exist, download screen should appear
   - ✅ Shows: "Waking your Soul Model… this takes 3–7 minutes the first time"
   - ✅ Black background with white progress ring
   - ✅ Progress indicator updates
   - ✅ Can cancel download (optional)

2. **After Download:**
   - ✅ Top-right should show "Soul awake ✓" indicator
   - ✅ Legacy Mirror should use model for generation (currently stubbed)
   - ✅ Model state changes from `downloading` → `ready`

3. **Model States:**
   - `notInitialized` → Initial state
   - `downloading` → During download
   - `loading` → Loading model into memory
   - `ready` → Model ready for inference
   - `sleeping` → Model unloaded (memory management)
   - `generating` → Currently generating response
   - `error` → Error state with message

**Note:** Currently using `mllama_stub.dart` for simulated responses. Real inference will work when `mllama_flutter` package is integrated.

**Expected Behavior:**
- ✅ Download screen appears when model missing
- ✅ Progress updates smoothly
- ✅ "Soul awake ✓" appears after model loads
- ✅ Legacy Mirror generates responses (stubbed currently)

### Testing Permissions

**Required Permissions:**

The app needs these permissions (grant when prompted):

- **Microphone** (`NSMicrophoneUsageDescription`)
  - For voice-to-text journaling
  - ✅ Test: Journal → Voice button → Should request permission

- **Photos** (`NSPhotoLibraryUsageDescription`)
  - For photo ingestion
  - ✅ Test: Data ingestion → Should access photos if permission granted

- **Health** (`NSHealthShareUsageDescription`, iOS only)
  - For health data (HRV, sleep, steps)
  - ✅ Test: Data ingestion → Should access health data if permission granted

- **Location** (`NSLocationWhenInUseUsageDescription`)
  - For location history
  - ✅ Test: Data ingestion → Should access location if permission granted

- **SMS** (Android only)
  - For message ingestion
  - ✅ Test: Data ingestion → Should access SMS if permission granted

- **Face ID** (`NSFaceIDUsageDescription`, iOS)
  - For Secrets Vault authentication
  - ✅ Test: Vault → Unlock → Should show Face ID prompt

**Permission Testing:**
- ✅ Grant all permissions - app should work fully
- ✅ Deny some permissions - app should handle gracefully
- ✅ Test permission re-request flow

### Testing UI/UX Details

#### Visual Elements
- ✅ **Haptic Feedback**: Should feel vibration on mirror swipe
- ✅ **Breathing Animation**: Subtle animation when model is "thinking"
- ✅ **Fade-in Animations**: Text appears with fade-in effect
- ✅ **Smooth Transitions**: All screen transitions should be smooth
- ✅ **Loading States**: Show appropriate loading indicators

#### Responsiveness
- ✅ All screens work in portrait mode
- ✅ Text is readable at all screen sizes
- ✅ Buttons are tappable (minimum 44x44 points)
- ✅ Scrolling works smoothly

#### Dark Mode
- ✅ Pure black background (#000000) everywhere
- ✅ White/gray text on black
- ✅ Icons visible and clear
- ✅ No light mode (dark mode only)

### Common Issues & Fixes

#### White Screen
- **Cause:** App is loading or determining which screen to show
- **Fix:** Wait a few seconds, or restart the app
- **If persists:** Check console for errors

#### App Crashes on Launch
- Check console logs: `flutter run` will show errors
- Common causes:
  - Missing `NSFaceIDUsageDescription` in `Info.plist` (iOS)
  - Service initialization errors
  - Provider errors
  - Background task initialization failures (non-critical)

#### Secrets Vault Crash
- **Fixed:** Removed sqflite, using file storage instead
- **If still crashes:** Check biometric permissions in `Info.plist`
- ✅ Should now work reliably with Face ID/password fallback

#### Mirrors Show Placeholder Text
- **Normal:** Mirrors use placeholder text until:
  1. Data is ingested (`life_log.jsonl` has entries)
  2. Model is downloaded and initialized
  3. Mirrors are generated (happens at 8 AM or manually in debug)
- **Test:** Use debug screen → "Regenerate Mirrors Now"

#### Debug Screen Not Opening
- Make sure you shake **twice quickly** (within 2 seconds)
- Try shaking harder
- Check that shake detection is enabled
- ✅ Should work reliably with delayed initialization

#### Mirrors Button Not Working
- **Fixed:** Now resets to first card when tapped while on Mirrors tab
- ✅ Should animate smoothly to first mirror

#### Bottom Navigation Not Working
- Check that all three tabs are functional
- Verify tab switching works
- Test back buttons on Vault and Future You screens
- ✅ All should work smoothly

### Manual Testing Checklist

#### First Launch
- [ ] App launches without crashing
- [ ] Loading spinner appears briefly
- [ ] Onboarding screens appear (3 screens)
- [ ] Can complete onboarding (tap "Let the mirror see you")
- [ ] Victory screen appears after onboarding
- [ ] Can tap "Begin" on victory screen
- [ ] Main screen shows after victory

#### Main Screen
- [ ] All UI elements visible (branding, tagline, indicators, buttons)
- [ ] Can swipe between 5 mirror cards
- [ ] Page indicator dots update correctly
- [ ] Haptic feedback on mirror swipe
- [ ] "Soul awake ✓" appears when model loaded
- [ ] "Memory: X moments" displays correctly
- [ ] Floating "+" button visible and tappable
- [ ] Bottom navigation visible (3 tabs)

#### Journal
- [ ] Floating "+" button opens journal
- [ ] Journal accepts text input
- [ ] Voice-to-text button appears (if permission granted)
- [ ] Can save journal entries
- [ ] Journal closes properly

#### Bottom Navigation
- [ ] Mirrors tab works (shows mirror cards)
- [ ] Tapping Mirrors while on Mirrors resets to first card
- [ ] Vault tab opens Secrets Vault
- [ ] Future You tab opens Future You messages
- [ ] Back buttons work on Vault and Future You screens

#### Secrets Vault
- [ ] Unlock button appears
- [ ] Face ID/Touch ID prompt appears
- [ ] Biometric authentication works
- [ ] Password fallback works after 2 failed attempts
- [ ] Vault unlocks after successful authentication
- [ ] Can add text secrets
- [ ] Can add voice secrets
- [ ] Secrets display correctly
- [ ] Back button returns to Mirrors

#### Future You Messages
- [ ] Message list displays (or empty state)
- [ ] Can tap messages to play
- [ ] Playback screen appears
- [ ] Audio playback works
- [ ] Back button returns to list

#### Debug Screen
- [ ] Shake twice opens debug screen
- [ ] All information displays correctly
- [ ] "Force Ingest Now" works
- [ ] "Regenerate Mirrors Now" works
- [ ] "Legacy Export" opens purchase flow
- [ ] Last 10 entries display correctly
- [ ] Can close debug screen

#### Data Ingestion
- [ ] Force ingestion completes
- [ ] Memory counter updates
- [ ] Debug screen shows new entries
- [ ] Data persists across app restarts

#### Model Download
- [ ] Download screen appears if model missing
- [ ] Progress updates correctly
- [ ] "Soul awake ✓" appears after download
- [ ] Legacy Mirror uses model (stubbed currently)

### Testing Commands

```bash
# Run with verbose logging
flutter run --verbose

# Run with hot reload enabled
flutter run

# Check for errors
flutter analyze

# View logs
flutter logs

# Run on specific device
flutter devices  # List available devices
flutter run -d <device-id>

# Build for release
./scripts/build_ios.sh    # iOS
./scripts/build_android.sh  # Android

# Test script
./scripts/test_app.sh
```

### Reset App State

To test onboarding flow again:

**iOS:**
```bash
# Uninstall app
xcrun simctl uninstall booted com.innermirror.innermirror

# Or reset simulator
xcrun simctl erase all
```

**Android:**
```bash
# Uninstall app
adb uninstall com.innermirror.innermirror

# Or clear app data
adb shell pm clear com.innermirror.innermirror
```

### Viewing Logs

```bash
# iOS Simulator logs
xcrun simctl spawn booted log stream --predicate 'processImagePath contains "Runner"'

# Android logs
adb logcat | grep flutter

# Flutter logs
flutter logs

# Filter for errors only
flutter run --verbose 2>&1 | grep -i "error\|exception\|crash"
```

## Expected Behavior

### First Launch:
1. Loading spinner (black screen with white spinner)
2. Onboarding screen (3 pages, dark aesthetic)
3. Victory screen ("The mirror is awake...")
4. Main screen with 5 mirrors

### Subsequent Launches:
1. Loading spinner (brief)
2. Main screen with 5 mirrors (last viewed mirror)

### Error Scenarios:
- Background task initialization fails → App still works (non-critical)
- Share extension unavailable → App still works (non-critical)
- Shake detection fails → App still works (non-critical)
- Model download fails → Shows error state, can retry

## Platform-Specific Testing

### iOS Testing
- ✅ Test on iOS Simulator (various iPhone models)
- ✅ Test on physical iPhone (Face ID required for Vault)
- ✅ Test biometric authentication
- ✅ Test Health data access
- ✅ Test background fetch
- ✅ Verify `Info.plist` permissions

### Android Testing
- ✅ Test on Android Emulator
- ✅ Test on physical Android device
- ✅ Test WorkManager background tasks
- ✅ Test SMS access (Android only)
- ✅ Test Google Fit integration
- ✅ Verify `AndroidManifest.xml` permissions

## Performance Testing

### Memory Usage
- ✅ Monitor memory during model download
- ✅ Check memory after model loads
- ✅ Monitor during data ingestion
- ✅ Verify no memory leaks

### Startup Time
- ✅ First launch: < 3 seconds to onboarding
- ✅ Subsequent launches: < 1 second to main screen
- ✅ Model initialization: Should not block UI

### Smoothness
- ✅ 60 FPS during mirror swipes
- ✅ Smooth page transitions
- ✅ No jank during animations
- ✅ Fast tab switching

---

**Testing Tips:**
- Always test on both simulator and physical device
- Test with and without permissions granted
- Test with various data states (empty, populated)
- Test error scenarios (network issues, etc.)
- Use debug screen to verify data ingestion
- Check console logs for any warnings or errors
