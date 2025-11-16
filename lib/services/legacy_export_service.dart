import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;
import 'life_log_service.dart';
import 'mirror_generation_service.dart';
import 'embedding_service.dart';

class LegacyExportService {
  static LegacyExportService? _instance;
  static LegacyExportService get instance => _instance ??= LegacyExportService._();
  
  LegacyExportService._();

  Future<File> exportSoulModel() async {
    final dir = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${dir.path}/innermirror/export');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    final archive = Archive();
    
    // Add life_log.jsonl
    final lifeLog = LifeLogService.instance;
    final lifeLogFile = await lifeLog.getLifeLogFile();
    if (await lifeLogFile.exists()) {
      final lifeLogData = await lifeLogFile.readAsBytes();
      archive.addFile(ArchiveFile('life_log.jsonl', lifeLogData.length, lifeLogData));
    }

    // Add mirrors
    final mirrorGen = MirrorGenerationService.instance;
    final mirrorsFile = await mirrorGen.mirrorsFile;
    if (await mirrorsFile.exists()) {
      final mirrorsData = await mirrorsFile.readAsBytes();
      archive.addFile(ArchiveFile('mirrors.jsonl', mirrorsData.length, mirrorsData));
    }

    // Add embeddings
    final embedding = EmbeddingService.instance;
    final embeddingsFile = await embedding.embeddingsFile;
    if (await embeddingsFile.exists()) {
      final embeddingsData = await embeddingsFile.readAsBytes();
      archive.addFile(ArchiveFile('embeddings.jsonl', embeddingsData.length, embeddingsData));
    }

    // Create encrypted zip
    final encoder = ZipEncoder();
    final zipData = encoder.encode(archive);
    
    if (zipData == null) {
      throw Exception('Failed to create archive');
    }

    // Save encrypted zip
    final exportFile = File('${exportDir.path}/soul_model_${DateTime.now().millisecondsSinceEpoch}.zip');
    await exportFile.writeAsBytes(zipData);
    
    return exportFile;
  }
}

