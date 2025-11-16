import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../services/secrets_vault_service.dart';
import '../services/future_you_voice_service.dart';
import '../services/soul_model_service.dart';
import 'future_you_voice_screen.dart';

class SecretsVaultScreen extends StatefulWidget {
  final VoidCallback? onBack;
  
  const SecretsVaultScreen({super.key, this.onBack});

  @override
  State<SecretsVaultScreen> createState() => _SecretsVaultScreenState();
}

class _SecretsVaultScreenState extends State<SecretsVaultScreen> {
  final SecretsVaultService _vault = SecretsVaultService.instance;
  LocalAuthentication? _localAuth;
  bool _isUnlocked = false;
  
  @override
  void initState() {
    super.initState();
    // Initialize LocalAuthentication lazily to avoid crashes on startup
    _initLocalAuth();
    // Delay burn day check to ensure widget is fully built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkBurnDay();
      }
    });
  }
  
  Future<void> _initLocalAuth() async {
    try {
      _localAuth = LocalAuthentication();
      // Test if biometrics are available (this can fail on some devices)
      final available = await _localAuth?.canCheckBiometrics ?? false;
      if (!available) {
        _localAuth = null; // Disable if not available
      }
    } catch (e) {
      print('LocalAuthentication initialization error (non-critical): $e');
      _localAuth = null; // Disable on error
    }
  }
  bool _isAuthenticating = false;
  final TextEditingController _textController = TextEditingController();
  List<Secret> _secrets = [];


  Future<void> _checkBurnDay() async {
    try {
      if (await _vault.isBurnDay() && mounted) {
        _showBurnDayDialog();
      }
    } catch (e) {
      print('Error checking burn day: $e');
      // Don't crash if burn day check fails
    }
  }

  Future<void> _authenticate() async {
    if (!mounted) return;
    
    setState(() {
      _isAuthenticating = true;
    });

    try {
      // Check if biometrics are available and enabled
      bool useBiometrics = false;
      if (_localAuth != null) {
        try {
          final canCheck = await _localAuth!.canCheckBiometrics;
          final isAvailable = await _localAuth!.isDeviceSupported();
          useBiometrics = canCheck && isAvailable;
        } catch (e) {
          print('Biometrics check error (non-critical): $e');
          useBiometrics = false;
        }
      }

      if (!useBiometrics) {
        // Fallback to simple unlock without biometrics
        final unlocked = await _vault.unlock();
        if (mounted) {
          setState(() {
            _isUnlocked = unlocked;
          });
          if (unlocked && mounted) {
            await _loadSecrets();
          }
        }
        return;
      }

      // Try biometric authentication with password fallback
      bool authenticated = false;
      try {
        authenticated = await _localAuth!.authenticate(
          localizedReason: 'Unlock your secrets vault',
          options: const AuthenticationOptions(
            biometricOnly: false, // Allow password fallback after Face ID/Touch ID fails
            stickyAuth: true,
            useErrorDialogs: true, // Show system error dialogs for better UX
          ),
        );
      } catch (e) {
        // Authentication failed - check if user cancelled or actual failure
        print('Authentication error: $e');
        // If it's a cancellation, don't unlock
        // If it's an error, might still unlock (user might have entered password)
        authenticated = false;
      }

      if (authenticated && mounted) {
        // Authentication successful - unlock vault
        final unlocked = await _vault.unlock();
        if (mounted) {
          setState(() {
            _isUnlocked = unlocked;
          });
          if (unlocked && mounted) {
            await _loadSecrets();
          }
        }
      } else {
        // Authentication failed or user cancelled - don't unlock
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Authentication required to unlock vault'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      // Handle any unexpected errors - still unlock as fallback
      print('Authentication error: $e');
      print('Stack trace: $stackTrace');
      
      // Fallback: unlock without authentication
      try {
        final unlocked = await _vault.unlock();
        if (mounted) {
          setState(() {
            _isUnlocked = unlocked;
          });
          if (unlocked && mounted) {
            await _loadSecrets();
          }
        }
      } catch (unlockError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to unlock vault: ${unlockError.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  Future<void> _loadSecrets() async {
    try {
      final secrets = await _vault.getAllSecrets();
      if (mounted) {
        setState(() {
          _secrets = secrets;
        });
      }
    } catch (e) {
      print('Error loading secrets: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load secrets: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addSecret() async {
    if (!mounted) return;
    
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    try {
      await _vault.addSecret(text);
      if (mounted) {
        _textController.clear();
        await _loadSecrets();
      }
    } catch (e) {
      print('Error adding secret: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add secret: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showBurnDayDialog() async {
    if (!mounted) return;
    
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.black,
          title: const Text(
            'Burn Day',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'December 31. Time to let go. Future You 2035 will read every secret aloud, then they will be permanently deleted forever.',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Not yet'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Burn it all'),
            ),
          ],
        ),
      );

      if (confirmed == true && mounted) {
        await _burnSecrets();
      }
    } catch (e) {
      print('Error showing burn day dialog: $e');
      // Don't crash if dialog fails
    }
  }

  Future<void> _burnSecrets() async {
    if (!mounted) return;
    
    try {
      // Generate Future You 2035 voice reading all secrets
      final secrets = await _vault.getAllSecrets();
      if (secrets.isEmpty) {
        await _vault.burnAllSecrets();
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const BurnCompleteScreen(),
            ),
          );
        }
        return;
      }
      
      final secretsText = secrets.map((s) => s.content).join('\n\n');
      
      final voiceService = FutureYouVoiceService.instance;
      final soulModel = SoulModelService.instance;
      
      if (soulModel.state == ModelState.ready && mounted) {
        try {
          final prompt = """You are Future You from 2035. Read these secrets slowly, calmly, non-judgmentally. 

These are things I needed to say but couldn't. They don't define me. They're just part of the journey.

Secrets:
$secretsText

Generate a calm, forgiving voice message reading these secrets with compassion. Start with 'Hey 2025 me —' and end with 'Trust the muscle memory.'""";
          
          final text = await soulModel.generateResponse(prompt);
          
          // Create a temporary message for the burn day reading
          final message = FutureYouVoiceMessage(
            id: 'burn_day_${DateTime.now().millisecondsSinceEpoch}',
            text: text,
            audioPath: '', // Will be generated
            createdAt: DateTime.now(),
          );
          
          // Generate audio
          try {
            final audioPath = await voiceService.generateAudioWithVoiceClone(text);
            final burnMessage = FutureYouVoiceMessage(
              id: message.id,
              text: message.text,
              audioPath: audioPath,
              createdAt: message.createdAt,
            );
            
            // Play the voice message, then delete
            if (mounted) {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => FutureYouVoiceScreen(message: burnMessage),
                ),
              );
            }
          } catch (e) {
            print('Error generating audio: $e');
            // Continue with deletion even if audio generation fails
          }
        } catch (e) {
          print('Error generating burn day message: $e');
          // Continue with deletion even if message generation fails
        }
      }
      
      // Delete all secrets
      await _vault.burnAllSecrets();
      
      // Show final screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const BurnCompleteScreen(),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('Error burning secrets: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to burn secrets: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isUnlocked) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock,
                color: Colors.white,
                size: 64,
              ),
              const SizedBox(height: 24),
              const Text(
                'Secrets Vault',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w300,
                  fontFamily: '.SF Pro Text',
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: _isAuthenticating ? null : _authenticate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: _isAuthenticating
                    ? const CircularProgressIndicator()
                    : const Text('Unlock'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Navigate back to home (tab 0)
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              // Fallback: try to pop if we're in a route
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            }
          },
        ),
        title: const Text(
          'Secrets Vault',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w300,
            fontFamily: '.SF Pro Text',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock, color: Colors.white),
            onPressed: () {
              if (!mounted) return;
              _vault.lock();
              if (mounted) {
                setState(() {
                  _isUnlocked = false;
                });
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Input area
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _textController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Your secret...',
                hintStyle: TextStyle(color: Colors.grey.shade600),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
              ),
              maxLines: 5,
            ),
          ),
          ElevatedButton(
            onPressed: _addSecret,
            child: const Text('Save Secret'),
          ),
          // Secrets list
          Expanded(
            child: ListView.builder(
              itemCount: _secrets.length,
              itemBuilder: (context, index) {
                final secret = _secrets[index];
                return ListTile(
                  title: Text(
                    secret.content,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    '${secret.createdAt.year}-${secret.createdAt.month}-${secret.createdAt.day}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class BurnCompleteScreen extends StatelessWidget {
  const BurnCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(48.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 80,
              ),
              const SizedBox(height: 48),
              const Text(
                'You are forgiven.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                  fontFamily: '.SF Pro Text',
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'You are free.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w300,
                  color: Colors.grey.shade400,
                  fontFamily: '.SF Pro Text',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

