import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

class LifeLogService {
  static LifeLogService? _instance;
  static LifeLogService get instance => _instance ??= LifeLogService._();
  
  LifeLogService._();

  Future<File> getLifeLogFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final memoryDir = Directory('${directory.path}/innermirror/memory');
    if (!await memoryDir.exists()) {
      await memoryDir.create(recursive: true);
    }
    return File('${memoryDir.path}/life_log.jsonl');
  }

  Future<void> appendEntry(Map<String, dynamic> entry) async {
    final file = await getLifeLogFile();
    final jsonLine = jsonEncode(entry) + '\n';
    await file.writeAsString(jsonLine, mode: FileMode.append);
  }

  Future<List<Map<String, dynamic>>> getAllEntries() async {
    final file = await getLifeLogFile();
    if (!await file.exists()) {
      return [];
    }

    final lines = await file.readAsLines();
    return lines
        .where((line) => line.trim().isNotEmpty)
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .toList();
  }

  Future<List<Map<String, dynamic>>> getRecentEntries({int count = 10}) async {
    final allEntries = await getAllEntries();
    return allEntries.reversed.take(count).toList();
  }

  Future<int> getTotalMoments() async {
    final entries = await getAllEntries();
    return entries.length;
  }

  Future<String> getLifeLogContent() async {
    final file = await getLifeLogFile();
    if (!await file.exists()) {
      return '';
    }
    return await file.readAsString();
  }
}

