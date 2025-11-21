import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shake/shake.dart';
import '../widgets/page_indicator.dart';
import '../widgets/floating_add_button.dart';
import 'journal_screen.dart';
// ModelDownloadScreen removed - no longer using LLM
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
// ModelDownloadService removed - no longer using LLM
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
        onPhoneShake: (ShakeEvent event) {
          // Ensure we're on the main thread for all UI operations
          // This prevents crashes from platform channel thread violations
          // Shake package 3.0.0+ requires ShakeEvent parameter
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

    // No model download needed - using NLP now
    final modelService = ref.read(soulModelServiceProvider);
    
    // Always ready - just initialize the stub service
    if (modelService.state == ModelState.notInitialized) {
      await modelService.initialize();
      if (mounted) {
        ref.read(modelStateProvider.notifier).state = modelService.state;
      }
    } else if (modelService.isReady) {
      ref.read(modelStateProvider.notifier).state = modelService.state;
    }
  }

  void _openJournal() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const JournalScreen(),
        fullscreenDialog: true,
      ),
    ).then((_) {
      // Reset to first page and update indicator when returning from Journal
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _resetToFirstPage();
          }
        });
      }
    });
  }

  void _onPageChanged(int page) {
    ref.read(currentPageProvider.notifier).state = page;
    // Haptic feedback on mirror swipe
    HapticFeedback.selectionClick();
  }

  void _resetToFirstPage() {
    // Immediately update indicator to show first dot - this happens instantly
    ref.read(currentPageProvider.notifier).state = 0;
    
    // Then reset PageView after a frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      final pageController = ref.read(pageControllerProvider);
      if (!pageController.hasClients) {
        // If not ready, wait and try again
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) {
            final controller = ref.read(pageControllerProvider);
            if (controller.hasClients) {
              controller.jumpToPage(0);
              // Double-check indicator is set
              ref.read(currentPageProvider.notifier).state = 0;
            }
          }
        });
        return;
      }
      
      // PageController is ready - reset immediately
      if (pageController.page?.round() != 0) {
        pageController.jumpToPage(0);
      }
      // Ensure indicator is set (jumpToPage doesn't trigger onPageChanged)
      ref.read(currentPageProvider.notifier).state = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentTab == 1) {
      return SecretsVaultScreen(
        onBack: () {
          // Reset indicator FIRST, before state change
          ref.read(currentPageProvider.notifier).state = 0;
          
          setState(() {
            _currentTab = 0;
          });
          
          // Then reset PageView after rebuild
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _resetToFirstPage();
          });
        },
      );
    }
    if (_currentTab == 2) {
      return FutureYouMessagesScreen(
        onBack: () {
          // Reset indicator FIRST, before state change
          ref.read(currentPageProvider.notifier).state = 0;
          
          setState(() {
            _currentTab = 0;
          });
          
          // Then reset PageView after rebuild
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _resetToFirstPage();
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
          // Top-center soul awake status
          Positioned(
            top: 48,
            left: 0,
            right: 0,
            child: Center(
              child: Consumer(
                builder: (context, ref, child) {
                  final modelService = ref.watch(soulModelServiceProvider);
                  if (modelService.isReady) {
                    return Text(
                      'Soul awake',
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
            ),
          ),
          // Top-right debug button (only in debug mode, hidden in screenshot mode)
          Positioned(
            top: 48,
            right: 24,
            child: kDebugMode && !ScreenshotMode.enabled
                ? GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const DebugScreen(),
                          fullscreenDialog: true,
                        ),
                      );
                    },
                    child: Container(
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
                  )
                : const SizedBox.shrink(),
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
                  fontStyle: FontStyle.normal,
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w300,
                  fontFamily: '.SF Pro Text',
                ),
              ),
            ),
          ),
          // Page indicator between tagline and mirror card title
          Positioned(
            top: 120,
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
            _resetToFirstPage();
          } else {
            setState(() {
              _currentTab = index;
            });
            // When switching back to Mirrors tab, reset to first page
            if (index == 0) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _resetToFirstPage();
              });
            }
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
