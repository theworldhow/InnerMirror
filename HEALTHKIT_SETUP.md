# HealthKit Setup for iOS

## Problem
When running "Force Ingest Now", you may see this error:
```
Missing com.apple.developer.healthkit entitlement.
```

This happens because HealthKit requires explicit entitlement configuration in Xcode.

## Solution

### 1. Entitlements File Created
I've created `ios/Runner/Runner.entitlements` with HealthKit enabled.

### 2. Configure in Xcode

You need to link this entitlements file in your Xcode project:

1. **Open Xcode:**
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Select Runner Target:**
   - Click on "Runner" project in left sidebar
   - Select "Runner" target (not project)
   - Go to "Signing & Capabilities" tab

3. **Enable HealthKit Capability:**
   - Click "+ Capability" button
   - Search for "HealthKit"
   - Double-click to add HealthKit capability
   - This will automatically enable HealthKit in the entitlements

4. **Verify Entitlements File:**
   - Go to "Build Settings" tab
   - Search for "Code Signing Entitlements"
   - Should show: `Runner/Runner.entitlements`
   - If not, set it manually: `$(PRODUCT_NAME)/Runner.entitlements`

### 3. Alternative: Manual Entitlements Setup

If HealthKit capability doesn't appear, you can manually configure:

1. **In Xcode:**
   - Select Runner target
   - Build Settings tab
   - Search "Code Signing Entitlements"
   - Set to: `Runner/Runner.entitlements`

2. **Verify the entitlements file exists:**
   - File: `ios/Runner/Runner.entitlements`
   - Should contain:
   ```xml
   <key>com.apple.developer.healthkit</key>
   <true/>
   ```

### 4. Clean and Rebuild

After configuring:

```bash
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter clean
flutter pub get
flutter run
```

### 5. App Store Connect Configuration

**Important:** If you plan to submit to App Store:

1. HealthKit requires App Store review justification
2. Add HealthKit usage description in App Store Connect
3. Health data access is a sensitive permission

## Error Handling

The app now handles HealthKit errors gracefully:
- ✅ If HealthKit entitlement is missing → Logs error but continues with other ingestion
- ✅ If permission denied → Logs and continues
- ✅ If HealthKit unavailable → Continues with SMS, photos, location

The "Force Ingest Now" button will continue to work even if HealthKit fails.

## Testing

After setup:
1. Run "Force Ingest Now" in debug screen
2. Should not crash with entitlement error
3. If HealthKit enabled → Will request permission and ingest data
4. If HealthKit disabled → Will skip health data but continue other ingestion

## Notes

- **Simulator:** HealthKit may not work fully in simulator (use physical device for full testing)
- **Physical Device:** Requires proper code signing and entitlements
- **Permission:** User must grant Health data permission when prompted
- **Privacy:** Health data is sensitive - ensure proper privacy policy

