import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/future_you_voice_service.dart';

class FutureYouVoiceScreen extends StatefulWidget {
  final FutureYouVoiceMessage message;

  const FutureYouVoiceScreen({
    super.key,
    required this.message,
  });

  @override
  State<FutureYouVoiceScreen> createState() => _FutureYouVoiceScreenState();
}

class _FutureYouVoiceScreenState extends State<FutureYouVoiceScreen> {
  FlutterTts _flutterTts = FlutterTts();
  bool _isPlaying = false;
  bool _isLoading = true;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      // Configure TTS for iOS/Android
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.5); // Slower, more thoughtful pace
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(0.9); // Slightly deeper voice
      
      // Set up completion handler
      _flutterTts.setCompletionHandler(() {
        if (mounted) {
          setState(() {
            _isPlaying = false;
          });
        }
      });
      
      // Set up error handler
      _flutterTts.setErrorHandler((msg) {
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _isLoading = false;
          });
        }
      });
      
      setState(() {
        _isLoading = false;
        _isInitialized = true;
      });
    } catch (e) {
      print('Error initializing TTS: $e');
      setState(() {
        _isLoading = false;
        _isInitialized = false;
      });
    }
  }

  Future<void> _togglePlayback() async {
    if (!_isInitialized) return;
    
    if (_isPlaying) {
      await _flutterTts.stop();
      setState(() {
        _isPlaying = false;
      });
    } else {
      setState(() {
        _isPlaying = true;
      });
      await _flutterTts.speak(widget.message.text);
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _flutterTts = FlutterTts();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Future You 2035',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w300,
            fontFamily: '.SF Pro Text',
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              // Audio waveform placeholder
              Container(
                height: 200,
                width: MediaQuery.of(context).size.width - 64,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : Icon(
                          _isPlaying ? Icons.volume_up : Icons.graphic_eq,
                          color: _isPlaying
                              ? Colors.white
                              : Colors.white.withOpacity(0.5),
                          size: 48,
                        ),
                ),
              ),
              const SizedBox(height: 32),
              // Play button
              GestureDetector(
                onTap: _isLoading || !_isInitialized ? null : _togglePlayback,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isLoading || !_isInitialized
                        ? Colors.white.withOpacity(0.5)
                        : Colors.white,
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.black,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Message text - now scrollable
              SelectableText(
                widget.message.text,
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey.shade200,
                  fontFamily: '.SF Pro Text',
                  height: 1.6,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '${widget.message.createdAt.year}-${widget.message.createdAt.month.toString().padLeft(2, '0')}-${widget.message.createdAt.day.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                  color: Colors.grey.shade600,
                  fontFamily: '.SF Pro Text',
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

