# Build Instructions for InnerMirror

## Prerequisites

### For iOS Builds (Mac only):
1. **Install Xcode** from the App Store (free, ~15GB)
2. **Install CocoaPods** (choose one method):
   ```bash
   # Option 1: Via Homebrew (recommended, no sudo needed)
   brew install cocoapods
   
   # Option 2: Via gem (requires sudo)
   sudo gem install cocoapods
   ```
3. **Setup Xcode**:
   ```bash
   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
   sudo xcodebuild -runFirstLaunch
   ```

### For Android Builds:
1. **Install Android Studio** from: https://developer.android.com/studio
2. **Install Android SDK** (Android Studio will guide you)
3. **Accept Android licenses**:
   ```bash
   flutter doctor --android-licenses
   ```

## Build Commands

### Android (Google Play)

```bash
# Build AAB (Android App Bundle)
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS (App Store)

**Option 1: Using Flutter (requires Xcode)**
```bash
# Build IPA
flutter build ipa --release

# Output: build/ios/ipa/innermirror.ipa
```

**Option 2: Using Xcode (recommended)**
```bash
# Open in Xcode
open ios/Runner.xcworkspace

# Then in Xcode:
# 1. Product > Archive
# 2. Window > Organizer
# 3. Distribute App > App Store Connect
```

## Quick Setup

### Install Xcode (for iOS):
```bash
# Install from App Store, then:
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch

# Install CocoaPods (via Homebrew - recommended):
brew install cocoapods
# OR via gem (if you prefer):
# sudo gem install cocoapods

# Install iOS dependencies:
cd ios && pod install && cd ..
```

### Install Android Studio (for Android):
1. Download from: https://developer.android.com/studio
2. Install Android SDK through Android Studio
3. Run: `flutter doctor --android-licenses`

## Current Status

Run `flutter doctor` to see what's installed:
```bash
flutter doctor
```

## Build Scripts

Use the provided scripts:
- `./scripts/build_android.sh` - Build Android AAB
- `./scripts/build_ios.sh` - Build iOS IPA (requires Xcode)

