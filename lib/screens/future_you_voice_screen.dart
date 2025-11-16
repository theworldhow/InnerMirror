import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart' as just_audio;
import 'package:audio_waveforms/audio_waveforms.dart';
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
  late just_audio.AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = true;
  PlayerController? _waveformController;

  @override
  void initState() {
    super.initState();
    _audioPlayer = just_audio.AudioPlayer();
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      // Initialize waveform
      _waveformController = PlayerController();
      await _waveformController!.preparePlayer(
        path: widget.message.audioPath,
        shouldExtractWaveform: true,
      );
      
      // Setup audio player
      await _audioPlayer.setFilePath(widget.message.audioPath);
      
      _audioPlayer.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
          });
        }
      });
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
      await _waveformController?.pausePlayer();
    } else {
      await _audioPlayer.play();
      await _waveformController?.startPlayer();
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _waveformController?.dispose();
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(48.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Waveform placeholder (audio_waveforms API may vary by version)
              if (_waveformController != null && !_isLoading)
                Container(
                  height: 200,
                  width: MediaQuery.of(context).size.width - 96,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.graphic_eq,
                      color: Colors.white.withOpacity(0.5),
                      size: 48,
                    ),
                  ),
                )
              else
                const SizedBox(
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
                ),
              const SizedBox(height: 48),
              // Play button
              GestureDetector(
                onTap: _isLoading ? null : _togglePlayback,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.black,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              // Message text
              Text(
                widget.message.text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w300,
                  color: Colors.grey.shade300,
                  fontFamily: '.SF Pro Text',
                  height: 1.8,
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
            ],
          ),
        ),
      ),
    );
  }
}

