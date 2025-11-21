import 'package:flutter/material.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'main_screen.dart';
import '../services/data_ingestion_service.dart';
import '../services/mirror_generation_service.dart';
import '../services/future_you_voice_service.dart';
import '../services/soul_model_service.dart';
import '../services/permission_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  int _currentPermissionIndex = 0;
  bool _isRequestingPermissions = false;
  Map<String, bool> _permissionResults = {};

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    // Enable permission request mode
    setState(() {
      _isRequestingPermissions = true;
      _currentPermissionIndex = 0;
      _permissionResults = {};
    });
    
    // Navigate to permission request page (4th page, index 3)
    if (_pageController.hasClients) {
      await _pageController.animateToPage(
        3,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentPage = 3;
      });
    }
    
    // Wait for UI to update and show permission page
    await Future.delayed(const Duration(milliseconds: 600));
    
    // Start step-by-step permission requests
    await _requestAllPermissionsStepByStep();
  }

  Future<void> _requestAllPermissionsStepByStep() async {
    final permissionService = PermissionService.instance;
    final requiredPermissions = permissionService.getRequiredPermissions();

    // Request permissions one by one
    for (int i = 0; i < requiredPermissions.length; i++) {
      if (!mounted) return;
      
      // Update UI to show current permission
      setState(() {
        _currentPermissionIndex = i;
      });
      
      // Wait a moment for user to see the permission request page
      await Future.delayed(const Duration(milliseconds: 800));

      final permissionName = requiredPermissions[i];
      
      // Request permission - this will trigger system dialog
      print('[Onboarding] Requesting permission: $permissionName');
      final result = await permissionService.requestNextPermission(permissionName);
      _permissionResults[result.key] = result.value;
      
      print('[Onboarding] Permission $permissionName: ${result.value ? "granted" : "denied"}');

      // Update UI to show result
      if (mounted) {
        setState(() {
          // UI will update to show granted/denied status
        });
      }

      // Wait for user to see the result before moving to next permission
      await Future.delayed(const Duration(milliseconds: 1500));
    }

    setState(() {
      _isRequestingPermissions = false;
    });

    // Mark onboarding as complete
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    
    // Show loading indicator
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }
    
    // Trigger first-time setup and WAIT for it to complete
    try {
      print('[Onboarding] Starting first-time setup with data ingestion...');
      await _triggerFirstTimeSetup();
      print('[Onboarding] First-time setup completed successfully');
    } catch (e, stackTrace) {
      print('[Onboarding] First-time setup error: $e');
      print('[Onboarding] Stack trace: $stackTrace');
    } finally {
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
      }
    }
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    }
  }

  void _showPermissionDialog(List<String> missingPermissions) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: Text(
          'Permissions Required',
          style: TextStyle(color: Colors.white, fontFamily: '.SF Pro Text'),
        ),
        content: Text(
          'The following permissions were not granted:\n${missingPermissions.join(', ')}\n\n'
          'You can grant these permissions later in Settings.',
          style: TextStyle(color: Colors.grey.shade300, fontFamily: '.SF Pro Text'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.of(context).pop();
            },
            child: const Text('Open Settings', style: TextStyle(color: Colors.blue)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Future<void> _triggerFirstTimeSetup() async {
    try {
      // Step 1: Ingest data for past 6 months
      print('[Onboarding] First-time setup: Starting data ingestion (past 6 months)...');
      final dataIngestion = DataIngestionService.instance;
      await dataIngestion.ingestPastWeek();
      print('[Onboarding] First-time setup: Data ingestion complete');
      
      // Step 2: Wait for model to be ready (if downloading)
      // Check if model is ready, if not, wait a bit and try again
      final soulModel = SoulModelService.instance;
      int attempts = 0;
      while (attempts < 10 && soulModel.state != ModelState.ready) {
        await Future.delayed(const Duration(seconds: 2));
        attempts++;
      }
      
      // Step 3: Generate mirrors immediately (force, bypass daily limit)
      if (soulModel.state == ModelState.ready) {
        print('First-time setup: Generating mirrors...');
        final mirrorGen = MirrorGenerationService.instance;
        await mirrorGen.generateAllMirrors(force: true);
        
        // Step 4: Generate initial Future You message
        print('First-time setup: Generating initial Future You message...');
        try {
          final futureYou = FutureYouVoiceService.instance;
          await futureYou.generateWeeklyMessage();
        } catch (e) {
          print('First-time Future You message generation error (non-critical): $e');
        }
      } else {
        print('Model not ready yet - mirrors will generate when model is ready');
        // Schedule generation when model becomes ready
        _waitForModelAndGenerate();
      }
    } catch (e) {
      print('First-time setup error: $e');
    }
  }

  Future<void> _waitForModelAndGenerate() async {
    // Wait for model to be ready, then generate mirrors and Future You message
    final soulModel = SoulModelService.instance;
    int attempts = 0;
    while (attempts < 30 && soulModel.state != ModelState.ready) {
      await Future.delayed(const Duration(seconds: 2));
      attempts++;
    }
    
    if (soulModel.state == ModelState.ready) {
      try {
        final mirrorGen = MirrorGenerationService.instance;
        await mirrorGen.generateAllMirrors(force: true);
        
        final futureYou = FutureYouVoiceService.instance;
        await futureYou.generateWeeklyMessage();
      } catch (e) {
        print('Delayed first-time generation error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView(
        controller: _pageController,
        physics: _isRequestingPermissions ? const NeverScrollableScrollPhysics() : const PageScrollPhysics(),
        onPageChanged: (index) {
          // Prevent swiping during permission requests
          if (!_isRequestingPermissions) {
            setState(() {
              _currentPage = index;
            });
          }
        },
        children: [
          _buildPage(
            title: 'You can hide from everyone.',
            subtitle: 'But you can\'t hide from you.',
            body: 'Every message. Every photo. Every step. Every secret. The mirror sees it all.',
          ),
          _buildPage(
            title: 'The AI that knows you better',
            subtitle: 'than you ever will.',
            body: 'Trained on your actual life. Fine-tuned to your voice. Brutally honest. Completely private.',
          ),
          _buildPage(
            title: 'There is nowhere left to hide.',
            subtitle: 'Let the mirror see you.',
            body: '100% on-device. No servers. No uploads. Your data never leaves your phone. Not even we can see it.',
            showButton: true,
          ),
          _buildPermissionRequestPage(),
        ],
      ),
    );
  }

  Widget _buildPage({
    required String title,
    required String subtitle,
    required String body,
    bool showButton = false,
  }) {
    return Padding(
      padding: const EdgeInsets.all(48.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w300,
              color: Colors.white,
              fontFamily: '.SF Pro Display',
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w300,
              color: Colors.grey.shade400,
              fontFamily: '.SF Pro Text',
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 48),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w300,
              color: Colors.grey.shade500,
              fontFamily: '.SF Pro Text',
              height: 1.8,
            ),
          ),
          const Spacer(),
          if (showButton)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _completeOnboarding,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                ),
                child: const Text(
                  'Let the mirror see you',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: '.SF Pro Text',
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: () {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: Text(
                'Continue',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontFamily: '.SF Pro Text',
                ),
              ),
            ),
          const SizedBox(height: 32),
          if (!_isRequestingPermissions)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index == _currentPage
                        ? Colors.white
                        : Colors.white.withOpacity(0.3),
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }

  Widget _buildPermissionRequestPage() {
    // Don't show permission page until we're requesting permissions
    if (!_isRequestingPermissions) {
      return _buildPage(
        title: 'Ready to Begin',
        subtitle: 'Tap the button to start',
        body: 'We will request permissions one by one to access your data.',
        showButton: false,
      );
    }
    
    final permissionService = PermissionService.instance;
    final requiredPermissions = permissionService.getRequiredPermissions();
    
    if (_currentPermissionIndex >= requiredPermissions.length) {
      return _buildPage(
        title: 'Permissions Complete',
        subtitle: 'Setting up your mirror...',
        body: 'All permissions have been requested. The mirror is now ready to see you.',
        showButton: false,
      );
    }

    final currentPermission = requiredPermissions[_currentPermissionIndex];
    final description = permissionService.getPermissionDescription(currentPermission);
    final isGranted = _permissionResults[currentPermission] ?? false;
    final hasBeenRequested = _permissionResults.containsKey(currentPermission);

    return Padding(
      padding: const EdgeInsets.all(48.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          if (!hasBeenRequested)
            // Show instruction before requesting
            Column(
              children: [
                Icon(
                  Icons.settings,
                  color: Colors.white,
                  size: 64,
                ),
                const SizedBox(height: 32),
                Text(
                  _getPermissionTitle(currentPermission),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w300,
                    color: Colors.white,
                    fontFamily: '.SF Pro Display',
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                    color: Colors.grey.shade400,
                    fontFamily: '.SF Pro Text',
                    height: 1.8,
                  ),
                ),
                const SizedBox(height: 48),
                Text(
                  'System permission dialog will appear...',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontFamily: '.SF Pro Text',
                    fontSize: 14,
                  ),
                ),
              ],
            )
          else
            // Show result after requesting
            Column(
              children: [
                Icon(
                  isGranted ? Icons.check_circle : Icons.warning,
                  color: isGranted ? Colors.green : Colors.orange,
                  size: 64,
                ),
                const SizedBox(height: 32),
                Text(
                  isGranted ? 'Permission Granted' : 'Permission Needed',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w300,
                    color: isGranted ? Colors.green : Colors.white,
                    fontFamily: '.SF Pro Display',
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  isGranted
                      ? 'Great! You can continue.'
                      : 'Please enable this permission in Settings > InnerMirror',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                    color: Colors.grey.shade400,
                    fontFamily: '.SF Pro Text',
                    height: 1.8,
                  ),
                ),
                if (!isGranted) ...[
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => openAppSettings(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Open Settings'),
                  ),
                ],
              ],
            ),
          const SizedBox(height: 32),
          // Progress indicator
          Container(
            width: double.infinity,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (_currentPermissionIndex + 1) / requiredPermissions.length,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${_currentPermissionIndex + 1} of ${requiredPermissions.length}',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontFamily: '.SF Pro Text',
              fontSize: 12,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  String _getPermissionTitle(String permissionName) {
    switch (permissionName) {
      case 'contacts':
        return 'Contacts Access';
      case 'calendar':
        return 'Calendar Access';
      case 'health':
        return 'Health & Fitness';
      case 'photos':
        return 'Photo Library';
      case 'microphone':
        return 'Microphone Access';
      case 'speech':
        return 'Speech Recognition';
      case 'location':
        return 'Location Access';
      case 'face_id':
        return 'Face ID';
      case 'notification_access':
        return Platform.isIOS 
            ? 'Message Access Info'
            : 'Notification Access';
      default:
        return 'Permission Request';
    }
  }

}

