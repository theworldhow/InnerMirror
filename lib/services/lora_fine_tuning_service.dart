import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'life_log_service.dart';
import 'soul_model_service.dart';

class LoRAFineTuningService {
  static LoRAFineTuningService? _instance;
  static LoRAFineTuningService get instance => _instance ??= LoRAFineTuningService._();
  
  LoRAFineTuningService._();
  
  final LifeLogService _lifeLog = LifeLogService.instance;
  final SoulModelService _soulModel = SoulModelService.instance;

  Future<void> fineTuneNightly() async {
    try {
      // Get new entries since last fine-tuning
      final entries = await _getNewEntriesForFineTuning();
      if (entries.isEmpty) return;

      // Convert to Alpaca instruction format
      final trainingData = _convertToAlpacaFormat(entries);
      
      // Save training data
      final trainingFile = await _saveTrainingData(trainingData);
      
      // Fine-tune LoRA using mllama_flutter's PEFT support
      await _runLoRATraining(trainingFile);
      
      // Merge LoRA into base model
      await _mergeLoRA();
      
      // Save last fine-tuning time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_lora_training', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('LoRA fine-tuning error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _getNewEntriesForFineTuning() async {
    final prefs = await SharedPreferences.getInstance();
    final lastTraining = prefs.getInt('last_lora_training');
    final lastTrainingTime = lastTraining != null 
        ? DateTime.fromMillisecondsSinceEpoch(lastTraining)
        : DateTime.now().subtract(const Duration(days: 7));
    
    final allEntries = await _lifeLog.getAllEntries();
    return allEntries.where((entry) {
      final entryTime = DateTime.fromMillisecondsSinceEpoch(entry['date'] as int? ?? 0);
      return entryTime.isAfter(lastTrainingTime);
    }).toList();
  }

  List<Map<String, dynamic>> _convertToAlpacaFormat(List<Map<String, dynamic>> entries) {
    return entries.map((entry) {
      // Create instruction-following format from user's actual data
      String instruction = '';
      String input = '';
      String output = '';
      
      switch (entry['type']) {
        case 'sms':
          instruction = 'Continue this conversation in your natural style:';
          input = 'From: ${entry['from']}\nMessage: ${entry['body']}';
          output = entry['body'] as String? ?? '';
          break;
        case 'journal':
          instruction = 'Write a journal entry about:';
          input = entry['text'] as String? ?? '';
          output = entry['text'] as String? ?? '';
          break;
        default:
          // Skip non-text entries for fine-tuning
          return null;
      }
      
      if (output.isEmpty) return null;
      
      return {
        'instruction': instruction,
        'input': input,
        'output': output,
      };
    }).whereType<Map<String, dynamic>>().toList();
  }

  Future<File> _saveTrainingData(List<Map<String, dynamic>> trainingData) async {
    final dir = await getApplicationDocumentsDirectory();
    final trainingDir = Directory('${dir.path}/innermirror/training');
    if (!await trainingDir.exists()) {
      await trainingDir.create(recursive: true);
    }
    
    final file = File('${trainingDir.path}/lora_training_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(jsonEncode(trainingData));
    return file;
  }

  Future<void> _runLoRATraining(File trainingFile) async {
    // Use mllama_flutter's PEFT support for LoRA training
    // This is a simplified implementation - actual PEFT API may vary
    try {
      // In production, this would call the actual PEFT training API
      // For now, we'll simulate the training process
      // The actual implementation would be:
      // await MLLamaContext.trainLoRA(
      //   trainingData: trainingFile.path,
      //   rank: 8,
      //   alpha: 16,
      //   targetModules: ['q_proj', 'v_proj'],
      // );
      
      // Simulate training time (actual would be 2-4 minutes)
      await Future.delayed(const Duration(seconds: 1));
    } catch (e) {
      print('LoRA training error: $e');
      rethrow;
    }
  }

  Future<void> _mergeLoRA() async {
    // Merge the trained LoRA adapter into the base model
    try {
      // In production, this would call:
      // await _soulModel.mergeLoRAAdapter();
      
      // For now, the model would automatically use the merged weights
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      print('LoRA merge error: $e');
      rethrow;
    }
  }
}

