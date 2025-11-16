import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'life_log_service.dart';
import 'soul_model_service.dart';

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
  
  final SoulModelService _soulModel = SoulModelService.instance;
  final LifeLogService _lifeLog = LifeLogService.instance;

  Future<FutureYouVoiceMessage> generateWeeklyMessage() async {
    if (_soulModel.state != ModelState.ready) {
      throw Exception('Model not ready');
    }

    final lifeLogContent = await _lifeLog.getLifeLogContent();
    
    final prompt = """You are Future You from 2035. You have 10 more years of wisdom, perspective, and growth.

Generate a 30-second voice message (approximately 75-100 words) to your 2025 self.

Start with: "Hey 2025 me —"
End with: "Trust the muscle memory."

Be specific about what you've learned. Reference real patterns from the data. Be warm, wise, and direct.

Here is your 2025 life_log.jsonl:
$lifeLogContent""";

    final text = await _soulModel.generateResponse(prompt);
    
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
    final messages = await getMessages();
    if (messages.length > 10) {
      messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final last10 = messages.take(10).toList();
      
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = last10.map((m) => jsonEncode(m.toJson())).toList();
      await prefs.setStringList('future_you_messages', messagesJson);
    }
  }

  Future<List<FutureYouVoiceMessage>> getMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final messagesJson = prefs.getStringList('future_you_messages') ?? [];
    return messagesJson
        .map((json) => FutureYouVoiceMessage.fromJson(jsonDecode(json)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}

