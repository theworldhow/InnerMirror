import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shake/shake.dart';
import '../widgets/page_indicator.dart';
import '../widgets/floating_add_button.dart';
import 'journal_screen.dart';
import 'model_download_screen.dart';
import 'debug_screen.dart';
import 'secrets_vault_screen.dart';
import 'future_you_messages_screen.dart';
import 'mirror_cards/truth_card.dart';
import 'mirror_cards/strength_card.dart';
import 'mirror_cards/shadow_card.dart';
import 'mirror_cards/growth_card.dart';
import 'mirror_cards/legacy_card.dart';
import '../providers/soul_model_provider.dart';
import '../providers/memory_provider.dart';
import '../services/model_download_service.dart';
import '../services/device_info_service.dart';
import '../services/soul_model_service.dart';
import '../utils/screenshot_mode.dart';

final pageControllerProvider = StateProvider<PageController>((ref) {
  final controller = PageController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

final currentPageProvider = StateProvider<int>((ref) => 0);

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  bool _checkedModel = false;
  ShakeDetector? _shakeDetector;
  int _shakeCount = 0;
  DateTime? _lastShake;
  int _currentTab = 0;
  int _debugTapCount = 0; // For triple-tap to open debug screen (simulator workaround)

  @override
  void initState() {
    super.initState();
    _checkModelOnLaunch();
    // Delay shake detection to ensure app is fully initialized
    // This prevents crashes from sensors plugin thread issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _setupShakeDetection();
        }
      });
    });
  }

  void _setupShakeDetection() {
    // Shake detection setup - wrapped in try-catch to prevent crashes
    // The sensors plugin may send messages from background threads, so we
    // ensure all UI operations happen on the main thread
    try {
      _shakeDetector = ShakeDetector.autoStart(
        onPhoneShake: () {
          // Ensure we're on the main thread for all UI operations
          // This prevents crashes from platform channel thread violations
          if (!mounted) return;
          
          // Schedule on main thread
          Future.microtask(() {
            if (!mounted) return;
            
            final now = DateTime.now();
            if (_lastShake == null || now.difference(_lastShake!) > const Duration(seconds: 2)) {
              _shakeCount = 1;
            } else {
              _shakeCount++;
            }
            _lastShake = now;

            if (_shakeCount >= 2 && mounted) {
              _shakeCount = 0;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const DebugScreen(),
                  fullscreenDialog: true,
                ),
              );
            }
          });
        },
      );
    } catch (e) {
      // Shake detection may not work on all platforms - that's okay
      // The app will still function without it
      if (mounted) {
        print('Shake detection initialization error (non-critical): $e');
      }
    }
  }

  @override
  void dispose() {
    try {
      _shakeDetector?.stopListening();
    } catch (e) {
      // Ignore errors during disposal
    }
    super.dispose();
  }

  Future<void> _checkModelOnLaunch() async {
    if (_checkedModel) return;
    _checkedModel = true;

    final deviceInfo = ref.read(deviceInfoServiceProvider);
    final downloadService = ref.read(modelDownloadServiceProvider);
    final use8B = await deviceInfo.shouldUse8BModel();
    final modelExists = await downloadService.modelExists(use8B: use8B);

    if (!modelExists && mounted) {
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => const ModelDownloadScreen(),
          fullscreenDialog: true,
        ),
      );

      if (result == true && mounted) {
        // Model downloaded, initialize it
        final modelService = ref.read(soulModelServiceProvider);
        await modelService.initialize(use8B: use8B);
        ref.read(modelStateProvider.notifier).state = modelService.state;
      }
    } else if (modelExists) {
      // Model exists, initialize it in background
      final modelService = ref.read(soulModelServiceProvider);
      if (modelService.state == ModelState.notInitialized) {
        modelService.initialize(use8B: use8B).then((_) {
          if (mounted) {
            ref.read(modelStateProvider.notifier).state = modelService.state;
          }
        });
      }
    }
  }

  void _openJournal() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const JournalScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  void _onPageChanged(int page) {
    ref.read(currentPageProvider.notifier).state = page;
    // Haptic feedback on mirror swipe
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentTab == 1) {
      return SecretsVaultScreen(
        onBack: () {
          setState(() {
            _currentTab = 0;
          });
        },
      );
    }
    if (_currentTab == 2) {
      return FutureYouMessagesScreen(
        onBack: () {
          setState(() {
            _currentTab = 0;
          });
        },
      );
    }

    final pageController = ref.watch(pageControllerProvider);
    final currentPage = ref.watch(currentPageProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView(
            controller: pageController,
            onPageChanged: _onPageChanged,
            children: const [
              TruthCard(),
              StrengthCard(),
              ShadowCard(),
              GrowthCard(),
              LegacyCard(),
            ],
          ),
          // Top-left branding with debug access
          Positioned(
            top: 48,
            left: 24,
            child: GestureDetector(
              onLongPress: () {
                // Long press to open debug screen (works reliably in simulator)
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const DebugScreen(),
                    fullscreenDialog: true,
                  ),
                );
              },
              onTap: () {
                // Triple tap to open debug screen (alternative method)
                _debugTapCount++;
                if (_debugTapCount >= 3) {
                  _debugTapCount = 0;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const DebugScreen(),
                      fullscreenDialog: true,
                    ),
                  );
                } else {
                  // Reset counter after 2 seconds
                  Future.delayed(const Duration(seconds: 2), () {
                    if (mounted) {
                      _debugTapCount = 0;
                    }
                  });
                }
              },
              child: Text(
                'INNERMIRROR',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                  color: const Color(0xFF666666),
                  fontFamily: '.SF Pro Text',
                ),
              ),
            ),
          ),
          // Top-right indicators
          Positioned(
            top: 48,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Debug button (only in debug mode, hidden in screenshot mode) - positioned above indicators
                if (kDebugMode && !ScreenshotMode.enabled)
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const DebugScreen(),
                          fullscreenDialog: true,
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey[600]!, width: 1),
                      ),
                      child: Text(
                        'DEBUG',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[300],
                          fontFamily: '.SF Pro Text',
                        ),
                      ),
                    ),
                  ),
                Consumer(
                  builder: (context, ref, child) {
                    final modelService = ref.watch(soulModelServiceProvider);
                    if (modelService.isReady) {
                      return Text(
                        'Soul awake ✓',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey.shade500,
                          fontFamily: '.SF Pro Text',
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 4),
                Consumer(
                  builder: (context, ref, child) {
                    final momentsAsync = ref.watch(totalMomentsProvider);
                    return momentsAsync.when(
                      data: (count) => Text(
                        'Memory: ${count.toString().replaceAllMapped(
                          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                          (Match m) => '${m[1]},',
                        )} moments',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey.shade600,
                          fontFamily: '.SF Pro Text',
                        ),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    );
                  },
                ),
              ],
            ),
          ),
          // Centered tagline
          Positioned(
            top: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "You can't hide from you.",
                style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w300,
                  fontFamily: '.SF Pro Text',
                ),
              ),
            ),
          ),
          // Page indicator at bottom
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: PageIndicator(
              currentPage: currentPage,
              pageCount: 5,
            ),
          ),
          // Floating add button
          Positioned(
            bottom: 32,
            right: 24,
            child: FloatingAddButton(
              onPressed: _openJournal,
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (index) {
          if (index == 0 && _currentTab == 0) {
            // If already on Mirrors tab, reset to first mirror card
            pageController.animateToPage(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          } else {
            setState(() {
              _currentTab = index;
            });
          }
        },
        backgroundColor: Colors.black,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey.shade600,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome),
            label: 'Mirrors',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lock),
            label: 'Vault',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.record_voice_over),
            label: 'Future You',
          ),
        ],
      ),
    );
  }
}
