import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'life_log_service.dart';

// Simplified embedding storage using JSON file
// In production, use Isar with proper code generation
class MemoryEmbedding {
  final String entryId;
  final String entryType;
  final DateTime timestamp;
  final List<double> embedding;
  final Map<String, dynamic> metadata;

  MemoryEmbedding({
    required this.entryId,
    required this.entryType,
    required this.timestamp,
    required this.embedding,
    required this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'entryId': entryId,
    'entryType': entryType,
    'timestamp': timestamp.toIso8601String(),
    'embedding': embedding,
    'metadata': metadata,
  };

  factory MemoryEmbedding.fromJson(Map<String, dynamic> json) => MemoryEmbedding(
    entryId: json['entryId'],
    entryType: json['entryType'],
    timestamp: DateTime.parse(json['timestamp']),
    embedding: List<double>.from(json['embedding']),
    metadata: json['metadata'] as Map<String, dynamic>,
  );
}

class EmbeddingService {
  static EmbeddingService? _instance;
  static EmbeddingService get instance => _instance ??= EmbeddingService._();
  
  EmbeddingService._();
  
  File? _embeddingsFile;
  Set<String> _existingIds = {};

  Future<File> get embeddingsFile async {
    if (_embeddingsFile != null) return _embeddingsFile!;
    
    final dir = await getApplicationDocumentsDirectory();
    final memoryDir = Directory('${dir.path}/innermirror/memory');
    if (!await memoryDir.exists()) {
      await memoryDir.create(recursive: true);
    }
    _embeddingsFile = File('${memoryDir.path}/embeddings.jsonl');
    return _embeddingsFile!;
  }

  Future<void> reindexAll() async {
    final lifeLog = LifeLogService.instance;
    final entries = await lifeLog.getAllEntries();
    final file = await embeddingsFile;

    // Load existing embeddings
    if (await file.exists()) {
      final lines = await file.readAsLines();
      _existingIds = lines
          .where((line) => line.trim().isNotEmpty)
          .map((line) => MemoryEmbedding.fromJson(jsonDecode(line)))
          .map((e) => e.entryId)
          .toSet();
    }

    for (final entry in entries) {
      final entryId = '${entry['type']}_${entry['date']}';
      
      // Skip if already embedded
      if (_existingIds.contains(entryId)) continue;

      // Generate embedding text
      final embeddingText = _createEmbeddingText(entry);
      
      // Generate embedding (simplified - would use actual embedding model)
      final embedding = await _generateEmbedding(embeddingText);
      
      // Store embedding
      final memoryEmbedding = MemoryEmbedding(
        entryId: entryId,
        entryType: entry['type'] as String? ?? 'unknown',
        timestamp: DateTime.fromMillisecondsSinceEpoch(entry['date'] as int? ?? 0),
        embedding: embedding,
        metadata: entry,
      );
      
      await file.writeAsString(
        jsonEncode(memoryEmbedding.toJson()) + '\n',
        mode: FileMode.append,
      );
      
      _existingIds.add(entryId);
    }
  }

  String _createEmbeddingText(Map<String, dynamic> entry) {
    final buffer = StringBuffer();
    buffer.write('Type: ${entry['type']}\n');
    buffer.write('Time: ${entry['timestamp']}\n');
    
    switch (entry['type']) {
      case 'sms':
        buffer.write('From: ${entry['from']}\n');
        buffer.write('Message: ${entry['body']}\n');
        break;
      case 'photo':
        buffer.write('Photo taken\n');
        break;
      case 'health_hrv':
        buffer.write('HRV: ${entry['value']}\n');
        break;
      case 'health_sleep':
        buffer.write('Sleep: ${entry['value']} minutes\n');
        break;
      case 'health_steps':
        buffer.write('Steps: ${entry['value']}\n');
        break;
      case 'location':
        buffer.write('Location: ${entry['latitude']}, ${entry['longitude']}\n');
        break;
    }
    
    return buffer.toString();
  }

  Future<List<double>> _generateEmbedding(String text) async {
    // Simplified embedding - in production, use actual embedding model
    // For now, create a simple hash-based embedding
    final hash = text.hashCode;
    final embedding = List<double>.generate(384, (i) => 
      ((hash + i) % 1000) / 1000.0
    );
    return embedding;
  }

  Future<List<MemoryEmbedding>> searchSimilar(String query, {int limit = 10}) async {
    final file = await embeddingsFile;
    if (!await file.exists()) return [];
    
    final lines = await file.readAsLines();
    final embeddings = lines
        .where((line) => line.trim().isNotEmpty)
        .map((line) => MemoryEmbedding.fromJson(jsonDecode(line)))
        .toList();
    
    // Sort by timestamp descending and limit
    embeddings.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return embeddings.take(limit).toList();
  }
}

