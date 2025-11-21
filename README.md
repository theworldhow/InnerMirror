# InnerMirror

A minimal, luxurious journaling app with mirror cards for self-reflection. **The mirror that reflects your authentic self.**

> "You can hide from everyone. You can't hide from you."

## Features

### Core Mirrors
- **5 Mirror Cards**: Truth, Strength, Shadow, Growth, Legacy
- Horizontal swipe navigation with page indicators
- Dark aesthetic with minimal, luxurious design
- Haptic feedback on mirror swipes
- **NLP-based mirror generation**: Rule-based insights from all your data sources
- Page indicator automatically resets when navigating back from other screens

### Journaling
- Full-screen journal with text input
- Voice-to-text support (requires microphone permission)
- Floating "+" button for quick access
- Journal entries stored locally
- Voice journaling with speech recognition

### Secrets Vault
- Biometric authentication (Face ID/Touch ID with password fallback)
- Secure storage of voice and text secrets
- Encrypted local file storage using Flutter Secure Storage
- "Burn Day" functionality (December 31st - all secrets deleted)
- Biometric unlock with graceful fallback

### Future You Messages
- Voice messages from "Future You 2035"
- Generated every Sunday at 8:00 AM
- Playback with waveform visualization
- Last 10 messages saved for replay
- NLP-based message generation from your data

### Data Ingestion & Memory
- Automatic nightly background data ingestion
- **Comprehensive data tracking**:
  - Photos & videos (metadata only)
  - Health data (steps, workouts, sleep, heart rate, mindfulness)
  - Location (when in use)
  - Calendar events & reminders
  - Contacts (for social pattern analysis)
  - Microphone & speech recognition (for journaling)
  - App usage patterns
- Stores data in `life_log.jsonl`
- "Memory: X moments" counter
- Debug screen (shake device twice) to view ingestion stats

### Onboarding & UX
- Comprehensive onboarding flow with permission requests
- All permissions requested sequentially on first launch
- Victory screen on first successful launch
- Bottom navigation: Mirrors, Vault, Future You
- "Soul awake" status indicator (top-center)
- Tagline: "You can't hide from you."
- Page indicators positioned between tagline and mirror card title

### Technical Features
- **State Management**: Riverpod 2.5+ for reactive state
- **Background Tasks**: WorkManager (Android), BackgroundFetch (iOS)
- **NLP-based Generation**: Rule-based pattern analysis - no LLM required
- **100% On-device**: No servers, no uploads, all data stays on device
- **Completely Free**: No accounts, no purchases, no subscriptions - all features available
- **Privacy-first**: All data processing happens locally

## Project Structure

```
lib/
  ├── main.dart                    # App entry point, onboarding flow
  ├── screens/
  │   ├── main_screen.dart         # Main screen with mirror cards
  │   ├── journal_screen.dart      # Journaling interface
  │   ├── secrets_vault_screen.dart # Secrets vault with biometric auth
  │   ├── future_you_messages_screen.dart # Future You messages list
  │   ├── future_you_voice_screen.dart    # Message playback
  │   ├── onboarding_screen.dart   # First-time onboarding & permissions
  │   ├── victory_screen.dart      # Victory message on launch
  │   ├── debug_screen.dart        # Debug screen (shake to open)
  │   └── mirror_cards/
  │       ├── truth_card.dart      # Truth Mirror
  │       ├── strength_card.dart   # Strength Mirror
  │       ├── shadow_card.dart     # Shadow Mirror
  │       ├── growth_card.dart     # Growth Mirror
  │       └── legacy_card.dart     # Legacy Mirror
  ├── services/
  │   ├── simple_nlp_service.dart  # NLP-based mirror generation (rule-based)
  │   ├── soul_model_service.dart  # Stub service (always ready - no LLM)
  │   ├── secrets_vault_service.dart  # Secrets vault storage
  │   ├── data_ingestion_service.dart # Background data ingestion
  │   ├── background_task_service.dart # Background task scheduling
  │   ├── future_you_voice_service.dart # Future You message generation
  │   ├── mirror_generation_service.dart # Mirror generation orchestration
  │   ├── legacy_export_service.dart # Legacy export functionality
  │   ├── permission_service.dart  # Permission management
  │   └── ... (other services)
  ├── providers/
  │   ├── soul_model_provider.dart # Model state provider (stub)
  │   ├── memory_provider.dart     # Memory moments provider
  │   └── journal_provider.dart    # Journal entries provider
  └── widgets/
      ├── page_indicator.dart      # Page dots indicator
      ├── floating_add_button.dart # Floating journal button
      ├── breathing_background.dart # Breathing animation
      └── regret_simulator_overlay.dart # Regret simulator UI
```

## Setup

### Prerequisites
- Flutter 3.24+ with null safety
- Dart SDK >= 3.0.0
- Xcode (for iOS development)
- Android Studio (for Android development)
- CocoaPods (for iOS)

### Installation

1. **Clone the repository**
```bash
git clone <repository-url>
cd InnerMirror
```

2. **Install Flutter dependencies**
```bash
flutter pub get
```

3. **iOS Setup**
```bash
cd ios
pod install
cd ..
```

4. **Clean build (if needed)**
```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..
```

## Running the App

### iOS Simulator
```bash
flutter run
```

### Android Emulator
```bash
# Start emulator first, then:
flutter run
```

### Physical Device
```bash
flutter devices  # List available devices
flutter run -d <device-id>
```

## Building for Release

### iOS (IPA)
```bash
flutter build ios --release
# Then open ios/Runner.xcworkspace in Xcode
# Product → Archive → Distribute App
```

### Android (AAB)
```bash
flutter build appbundle --release
```

## Permissions

The app requires these permissions (configured in `ios/Runner/Info.plist` for iOS):

| Permission | Key | Purpose |
|------------|-----|---------|
| **Face ID** | `NSFaceIDUsageDescription` | Secrets vault authentication |
| **Health (Read)** | `NSHealthShareUsageDescription` | Health data analysis |
| **Health (Write)** | `NSHealthUpdateUsageDescription` | Health data analysis |
| **Location** | `NSLocationWhenInUseUsageDescription` | Location pattern analysis |
| **Photos** | `NSPhotoLibraryUsageDescription` | Photo metadata analysis |
| **Contacts** | `NSContactsUsageDescription` | Social pattern analysis |
| **Microphone** | `NSMicrophoneUsageDescription` | Voice journaling |
| **Speech Recognition** | `NSSpeechRecognitionUsageDescription` | Voice-to-text journaling |
| **Calendar** | `NSCalendarsUsageDescription` | Schedule pattern analysis |
| **Reminders** | `NSRemindersUsageDescription` | Task pattern analysis |

**All permissions are optional** - the app works with reduced functionality if permissions are denied.

## Features Status

### ✅ Implemented
- All 5 mirror cards with NLP-based content generation
- Journal with voice-to-text support
- Secrets Vault with biometric auth
- Future You messages with NLP-based generation
- Onboarding flow with sequential permission requests
- Victory screen on first launch
- Debug screen (shake twice to open)
- Background task framework
- Comprehensive data ingestion from multiple sources
- Memory counter
- Bottom navigation (Mirrors, Vault, Future You)
- Legacy export functionality (free)
- Page indicator with automatic reset
- "Soul awake" status indicator

### 🔧 How It Works
- **Mirror Generation**: Uses rule-based NLP analysis of all ingested data
- **No LLM Required**: Lightweight, fast, and privacy-first approach
- **Pattern Analysis**: Analyzes patterns across photos, health, location, calendar, contacts, etc.
- **Data Integration**: All data sources contribute to mirror insights
- **On-device Only**: All processing happens locally - no cloud services

### 📋 Future Enhancements
- Enhanced NLP rules for more nuanced insights
- Additional data source integration
- Push notifications for Future You messages
- Share extension for Regret Simulator
- Legacy export encryption

## Debug Features

### Debug Screen
Shake your device **twice quickly** (within 2 seconds) to open the debug screen. Shows:
- Last ingestion time
- Total moments count
- Last 10 raw entries from `life_log.jsonl`
- "Force ingest now" button
- "Regenerate Mirrors Now" button
- "Legacy Export" button (free, exports your soul data)
- Model state (always "Ready" - using NLP)

## Architecture

- **State Management**: Riverpod 2.5+ for reactive state
- **Mirror Generation**: Simple NLP service with rule-based pattern analysis
- **Storage**: 
  - File-based JSONL for life logs and secrets
  - SharedPreferences for app settings
  - Flutter Secure Storage for encrypted secrets
- **Background Tasks**: Platform-specific (WorkManager/BackgroundFetch)
- **Authentication**: LocalAuthentication for biometric auth
- **Privacy**: 100% on-device, no cloud uploads, no data transmission

## Data Sources & Privacy

All data sources are used **only** for generating mirror insights. The app:
- ✅ Processes all data **100% on-device**
- ✅ Never uploads or transmits any data
- ✅ Never creates accounts or tracks users
- ✅ Allows users to deny any permission
- ✅ Works with reduced insights if permissions are denied

See `APP_STORE_REVIEW_RESPONSE_ALL_DATA_SOURCES.md` for detailed justification of each data source.

## Known Issues & Notes

1. **No LLM**: The app uses rule-based NLP instead of LLM for privacy and performance
2. **Biometric Auth**: Requires `NSFaceIDUsageDescription` in `Info.plist` for iOS (already configured)
3. **Background Tasks**: May require additional permissions on some devices
4. **File Storage**: Uses file-based storage instead of databases for stability

## Contributing

This is a private project.

## License

Private project - All rights reserved.

## Support

For App Store submission, see:
- `APP_STORE_VALIDATION.md` - iOS App Store submission checklist
- `APP_STORE_REVIEW_RESPONSE_ALL_DATA_SOURCES.md` - Data source justifications for App Store review

---

**InnerMirror** - *The mirror is awake. There is nowhere left to hide.*
