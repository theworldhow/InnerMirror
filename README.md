# InnerMirror

A minimal, luxurious journaling app with mirror cards for self-reflection. **The AI that knows you better than you ever will.**

> "You can hide from everyone. You can't hide from you."

## Features

### Core Mirrors
- **5 Mirror Cards**: Truth, Strength, Shadow, Growth, Legacy
- Horizontal swipe navigation with page indicators
- Dark aesthetic with minimal, luxurious design
- Haptic feedback on mirror swipes
- Breathing animation when model is thinking

### Journaling
- Full-screen journal with text input
- Voice-to-text support (requires microphone permission)
- Floating "+" button for quick access
- Journal entries stored locally

### Secrets Vault
- Biometric authentication (Face ID/Touch ID with password fallback)
- Secure storage of voice and text secrets
- Encrypted local file storage
- "Burn Day" functionality (December 31st - all secrets deleted)
- Biometric unlock with graceful fallback

### Future You Messages
- 30-second voice messages from "Future You 2035"
- Generated every Sunday at 8:00 AM
- Playback with waveform visualization
- Last 10 messages saved for replay

### Data Ingestion & Memory
- Automatic nightly background data ingestion
- Tracks: SMS, photos, screen time, health data, location
- Stores data in `life_log.jsonl`
- "Memory: X moments" counter
- Debug screen (shake device twice) to view ingestion stats

### Onboarding & UX
- 3-screen onboarding flow (dark, unsettling)
- Victory screen on first successful launch
- Bottom navigation: Mirrors, Vault, Future You
- "Mirrors" button resets to first card when tapped

### Technical Features
- **State Management**: Riverpod 2.5+
- **Background Tasks**: WorkManager (Android), BackgroundFetch (iOS)
- **RevenueCat**: In-app purchases (Mirror Plus subscription, Legacy export)
- **Model Download**: Automatic LLM model download on first launch
- **100% On-device**: No servers, no uploads, all data stays on device

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
  │   ├── onboarding_screen.dart   # First-time onboarding
  │   ├── victory_screen.dart      # Victory message on launch
  │   ├── model_download_screen.dart # Model download progress
  │   ├── debug_screen.dart        # Debug screen (shake to open)
  │   └── mirror_cards/
  │       ├── truth_card.dart      # Truth Mirror
  │       ├── strength_card.dart   # Strength Mirror
  │       ├── shadow_card.dart     # Shadow Mirror
  │       ├── growth_card.dart     # Growth Mirror
  │       └── legacy_card.dart     # Legacy Mirror (with LLM)
  ├── services/
  │   ├── soul_model_service.dart  # LLM model management (stubbed)
  │   ├── model_download_service.dart # Model download logic
  │   ├── secrets_vault_service.dart  # Secrets vault storage
  │   ├── data_ingestion_service.dart # Background data ingestion
  │   ├── background_task_service.dart # Background task scheduling
  │   ├── future_you_voice_service.dart # Future You message generation
  │   ├── mirror_generation_service.dart # Daily mirror generation
  │   ├── revenue_cat_service.dart # In-app purchases
  │   └── ... (other services)
  ├── providers/
  │   ├── soul_model_provider.dart # Model state provider
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
- Xcode (for iOS)
- Android Studio (for Android)

### Installation

1. **Clone the repository**
```bash
git clone <repository-url>
cd InnerMirror
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **iOS Setup**
```bash
cd ios
pod install
cd ..
```

4. **Configure RevenueCat** (optional)
   - Update `lib/services/revenue_cat_service.dart` with your RevenueCat API key
   - Configure products in RevenueCat dashboard:
     - `mirror_plus`: Monthly subscription ($4.99)
     - `legacy`: One-time purchase ($99.00)

### Permissions

The app requires these permissions (configured in `Info.plist` for iOS and `AndroidManifest.xml` for Android):

- **NSMicrophoneUsageDescription**: Voice-to-text journaling
- **NSPhotoLibraryUsageDescription**: Photo ingestion
- **NSLocationWhenInUseUsageDescription**: Location history
- **NSHealthShareUsageDescription**: Health data (iOS)
- **NSFaceIDUsageDescription**: Secrets vault authentication
- **SMS**: Message ingestion (Android only)

## Running the App

### iOS Simulator
```bash
./scripts/run_ios_simulator.sh
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
./scripts/build_ios.sh
```

### Android (AAB)
```bash
./scripts/build_android.sh
```

See `BUILD_INSTRUCTIONS.md` for detailed build instructions.

## Features Status

### ✅ Implemented
- All 5 mirror cards UI
- Journal with voice-to-text
- Secrets Vault with biometric auth
- Future You messages screens
- Onboarding flow
- Victory screen
- Debug screen (shake twice)
- Background task framework
- Data ingestion services
- Memory counter
- Bottom navigation
- RevenueCat integration
- Model download UI

### 🔄 Stubbed (Ready for Implementation)
- **On-device LLM Inference**: Currently using `mllama_stub.dart` for simulated responses
  - Ready for `mllama_flutter` package integration when available
  - Model download service is functional
- **Voice Cloning**: Future You voice uses `flutter_tts` (can be upgraded to Piper TTS)
- **Embeddings**: Simplified JSONL storage (ready for Isar upgrade)
- **LoRA Fine-tuning**: Service structure ready for PEFT implementation

### 📋 Future Enhancements
- Real on-device Llama 3.2 8B inference
- Personal LoRA fine-tuning
- Daily mirror generation from life_log data
- Push notifications
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
- "Legacy Export" button ($99 paywall)

## Architecture

- **State Management**: Riverpod 2.5+ for reactive state
- **Storage**: 
  - File-based JSONL for life logs and secrets
  - SharedPreferences for app settings
  - Isar ready for embeddings (currently using JSONL)
- **Background Tasks**: Platform-specific (WorkManager/BackgroundFetch)
- **Authentication**: LocalAuthentication for biometric auth
- **Privacy**: 100% on-device, no cloud uploads

## Known Issues & Notes

1. **LLM Inference**: Currently stubbed. Replace `mllama_stub.dart` with actual `mllama_flutter` package when available.

2. **Biometric Auth**: Requires `NSFaceIDUsageDescription` in `Info.plist` for iOS (already configured).

3. **Background Tasks**: May require additional permissions on some devices.

4. **Sqflite Removed**: Secrets Vault uses file storage instead of database to avoid iOS crashes.

## Contributing

This is a private project. See `CODE_SIGNING_SETUP.md` for development setup.

## License

Private project - All rights reserved.

## Support

For build and deployment instructions, see:
- `BUILD_INSTRUCTIONS.md`
- `CODE_SIGNING_SETUP.md`
- `SUBMIT_TO_STORES.md`
- `TESTING_GUIDE.md`
- `SHIPPING_GUIDE.md`

---

**InnerMirror** - *The mirror is awake. There is nowhere left to hide.*
