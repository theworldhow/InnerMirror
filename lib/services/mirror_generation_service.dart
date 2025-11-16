import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'life_log_service.dart';
import 'soul_model_service.dart';
import 'embedding_service.dart';

class MirrorContent {
  final String mirrorType; // truth, strength, shadow, growth, legacy
  final String content;
  final DateTime generatedAt;
  final DateTime validUntil; // Next generation time

  MirrorContent({
    required this.mirrorType,
    required this.content,
    required this.generatedAt,
    required this.validUntil,
  });

  Map<String, dynamic> toJson() => {
    'mirrorType': mirrorType,
    'content': content,
    'generatedAt': generatedAt.toIso8601String(),
    'validUntil': validUntil.toIso8601String(),
  };

  factory MirrorContent.fromJson(Map<String, dynamic> json) => MirrorContent(
    mirrorType: json['mirrorType'],
    content: json['content'],
    generatedAt: DateTime.parse(json['generatedAt']),
    validUntil: DateTime.parse(json['validUntil']),
  );
}

class MirrorGenerationService {
  static MirrorGenerationService? _instance;
  static MirrorGenerationService get instance => _instance ??= MirrorGenerationService._();
  
  MirrorGenerationService._();
  
  File? _mirrorsFile;
  final SoulModelService _soulModel = SoulModelService.instance;
  final LifeLogService _lifeLog = LifeLogService.instance;
  final EmbeddingService _embedding = EmbeddingService.instance;

  Future<File> get mirrorsFile async {
    if (_mirrorsFile != null) return _mirrorsFile!;
    final dir = await getApplicationDocumentsDirectory();
    final memoryDir = Directory('${dir.path}/innermirror/memory');
    if (!await memoryDir.exists()) {
      await memoryDir.create(recursive: true);
    }
    _mirrorsFile = File('${memoryDir.path}/mirrors.jsonl');
    return _mirrorsFile!;
  }

  Future<void> generateAllMirrors() async {
    // Rate limiting: only generate once per day
    final prefs = await SharedPreferences.getInstance();
    final lastGeneration = prefs.getInt('last_mirror_generation');
    final now = DateTime.now();
    
    if (lastGeneration != null) {
      final lastGenTime = DateTime.fromMillisecondsSinceEpoch(lastGeneration);
      if (now.difference(lastGenTime).inHours < 24) {
        // Already generated today
        return;
      }
    }

    if (_soulModel.state != ModelState.ready) {
      // Try to initialize model if needed
      return;
    }

    final lifeLogContent = await _lifeLog.getLifeLogContent();
    
    // Generate each mirror
    await _generateTruthMirror(lifeLogContent);
    await _generateStrengthMirror(lifeLogContent);
    await _generateShadowMirror(lifeLogContent);
    await _generateGrowthMirror(lifeLogContent);
    await _generateLegacyMirror(lifeLogContent);
    
    // Save generation time
    await prefs.setInt('last_mirror_generation', now.millisecondsSinceEpoch);
  }

  Future<void> _generateTruthMirror(String lifeLogContent) async {
    final prompt = """You have perfect recall of everything I've ever written or said in messages and journal. 

Count this week only. Never guess. 

Output exactly: 
"[Big number] times you said you were fine when you weren't. 

Last one: [exact quote] to [person] on [date/time]. 

Here's the pattern: [one brutal sentence]."

Here is my life_log.jsonl:
$lifeLogContent""";

    try {
      final response = await _soulModel.generateResponse(prompt);
      await _saveMirrorContent('truth', response);
    } catch (e) {
      print('Error generating Truth mirror: $e');
    }
  }

  Future<void> _generateStrengthMirror(String lifeLogContent) async {
    final prompt = """Look at every success and failure in my data. 

Find the real superpower that actually works for me. 

Output exactly: 
"You win [X]% of the time when you [specific behavior from real data]. 

Do that more."

Here is my life_log.jsonl:
$lifeLogContent""";

    try {
      final response = await _soulModel.generateResponse(prompt);
      await _saveMirrorContent('strength', response);
    } catch (e) {
      print('Error generating Strength mirror: $e');
    }
  }

  Future<void> _generateShadowMirror(String lifeLogContent) async {
    final prompt = """Find the avoidance pattern I hate admitting. 

Output exactly: 
"You [specific toxic behavior] when you feel [exact trigger from data]. 

Last time: [person/event] on [date]. 

Fix it: [one-line command]."

Here is my life_log.jsonl:
$lifeLogContent""";

    try {
      final response = await _soulModel.generateResponse(prompt);
      await _saveMirrorContent('shadow', response);
    } catch (e) {
      print('Error generating Shadow mirror: $e');
    }
  }

  Future<void> _generateGrowthMirror(String lifeLogContent) async {
    final prompt = """Compare this year to last year using real timestamps. 

Output exactly: 
"You're [exact %] better at [skill/boundary] than last year. 

Next level: [specific boundary to set next]."

Here is my life_log.jsonl:
$lifeLogContent""";

    try {
      final response = await _soulModel.generateResponse(prompt);
      await _saveMirrorContent('growth', response);
    } catch (e) {
      print('Error generating Growth mirror: $e');
    }
  }

  Future<void> _generateLegacyMirror(String lifeLogContent) async {
    final prompt = """You are my exact digital twin. You have perfect recall of everything in life_log.jsonl.

Never guess. Only use real events, messages, and patterns from my actual data.

In 40 years, this week will be remembered as:

Here is my life_log.jsonl:
$lifeLogContent""";

    try {
      final response = await _soulModel.generateResponse(prompt);
      await _saveMirrorContent('legacy', response);
    } catch (e) {
      print('Error generating Legacy mirror: $e');
    }
  }

  Future<void> _saveMirrorContent(String mirrorType, String content) async {
    final file = await mirrorsFile;
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    
    // Load existing mirrors
    Map<String, MirrorContent> mirrors = {};
    if (await file.exists()) {
      final lines = await file.readAsLines();
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        final mirror = MirrorContent.fromJson(jsonDecode(line));
        mirrors[mirror.mirrorType] = mirror;
      }
    }
    
    // Update this mirror
    mirrors[mirrorType] = MirrorContent(
      mirrorType: mirrorType,
      content: content,
      generatedAt: now,
      validUntil: tomorrow,
    );
    
    // Write all mirrors back
    final jsonLines = mirrors.values.map((m) => jsonEncode(m.toJson())).join('\n');
    await file.writeAsString(jsonLines + '\n');
  }

  Future<String?> getMirrorContent(String mirrorType) async {
    final file = await mirrorsFile;
    if (!await file.exists()) return null;
    
    final lines = await file.readAsLines();
    for (final line in lines.reversed) {
      if (line.trim().isEmpty) continue;
      final mirror = MirrorContent.fromJson(jsonDecode(line));
      if (mirror.mirrorType == mirrorType && mirror.validUntil.isAfter(DateTime.now())) {
        return mirror.content;
      }
    }
    return null;
  }

  Future<DateTime?> getLastGeneratedTime(String mirrorType) async {
    final file = await mirrorsFile;
    if (!await file.exists()) return null;
    
    final lines = await file.readAsLines();
    for (final line in lines.reversed) {
      if (line.trim().isEmpty) continue;
      final mirror = MirrorContent.fromJson(jsonDecode(line));
      if (mirror.mirrorType == mirrorType) {
        return mirror.generatedAt;
      }
    }
    return null;
  }
}

