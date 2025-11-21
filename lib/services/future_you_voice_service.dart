import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'life_log_service.dart';
import 'simple_nlp_service.dart';

class FutureYouVoiceMessage {
  final String id;
  final String text;
  final String audioPath;
  final DateTime createdAt;

  FutureYouVoiceMessage({
    required this.id,
    required this.text,
    required this.audioPath,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'audioPath': audioPath,
    'createdAt': createdAt.toIso8601String(),
  };

  factory FutureYouVoiceMessage.fromJson(Map<String, dynamic> json) => FutureYouVoiceMessage(
    id: json['id'],
    text: json['text'],
    audioPath: json['audioPath'],
    createdAt: DateTime.parse(json['createdAt']),
  );
}

class FutureYouVoiceService {
  static FutureYouVoiceService? _instance;
  static FutureYouVoiceService get instance => _instance ??= FutureYouVoiceService._();
  
  FutureYouVoiceService._();
  
  final LifeLogService _lifeLog = LifeLogService.instance;

  Future<FutureYouVoiceMessage> generateWeeklyMessage() async {
    // Always ready now - using NLP
    final lifeLogContent = await _lifeLog.getLifeLogContent();
    
    final prompt = """You are Future You from 2035. You have 10 more years of wisdom, perspective, and growth.

Generate a 30-second voice message (approximately 75-100 words) to your 2025 self.

Start with: "Hey 2025 me —"
End with: "Trust the muscle memory."

Be specific about what you've learned. Reference real patterns from the data. Be warm, wise, and direct.

Here is your 2025 life_log.jsonl:
$lifeLogContent""";

    // Use NLP service instead of LLM
    final nlpService = SimpleNLPService.instance;
    final text = await nlpService.generateResponse(
      prompt: prompt,
      lifeLogContent: lifeLogContent,
    );
    
    // Ensure proper format
    String formattedText = text.trim();
    if (!formattedText.startsWith('Hey 2025 me —')) {
      formattedText = 'Hey 2025 me — $formattedText';
    }
    if (!formattedText.endsWith('Trust the muscle memory.')) {
      formattedText = '$formattedText Trust the muscle memory.';
    }

    // Generate audio with voice cloning
    final audioPath = await _generateAudioWithVoiceClone(formattedText);
    
    // Save message
    final message = FutureYouVoiceMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: formattedText,
      audioPath: audioPath,
      createdAt: DateTime.now(),
    );
    
    await _saveMessage(message);
    await _keepLast10Messages();
    
    return message;
  }

  Future<String> generateAudioWithVoiceClone(String text) async {
    return await _generateAudioWithVoiceClone(text);
  }

  // Public method to get messages
  Future<List<FutureYouVoiceMessage>> getMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final messagesJson = prefs.getStringList('future_you_messages') ?? [];
    var messages = messagesJson
        .map((json) => FutureYouVoiceMessage.fromJson(jsonDecode(json) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    // Generate initial message if empty and we have ingested data
    if (messages.isEmpty) {
      final lifeLogContent = await _lifeLog.getLifeLogContent();
      if (lifeLogContent.trim().isNotEmpty) {
        // Generate initial message based on ingested data
        final initialMessage = await _generateInitialMessage(lifeLogContent);
        messages.add(initialMessage);
        await _saveMessage(initialMessage);
      }
    }
    
    return messages;
  }
  
  Future<FutureYouVoiceMessage> _generateInitialMessage(String lifeLogContent) async {
    final entries = await _lifeLog.getAllEntries();
    final recentEntries = entries.take(10).toList();
    
    // Generate detailed message based on ingested data
    final entryCount = recentEntries.length;
    final entryCountText = entryCount > 0 ? 'I can see $entryCount moments you\'ve tracked. ' : '';
    
    final messageText = """Hey 2025 me —

This is your first message from Future You. I'm looking back at the moments you've captured so far, and I want you to know something important:

You're already doing the work.

Every entry you've made, every moment you've tracked, every pattern you've noticed—these aren't just data points. They're evidence of a fundamental shift: you're choosing awareness over autopilot.

$entryCountText Each one is a seed. Each one matters.

Here's what I know now that you're still learning:
- The patterns you're seeing are real. Trust them.
- The shadow you're avoiding will keep showing up until you face it.
- The strength you're discovering is already there—you're just learning to use it.
- The growth you're seeking is happening in the tracking itself.

You think you're just documenting your life, but you're actually changing it. Every time you look in the mirror, you're becoming more of who you're meant to be.

Keep going. Keep tracking. Keep showing up.

The person you're becoming is already here. The patterns you're noticing will become obvious in time. The growth you're seeking is happening right now, in this moment, as you choose awareness over avoidance.

Trust the muscle memory. The work you're doing now will pay off in ways you can't yet imagine.

— Future You, 2035""";

    // Generate audio
    final audioPath = await _generateAudioWithVoiceClone(messageText);
    
    // Create message
    final message = FutureYouVoiceMessage(
      id: 'initial_${DateTime.now().millisecondsSinceEpoch}',
      text: messageText,
      audioPath: audioPath,
      createdAt: DateTime.now(),
    );
    
    return message;
  }

  Future<String> _generateAudioWithVoiceClone(String text) async {
    // In production, this would use Piper TTS + voice cloning
    // For now, we'll use flutter_tts with voice modification
    final dir = await getApplicationDocumentsDirectory();
    final voiceDir = Directory('${dir.path}/innermirror/voice');
    if (!await voiceDir.exists()) {
      await voiceDir.create(recursive: true);
    }
    
    final audioPath = '${voiceDir.path}/future_you_${DateTime.now().millisecondsSinceEpoch}.wav';
    
    // TODO: Implement actual Piper TTS + voice cloning
    // This would:
    // 1. Load voice clone model (trained on 3 min of journal voice notes)
    // 2. Apply +10 year age filter (deeper, warmer tone)
    // 3. Generate audio with Piper TTS
    // 4. Save to audioPath
    
    // For now, create placeholder audio file
    final file = File(audioPath);
    await file.writeAsString('placeholder_audio_data');
    
    return audioPath;
  }

  Future<void> _saveMessage(FutureYouVoiceMessage message) async {
    final prefs = await SharedPreferences.getInstance();
    final messagesJson = prefs.getStringList('future_you_messages') ?? [];
    messagesJson.add(jsonEncode(message.toJson()));
    await prefs.setStringList('future_you_messages', messagesJson);
  }

  Future<void> _keepLast10Messages() async {
    final prefs = await SharedPreferences.getInstance();
    final messagesJson = prefs.getStringList('future_you_messages') ?? [];
    if (messagesJson.length > 10) {
      final messages = messagesJson
          .map((json) => FutureYouVoiceMessage.fromJson(jsonDecode(json) as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final last10 = messages.take(10).toList();
      
      final last10Json = last10.map((m) => jsonEncode(m.toJson())).toList();
      await prefs.setStringList('future_you_messages', last10Json);
    }
  }

}

