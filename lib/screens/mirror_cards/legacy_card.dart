import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/mirror_generation_service.dart';
import '../../widgets/breathing_background.dart';

class LegacyCard extends ConsumerStatefulWidget {
  const LegacyCard({super.key});

  @override
  ConsumerState<LegacyCard> createState() => _LegacyCardState();
}

class _LegacyCardState extends ConsumerState<LegacyCard> with SingleTickerProviderStateMixin {
  String? _content;
  DateTime? _lastGenerated;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _loadContent();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadContent() async {
    final service = MirrorGenerationService.instance;
    final content = await service.getMirrorContent('legacy');
    final lastGen = await service.getLastGeneratedTime('legacy');
    
    if (mounted) {
      setState(() {
        _content = content;
        _lastGenerated = lastGen;
      });
      _fadeController.forward();
    }
  }

  String _formatTimeAgo(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
  }

  @override
  Widget build(BuildContext context) {
    return BreathingBackground(
      isActive: _content == null && _lastGenerated == null,
      child: Container(
        color: Colors.black,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'LEGACY',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 8,
                  color: Colors.white,
                  fontFamily: '.SF Pro Display',
                ),
              ),
              const SizedBox(height: 48),
              Text(
                'What will remain when you\'re gone?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w300,
                  color: Colors.grey.shade400,
                  fontFamily: '.SF Pro Text',
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 48),
              FadeTransition(
                opacity: _fadeAnimation,
                child: _content != null
                    ? Column(
                        children: [
                          Text(
                            _content!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey.shade200,
                              fontFamily: '.SF Pro Text',
                              height: 1.8,
                              letterSpacing: 0.3,
                            ),
                          ),
                          if (_lastGenerated != null) ...[
                            const SizedBox(height: 24),
                            Text(
                              'Updated ${_formatTimeAgo(_lastGenerated)}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w300,
                                color: Colors.grey.shade600,
                                fontFamily: '.SF Pro Text',
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      )
                    : Text(
                        'Your impact extends beyond your presence. The choices you make, the love you give, the truth you live—these are the echoes that will outlast you.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                          color: Colors.grey.shade600,
                          fontFamily: '.SF Pro Text',
                          height: 1.8,
                        ),
                      ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}
