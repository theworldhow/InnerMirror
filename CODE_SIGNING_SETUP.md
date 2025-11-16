# iOS Code Signing Setup Guide

## Quick Start: Run on Simulator (No Signing Required)

The easiest way to test your app without code signing:

```bash
# Run on iOS Simulator (no code signing needed)
# This script will automatically boot a simulator if needed
./scripts/run_ios_simulator.sh

# Or manually:
# 1. Boot a simulator:
xcrun simctl boot "iPhone 17 Pro"

# 2. Run the app:
flutter run -d ios
```

## For Device Deployment or App Store

You need code signing for:
- Running on a physical iPhone/iPad
- Building for TestFlight
- Submitting to App Store

### Option 1: Free Apple ID (Personal Team)

Works for testing on your own device, but **not** for App Store submission.

1. **Open Xcode:**
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Select Runner project** in the left sidebar

3. **Select Runner target** → **Signing & Capabilities** tab

4. **Check "Automatically manage signing"**

5. **Select your Team:**
   - Click the Team dropdown
   - Sign in with your Apple ID (free)
   - Xcode will create a free "Personal Team" certificate

6. **Change Bundle Identifier** (if needed):
   - Bundle ID: `com.innermirror.innermirror` might be taken
   - Change to something unique like: `com.yourname.innermirror`

7. **Build and run:**
   ```bash
   flutter run -d <your-device-id>
   ```

### Option 2: Apple Developer Account ($99/year)

Required for:
- App Store submission
- TestFlight distribution
- Advanced capabilities (Push Notifications, etc.)

1. **Sign up:** https://developer.apple.com/programs/

2. **Open Xcode:**
   ```bash
   open ios/Runner.xcworkspace
   ```

3. **Select Runner project** → **Runner target** → **Signing & Capabilities**

4. **Select your Developer Team** (not Personal Team)

5. **Xcode will automatically:**
   - Create certificates
   - Generate provisioning profiles
   - Configure signing

6. **Build for App Store:**
   ```bash
   flutter build ipa --release
   ```

## Troubleshooting

### "No valid code signing certificates were found"

**Solution:** Set up signing in Xcode (see Option 1 or 2 above)

### "Bundle identifier is already in use"

**Solution:** Change the Bundle ID in Xcode:
1. Runner project → Runner target → General
2. Change "Bundle Identifier" to something unique
3. Example: `com.yourname.innermirror`

### "Development team not selected"

**Solution:**
1. Open Xcode: `open ios/Runner.xcworkspace`
2. Runner → Signing & Capabilities
3. Select a Team from the dropdown
4. Sign in with Apple ID if needed

### "Provisioning profile doesn't match"

**Solution:**
1. In Xcode, uncheck "Automatically manage signing"
2. Check it again
3. Xcode will regenerate the profile

## Current Bundle ID

Your app's Bundle ID is: `com.innermirror.innermirror`

If this is already taken, change it in Xcode:
- Runner project → Runner target → General → Bundle Identifier

## Next Steps

- **Testing:** Use simulator (no signing needed)
- **Device testing:** Use free Apple ID (Option 1)
- **App Store:** Need paid Developer account (Option 2)

