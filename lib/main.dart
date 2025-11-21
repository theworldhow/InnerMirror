import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/background_task_service.dart';
import 'services/share_extension_service.dart';
import 'services/mirror_generation_service.dart';
import 'screens/main_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/victory_screen.dart';
import 'providers/soul_model_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize background tasks (may fail on iOS - that's okay)
  try {
    await BackgroundTaskService.instance.initialize();
  } catch (e) {
    // Background tasks may not be available on all platforms
    print('Background task initialization error (non-critical): $e');
  }
  
  // Initialize share extension
  try {
    ShareExtensionService.instance.initialize();
  } catch (e) {
    // Share extension may not be available
    print('Share extension initialization error (non-critical): $e');
  }
  
  // Setup mirror regeneration callback (will be set up once ProviderScope is available)
  // This is done in the app widget after ProviderScope is created
  
  runApp(
    const ProviderScope(
      child: InnerMirrorApp(),
    ),
  );
}

class InnerMirrorApp extends ConsumerStatefulWidget {
  const InnerMirrorApp({super.key});

  @override
  ConsumerState<InnerMirrorApp> createState() => _InnerMirrorAppState();
}

class _InnerMirrorAppState extends ConsumerState<InnerMirrorApp> {
  Widget _home = const Scaffold(
    backgroundColor: Colors.black,
    body: Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    ),
  );

  @override
  void initState() {
    super.initState();
    // Setup mirror regeneration callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mirrorGen = MirrorGenerationService.instance;
      // Access the provider to ensure callback is set up
      ref.read(mirrorRegeneratedProvider);
      // Set the callback to notify provider when mirrors are regenerated
      mirrorGen.onMirrorsRegenerated = () {
        ref.read(mirrorRegeneratedProvider.notifier).state++;
      };
    });
    _determineHome();
  }

  Future<void> _determineHome() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
      final shouldShowVictory = await VictoryScreen.shouldShow();

      Widget home;
      if (!onboardingComplete) {
        home = const OnboardingScreen();
      } else if (shouldShowVictory) {
        home = const VictoryScreen();
      } else {
        home = const MainScreen();
      }

      if (mounted) {
        setState(() {
          _home = home;
        });
      }
    } catch (e) {
      // If there's an error, show main screen as fallback
      if (mounted) {
        setState(() {
          _home = const MainScreen();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InnerMirror',
      debugShowCheckedModeBanner: false,
      navigatorKey: ShareExtensionService.instance.navigatorKey,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          surface: Colors.black,
          background: Colors.black,
        ),
        useMaterial3: true,
      ),
      home: _home,
    );
  }
}

